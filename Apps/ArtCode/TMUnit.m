//
//  TMUnit.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"
#import "TMIndex+Internal.h"
#import "TMScope+Internal.h"
#import "TMTheme.h"
#import "TMBundle.h"
#import "TMPreference.h"
#import "TMSyntaxNode.h"
#import "OnigRegexp.h"
#import "CStringCachingString.h"
#import "NSIndexSet+StringRanges.h"
#import "CodeFile+Generation.h"
#import <libkern/OSAtomic.h>

static NSMutableDictionary *_extensionClasses;

static NSString * const _captureName = @"name";
static OnigRegexp *_numberedCapturesRegexp;
static OnigRegexp *_namedCapturesRegexp;

@interface TMSymbol ()

@property (nonatomic, readwrite) BOOL separator;
- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon range:(NSRange)range;

@end

@interface Change : NSObject
{
    @package
    CodeFileGeneration generation;
    NSRange oldRange;
    NSRange newRange;
}
@end

@implementation Change
@end

@interface TMUnit () <CodeFilePresenter>
{
    TMSyntaxNode *_syntax;
    OSSpinLock _scopesLock;
    CodeFileGeneration _scopesGeneration;
    TMScope *_rootScope;
    NSOperationQueue *_internalQueue;
    OSSpinLock _pendingChangesLock;
    NSMutableArray *_pendingChanges;
    BOOL _hasPendingChanges;
    NSMutableIndexSet *_unparsedRanges;
    NSMutableIndexSet *_blankRanges;
    NSMutableDictionary *_patternsIncludedByPattern;
    NSMutableDictionary *_extensions;
}
- (NSMutableArray *)_scopeStackAtOffset:(NSUInteger)offset;
- (void)_setHasPendingChanges;
- (void)_generateScopes;
- (BOOL)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result offset:(NSUInteger)offset inScope:(TMScope *)scope generation:(CodeFileGeneration)generation;
- (void)_shiftScopesByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange;
- (BOOL)_addedScope:(TMScope *)scope withGeneration:(CodeFileGeneration)generation;
- (BOOL)_removedScope:(TMScope *)scope withGeneration:(CodeFileGeneration)generation;
- (BOOL)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope generation:(CodeFileGeneration)generation;
- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern;
@end

@implementation TMUnit

@synthesize index = _index, codeFile = _codeFile, loading = _isLoading;

#pragma mark - Internal Methods

+ (void)initialize
{
    if (self != [TMUnit class])
        return;
    _numberedCapturesRegexp = [OnigRegexp compile:@"\\\\([1-9])" options:OnigOptionCaptureGroup];
    _namedCapturesRegexp = [OnigRegexp compile:@"\\\\k<(.*?)>" options:OnigOptionCaptureGroup];
    ECASSERT(_numberedCapturesRegexp && _namedCapturesRegexp);
}

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key
{
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *extensionClassesForLanguage = [_extensionClasses objectForKey:languageIdentifier];
    if (!extensionClassesForLanguage)
    {
        extensionClassesForLanguage = [[NSMutableDictionary alloc] init];
        [_extensionClasses setObject:extensionClassesForLanguage forKey:languageIdentifier];
    }
    [extensionClassesForLanguage setObject:extensionClass forKey:key];
}

- (id)initWithIndex:(TMIndex *)index codeFile:(CodeFile *)codeFile rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(index);
    self = [super init];
    if (!self)
        return nil;
    
    _index = index;
    _codeFile = codeFile;
    [_codeFile addPresenter:self];

    _scopesLock = OS_SPINLOCK_INIT;
    
    _internalQueue = [[NSOperationQueue alloc] init];
    _internalQueue.maxConcurrentOperationCount = 1;
    
    __weak TMUnit *weakSelf = self;
    [_internalQueue addOperationWithBlock:^{
        if (rootScopeIdentifier)
            weakSelf->_syntax = [TMSyntaxNode syntaxWithScopeIdentifier:rootScopeIdentifier];
        else
            weakSelf->_syntax = [TMSyntaxNode syntaxForCodeFile:codeFile];
        OSSpinLockLock(&weakSelf->_scopesLock);
        weakSelf->_rootScope = [[TMScope alloc] init];
        weakSelf->_rootScope.identifier = _syntax.scopeName;
        weakSelf->_rootScope.syntaxNode = _syntax;
        OSSpinLockUnlock(&weakSelf->_scopesLock);
    }];
    
    _pendingChangesLock = OS_SPINLOCK_INIT;
    Change *firstChange = [[Change alloc] init];
    firstChange->generation = [_codeFile currentGeneration];
    firstChange->oldRange = NSMakeRange(0, 0);
    firstChange->newRange = NSMakeRange(0, [_codeFile length]);
    _pendingChanges = [NSMutableArray arrayWithObject:firstChange];
    OSSpinLockLock(&_pendingChangesLock);
    [self _setHasPendingChanges];
    OSSpinLockUnlock(&_pendingChangesLock);
    
    _unparsedRanges = [[NSMutableIndexSet alloc] init];
    _blankRanges = [[NSMutableIndexSet alloc] init];
    _patternsIncludedByPattern = [NSMutableDictionary dictionary];
    
    _extensions = [[NSMutableDictionary alloc] init];
    [_extensionClasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![rootScopeIdentifier isEqualToString:key])
            return;
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id extension = [[obj alloc] initWithCodeUnit:self];
            if (!extension)
                return;
            [_extensions setObject:extension forKey:key];
        }];
    }];
    
    return self;
}

- (id)extensionForKey:(id)key
{
    return [_extensions objectForKey:key];
}

#pragma mark - Public Methods

- (TMIndex *)index
{
    return _index;
}

- (CodeFile *)codeFile
{
    return _codeFile;
}

- (void)rootScopeWithCompletionHandler:(void (^)(TMScope *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if ([_codeFile currentGeneration] == _scopesGeneration)
    {
        OSSpinLockLock(&_scopesLock);
        TMScope *rootScopeCopy = [_rootScope copy];
        OSSpinLockUnlock(&_scopesLock);
        completionHandler(rootScopeCopy);
    }
    else
    {
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self rootScopeWithCompletionHandler:completionHandler];
        } afterDelay:0.3];
    }
}

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(TMScope *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if ([_codeFile currentGeneration] == _scopesGeneration)
    {
        OSSpinLockLock(&_scopesLock);
        TMScope *scopeCopy = [[[self _scopeStackAtOffset:offset] lastObject] copy];
        OSSpinLockUnlock(&_scopesLock);
        completionHandler(scopeCopy);
    }
    else
    {
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self scopeAtOffset:offset withCompletionHandler:completionHandler];
        } afterDelay:0.3];
    }
}

- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

#pragma mark - CodeFilePresenter

- (void)codeFile:(CodeFile *)codeFile didReplaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)string
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    Change *change = [[Change alloc] init];
    change->generation = [codeFile currentGeneration];
    change->oldRange = range;
    change->newRange = NSMakeRange(range.location, [string length]);
    OSSpinLockLock(&_pendingChangesLock);
    [_pendingChanges addObject:change];
    [self _setHasPendingChanges];    
    OSSpinLockUnlock(&_pendingChangesLock);
}

#pragma mark - Private Methods

- (NSMutableArray *)_scopeStackAtOffset:(NSUInteger)offset
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:_rootScope];
    for (;;)
    {
        BOOL recurse = NO;
        for (TMScope *childScope in [[scopeStack lastObject] children])
            if (childScope.location < offset && childScope.location + childScope.length > offset)
            {
                [scopeStack addObject:childScope];
                recurse = YES;
                break;
            }
        if (!recurse)
            break;
    }
    return scopeStack;
}

- (void)_setHasPendingChanges
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ECASSERT(!OSSpinLockTry(&_pendingChangesLock));
    if (_hasPendingChanges)
    {
        OSSpinLockUnlock(&_pendingChangesLock);
        return;
    }
    _hasPendingChanges = YES;
    _isLoading = YES;
    __weak TMUnit *weakSelf = self;
    [_internalQueue addOperationWithBlock:^{
        [weakSelf _generateScopes];
    }];
}

- (void)_generateScopes
{
    // This is going to be the reference generation, if it changes we break out immediately because we know we're about to be called again
    CodeFileGeneration startingGeneration;
    
    // First of all, we apply all the pending changes to the scope tree, the unparsed ranges and the blank ranges
    OSSpinLockLock(&_pendingChangesLock);
    if (![_pendingChanges count])
        return;
    while ([_pendingChanges count])
    {
        Change *currentChange = [_pendingChanges objectAtIndex:0];
        [_pendingChanges removeObjectAtIndex:0];
        OSSpinLockUnlock(&_pendingChangesLock);
        // Save the change's generation as our starting generation, because new changes might be queued at any time outside of the lock, and we'd apply them too late then
        startingGeneration = currentChange->generation;
        NSRange oldRange = currentChange->oldRange;
        NSRange newRange = currentChange->newRange;
        // Adjust the scope tree to account for the change
        OSSpinLockLock(&_scopesLock);
        [self _shiftScopesByReplacingRange:oldRange withRange:newRange];
        OSSpinLockUnlock(&_scopesLock);
        // Replace the ranges in the unparsed ranges, use a placeholder range of length 1 if the new range is of length 0 because the change was a deletion
        [_unparsedRanges replaceIndexesInRange:oldRange withIndexesInRange:newRange.length ? newRange : NSMakeRange(newRange.location, 1)];
        // Shift the blank ranges around, no need to add the new ranges to these yet, we'll do that once we parse them
        [_blankRanges shiftIndexesByReplacingRange:oldRange withRange:newRange];
        OSSpinLockLock(&_pendingChangesLock);
    }
    // We're done applying the current pending changes, reset the hasPendingChanges flag
    _hasPendingChanges = NO;
    OSSpinLockUnlock(&_pendingChangesLock);
    
    // Next we parse the unparsed ranges. We always use our starting generation as expected generation.
    for (;;)
    {
        NSRange nextRange = [_unparsedRanges firstRange];
        // If no first range we're done here, move on to the next step
        if (nextRange.location == NSNotFound)
            break;
                
        // Get the first line range
        NSRange lineRange = NSMakeRange(nextRange.location, 0);
        if (![self.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:startingGeneration])
            return;

        // Setup the scope stack
        OSSpinLockLock(&_scopesLock);
        NSMutableArray *scopeStack = [[self _scopeStackAtOffset:lineRange.location] mutableCopy];
        OSSpinLockUnlock(&_scopesLock);

        // Parse the range
        NSUInteger previousTokenStart = 0;
        NSUInteger previousTokenEnd = 0;
        for (;;)
        {
            // If we went over the end of the current unparsed range, break out
            if (lineRange.location >= NSMaxRange(nextRange))
                break;
            
            // Add the line to the unparsed ranges, this way if we break out before we're done parsing it we can try again later
            [_unparsedRanges addIndexesInRange:lineRange];
            
            // Delete all scopes in the line
            {
//                NSMutableArray *childScopeIndexStack = [[NSMutableArray alloc] init];
//                OSSpinLockLock(&_scopesLock);
//                TMScope *scope = _rootScope;
//                NSUInteger childScopeIndex = 0;
//                for (;;)
//                {
//                    NSRange scopeRange = NSMakeRange(scope.location, scope.length);
//                    if (NSIntersectionRange(scopeRange, lineRange).length)
//                    {
//                        
//                    }
//                    else
//                    {
//                        
//                    }
//                }
//                OSSpinLockUnlock(&_scopesLock);
            }
            
            // Setup the line
            NSString *uncachedString;
            if (![self.codeFile string:&uncachedString inRange:lineRange expectedGeneration:startingGeneration])
                return;
            CStringCachingString *line = [CStringCachingString stringWithString:uncachedString];
            NSUInteger position = 0;
            for (;;)
            {
#warning TODO from here on we can't really break out without extending the range of the containing scopes to cover all the child scopes, so we need to check for that
                TMScope *scope = [scopeStack lastObject];
                TMSyntaxNode *syntaxNode = scope.syntaxNode;
                                
                // Find the first matching pattern
                TMSyntaxNode *firstSyntaxNode = nil;
                OnigResult *firstResult = nil;
                NSArray *patterns = [self _patternsIncludedByPattern:syntaxNode];
                for (TMSyntaxNode *pattern in patterns)
                {
                    OnigRegexp *patternRegexp = pattern.match;
                    if (!patternRegexp)
                        patternRegexp = pattern.begin;
                    ECASSERT(patternRegexp);
                    OnigResult *result = [patternRegexp search:line start:position];
                    if (!result || (firstResult && [firstResult bodyRange].location <= [result bodyRange].location))
                        continue;
                    firstResult = result;
                    firstSyntaxNode = pattern;
                }
                
                // Find the end match
                OnigResult *endResult = [scope.endRegexp search:line start:position];
                
                ECASSERT(!firstSyntaxNode || firstResult);
                
                // Handle the matches
                if (endResult && (!firstResult || [firstResult bodyRange].location >= [endResult bodyRange].location ))
                {
                    // Handle end result first
                    NSRange resultRange = [endResult bodyRange];
                    // Handle content name nested scope
                    if (syntaxNode.contentName)
                    {
                        previousTokenEnd = resultRange.location + lineRange.location;
                        if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:startingGeneration])
                            return;
                        previousTokenStart = previousTokenEnd;
                        scope.length = resultRange.location + lineRange.location - scope.location;
                        scope.completelyParsed = YES;
                        [scopeStack removeLastObject];
                        scope = [scopeStack lastObject];
                    }
                    previousTokenEnd = NSMaxRange(resultRange) + lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = previousTokenEnd;
                    // Handle end captures
                    [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult offset:lineRange.location inScope:scope generation:startingGeneration];
                    scope.length = NSMaxRange(resultRange) + lineRange.location - scope.location;
                    scope.completelyParsed = YES;
                    if ([scopeStack count] == 1)
                        return;
                    [scopeStack removeLastObject];
                    // We don't need to make sure position advances since we changed the stack
                    // This could bite us if there's a begin and end regexp that match in the same position
                    position = NSMaxRange(resultRange);
                }
                else if (firstSyntaxNode.match)
                {
                    // Handle a match pattern
                    NSRange resultRange = [firstResult bodyRange];
                    previousTokenEnd = resultRange.location + lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = previousTokenEnd;
                    TMScope *matchScope = [scope newChildScope];
                    matchScope.identifier = firstSyntaxNode.scopeName;
                    matchScope.syntaxNode = firstSyntaxNode;
                    matchScope.location = resultRange.location + lineRange.location;
                    matchScope.length = resultRange.length;
                    matchScope.completelyParsed = YES;
                    previousTokenEnd = NSMaxRange(resultRange) + lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:matchScope generation:startingGeneration])
                        return;
                    previousTokenStart = previousTokenEnd;
                    // Handle match pattern captures
                    [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult offset:lineRange.location inScope:matchScope generation:startingGeneration];
                    // We need to make sure position increases, or it would loop forever with a 0 width match
                    NSUInteger newPosition = NSMaxRange(resultRange);
                    if (position == newPosition)
                        ++position;
                    else
                        position = newPosition;
                }
                else if (firstSyntaxNode.begin)
                {
                    // Handle a new span pattern
                    NSRange resultRange = [firstResult bodyRange];
                    previousTokenEnd = resultRange.location + lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = previousTokenEnd;
                    TMScope *spanScope = [scope newChildScope];
                    spanScope.identifier = firstSyntaxNode.scopeName;
                    spanScope.syntaxNode = firstSyntaxNode;
                    spanScope.location = resultRange.location + lineRange.location;
                    // Create the end regexp
                    NSMutableString *end = [NSMutableString stringWithString:firstSyntaxNode.end];
                    [_numberedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
                        int captureNumber = [[result stringAt:1] intValue];
                        if (captureNumber >= 0 && [firstResult count] > captureNumber)
                            return [firstResult stringAt:captureNumber];
                        else
                            return nil;
                    }];
                    [_namedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
                        NSString *captureName = [result stringAt:1];
                        int captureNumber = [firstResult indexForName:captureName];
                        if (captureNumber >= 0 && [firstResult count] > captureNumber)
                            return [firstResult stringAt:captureNumber];
                        else
                            return nil;
                    }];
                    spanScope.endRegexp = [OnigRegexp compile:end options:OnigOptionCaptureGroup];
                    ECASSERT(spanScope.endRegexp);
                    // Handle begin captures
                    previousTokenEnd = NSMaxRange(resultRange) + lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = previousTokenEnd;
                    if (![self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult offset:lineRange.location inScope:spanScope generation:startingGeneration])
                        return;
                    [scopeStack addObject:spanScope];
                    // Handle content name nested scope
                    if (firstSyntaxNode.contentName)
                    {
                        TMScope *contentScope = [spanScope newChildScope];
                        contentScope.identifier = firstSyntaxNode.contentName;
                        contentScope.syntaxNode = firstSyntaxNode;
                        contentScope.location = NSMaxRange(resultRange) + lineRange.location;
                        contentScope.endRegexp = spanScope.endRegexp;
                        [scopeStack addObject:contentScope];
                    }
                    // We don't need to make sure position advances since we changed the stack
                    // This could bite us if there's a begin and end regexp that match in the same position
                    position = NSMaxRange(resultRange);
                }
                else
                    break;
                
                // We need to break if we hit the end of the line, failing to do so not only runs another cycle that doesn't find anything 99% of the time, but also can cause problems with matches that include the newline which have to be the last match for the line in the remaining 1% of the cases
                if (position >= lineRange.length)
                    break;
            }
            // Stretch all remaining scopes to cover the current line
            NSUInteger lineEnd = NSMaxRange(lineRange);
            for (TMScope *scope in scopeStack)
                scope.length = lineEnd - scope.location;
            // Remove the parsed line from the unparsed ranges
            [_unparsedRanges removeIndexesInRange:lineRange];
            // proceed to next line
            lineRange = NSMakeRange(NSMaxRange(lineRange), 0);
            if (![self.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:startingGeneration])
                return;
        }
    }
}

- (BOOL)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result offset:(NSUInteger)offset inScope:(TMScope *)scope generation:(CodeFileGeneration)generation
{
    ECASSERT([NSOperationQueue currentQueue] == _internalQueue);
    ECASSERT(scope);
    if (!dictionary || !result)
        return YES;
    TMScope *capturesScope = scope;
    NSString *name = [[dictionary objectForKey:@"0"] objectForKey:_captureName];
    if (name)
    {
        ECASSERT([name isKindOfClass:[NSString class]]);
        capturesScope = [scope newChildScope];
        capturesScope.identifier = name;
        capturesScope.location = [result bodyRange].location + offset;
        capturesScope.length = [result bodyRange].length;
        capturesScope.completelyParsed = YES;
        if (![self _parsedTokenInRange:NSMakeRange(capturesScope.location, capturesScope.length) withScope:capturesScope generation:generation])
            return NO;
    }
    NSUInteger numMatchRanges = [result count];
    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
    {
        NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
        if (!currentMatchRange.length)
            continue;
        NSString *currentCaptureName = [[dictionary objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_captureName];
        if (!currentCaptureName)
            continue;
        ECASSERT([currentCaptureName isKindOfClass:[NSString class]]);
        TMScope *currentCaptureScope = [capturesScope ? capturesScope : scope newChildScope];
        currentCaptureScope.identifier = currentCaptureName;
        ECASSERT(currentMatchRange.location >= [result bodyRange].location && NSMaxRange(currentMatchRange) <= NSMaxRange([result bodyRange]));
        currentCaptureScope.location = currentMatchRange.location + offset;
        currentCaptureScope.length = currentMatchRange.length;
        currentCaptureScope.completelyParsed = YES;
        if (![self _parsedTokenInRange:NSMakeRange(currentCaptureScope.location, currentCaptureScope.length) withScope:currentCaptureScope generation:generation])
            return NO;
    }
    return YES;
}

- (void)_shiftScopesByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
    ECASSERT(oldRange.location == newRange.location);
    
    NSMutableArray *scopeEnumeratorStack = [NSMutableArray arrayWithObject:[[NSArray arrayWithObject:_rootScope] objectEnumerator]];
    NSUInteger oldRangeEnd = NSMaxRange(oldRange);
    NSInteger offset = newRange.length - oldRange.length;
    // Enumerate all the scopes and adjust them for the change
    while ([scopeEnumeratorStack count])
    {
        TMScope *scope = nil;
        while (scope = [[scopeEnumeratorStack lastObject] nextObject])
        {
            if (scope.location + scope.length <= oldRange.location)
            {
                // If the scope is before the affected range, continue to the next scope
                continue;
            }
            else if (scope.location >= oldRange.location && scope.location < oldRangeEnd)
            {
                // If the scope's start is within the affected range it's going to get removed during regeneration, just continue to the next scope
                continue;
            }
            else if (scope.location >= oldRangeEnd)
            {
                // If the scope is past the affected range, shift the location
                scope.location += offset;
            }
            else if (scope.location + scope.length < oldRangeEnd)
            {
                // If the affected range overlaps the tail of the scope, cut it off
                scope.length -= NSIntersectionRange(NSMakeRange(scope.location, scope.length), oldRange).length;
            }
            else
            {
                // If the scope is none of the above, the affected range is completely contained in it, let's stretch it to cover the difference
                ECASSERT(oldRange.length < scope.length && scope.location < oldRange.location && scope.location + scope.length >= NSMaxRange(oldRange));
                scope.length += offset;
            }
            
            // Recurse over the scope's children
            if (scope.children.count)
                [scopeEnumeratorStack addObject:scope.children.objectEnumerator];
        }
        [scopeEnumeratorStack removeLastObject];
    }
}

- (BOOL)_addedScope:(TMScope *)scope withGeneration:(CodeFileGeneration)generation
{
    return YES;
}

- (BOOL)_removedScope:(TMScope *)scope withGeneration:(CodeFileGeneration)generation
{
    return YES;
}

- (BOOL)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope generation:(CodeFileGeneration)generation
{
    if (scope)
    {
        NSDictionary *attributes = [self.codeFile.theme attributesForScope:scope];
        if ([attributes count])
            return [self.codeFile addAttributes:attributes range:tokenRange expectedGeneration:generation];
        return YES;
    }
    else
    {
        return [self.codeFile removeAllAttributesInRange:tokenRange expectedGeneration:generation];
    }
}

- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern
{
    ECASSERT([NSOperationQueue currentQueue] == _internalQueue);
    NSMutableArray *includedPatterns = [_patternsIncludedByPattern objectForKey:pattern];
    if (includedPatterns)
        return includedPatterns;
    if (!pattern.patterns)
        return nil;
    includedPatterns = [NSMutableArray arrayWithArray:pattern.patterns];
    NSMutableSet *dereferencedPatterns = [NSMutableSet set];
    NSMutableIndexSet *containerPatternIndexes = [NSMutableIndexSet indexSet];
    do
    {
        [containerPatternIndexes removeAllIndexes];
        [includedPatterns enumerateObjectsUsingBlock:^(TMSyntaxNode *obj, NSUInteger idx, BOOL *stop) {
            if ([obj match] || [obj begin])
                return;
            [containerPatternIndexes addIndex:idx];
        }];
        __block NSUInteger offset = 0;
        [containerPatternIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            TMSyntaxNode *containerPattern = [includedPatterns objectAtIndex:idx + offset];
            [includedPatterns removeObjectAtIndex:idx + offset];
            if ([dereferencedPatterns containsObject:containerPattern])
                return;
            ECASSERT(containerPattern.include || containerPattern.patterns);
            ECASSERT(!containerPattern.include || !containerPattern.patterns);
            if (containerPattern.include)
            {
                unichar firstCharacter = [containerPattern.include characterAtIndex:0];
                if (firstCharacter == '#')
                {
                    TMSyntaxNode *patternSyntax = [containerPattern rootSyntax];
                    [includedPatterns insertObject:[patternSyntax.repository objectForKey:[containerPattern.include substringFromIndex:1]] atIndex:idx + offset];
                }
                else
                {
                    ECASSERT(firstCharacter != '$' || [containerPattern.include isEqualToString:@"$base"] || [containerPattern.include isEqualToString:@"$self"]);
                    TMSyntaxNode *includedSyntax = nil;
                    if ([containerPattern.include isEqualToString:@"$base"])
                        includedSyntax = _syntax;
                    else if ([containerPattern.include isEqualToString:@"$self"])
                        includedSyntax = [containerPattern rootSyntax];
                    else
                        includedSyntax = [TMSyntaxNode syntaxWithScopeIdentifier:containerPattern.include];
                    [includedPatterns addObject:includedSyntax];
                }
            }
            else
            {
                NSUInteger patternsCount = [containerPattern.patterns count];
                ECASSERT(patternsCount);
                [includedPatterns insertObjects:containerPattern.patterns atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx + offset, patternsCount)]];
                offset += patternsCount - 1;
            }
            [dereferencedPatterns addObject:containerPattern];
        }];
    }
    while ([containerPatternIndexes count]);
    [_patternsIncludedByPattern setObject:includedPatterns forKey:pattern];
    return includedPatterns;
}

@end

@implementation TMSymbol

@synthesize title = _title, icon = _icon, range = _range, indentation = _indentation, separator = _separator;

- (id)initWithTitle:(NSString *)title icon:(UIImage *)icon range:(NSRange)range
{
    self = [super init];
    if (!self)
        return nil;
    // Get indentation level and modify title
    NSUInteger titleLength = [_title length];
    for (; _indentation < titleLength; ++_indentation)
    {
        if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[title characterAtIndex:_indentation]])
            break;
    }
    _title = _indentation ? [title substringFromIndex:_indentation] : title;
    _icon = icon;
    _range = range;
    return self;
}

@end
