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
    NSMutableDictionary *_patternsIncludedByPattern;
    NSMutableDictionary *_extensions;
}
- (NSMutableArray *)_scopeStackAtOffset:(NSUInteger)offset options:(TMUnitScopeQueryOptions)options;
- (void)_setHasPendingChanges;
- (void)_generateScopes;
- (BOOL)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result offset:(NSUInteger)offset inScope:(TMScope *)scope generation:(CodeFileGeneration)generation;
- (void)_shiftScopesByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange;
- (void)_removeScopesInRange:(NSRange)range;
- (void)_addedScope:(TMScope *)scope;
- (void)_removedScope:(TMScope *)scope;
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
        TMUnit *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        if (rootScopeIdentifier)
            strongSelf->_syntax = [TMSyntaxNode syntaxWithScopeIdentifier:rootScopeIdentifier];
        else
            strongSelf->_syntax = [TMSyntaxNode syntaxForCodeFile:codeFile];
        OSSpinLockLock(&strongSelf->_scopesLock);
        strongSelf->_rootScope = [[TMScope alloc] init];
        strongSelf->_rootScope.identifier = _syntax.scopeName;
        strongSelf->_rootScope.syntaxNode = _syntax;
        OSSpinLockUnlock(&strongSelf->_scopesLock);
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

- (void)scopeAtOffset:(NSUInteger)offset options:(TMUnitScopeQueryOptions)options withCompletionHandler:(void (^)(TMScope *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if ([_codeFile currentGeneration] == _scopesGeneration)
    {
        OSSpinLockLock(&_scopesLock);
        TMScope *scopeCopy = [[[self _scopeStackAtOffset:offset options:options] lastObject] copy];
        OSSpinLockUnlock(&_scopesLock);
        completionHandler(scopeCopy);
    }
    else
    {
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self scopeAtOffset:offset options:options withCompletionHandler:completionHandler];
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

- (NSMutableArray *)_scopeStackAtOffset:(NSUInteger)offset options:(TMUnitScopeQueryOptions)options
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
    if (offset >= _rootScope.length)
        return nil;
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:_rootScope];
    for (;;)
    {
        BOOL recurse = NO;
        for (TMScope *childScope in [[scopeStack lastObject] children])
        {
            NSRange childScopeRange = NSMakeRange(childScope.location, childScope.length);
            NSUInteger childScopeEnd = NSMaxRange(childScopeRange);
            if ((options == TMUnitScopeQueryContainedOnly && childScopeRange.location < offset && childScopeEnd > offset)
                || (options == TMUnitScopeQueryAdjacentStart && childScopeRange.location <= offset && childScopeEnd > offset)
                || (options == TMUnitScopeQueryAdjacentEnd && childScopeRange.location < offset && childScopeEnd > offset))
            {
                [scopeStack addObject:childScope];
                recurse = YES;
                break;
            }
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
        return;
    _hasPendingChanges = YES;
    _isLoading = YES;
    __weak TMUnit *weakSelf = self;
    [_internalQueue addOperationWithBlock:^{
        TMUnit *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        OSSpinLockLock(&strongSelf->_scopesLock);
        [strongSelf _generateScopes];
        OSSpinLockUnlock(&strongSelf->_scopesLock);
    }];
}

- (void)_generateScopes
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
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
        ECASSERT(oldRange.location == newRange.location);
        // Adjust the scope tree to account for the change
        [self _shiftScopesByReplacingRange:oldRange withRange:newRange];
        // Replace the ranges in the unparsed ranges, add a placeholder if the change was a deletion so we know the part right after the deletion needs to be reparsed
        [_unparsedRanges replaceIndexesInRange:oldRange withIndexesInRange:newRange];
        if (!newRange.length)
            [_unparsedRanges addIndex:newRange.location];
        OSSpinLockLock(&_pendingChangesLock);
    }
    // We're done applying the current pending changes, reset the hasPendingChanges flag and get the next range
    _hasPendingChanges = NO;
    NSRange nextRange = [_unparsedRanges firstRange];    
    OSSpinLockUnlock(&_pendingChangesLock);
    
    // Parse the next range
    while (nextRange.location != NSNotFound)
    {
        // Get the first line range
        NSRange lineRange = NSMakeRange(nextRange.location, 0);
        if (![self.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:startingGeneration])
            return;

        // Setup the scope stack
        NSMutableArray *scopeStack = [self _scopeStackAtOffset:lineRange.location options:TMUnitScopeQueryAdjacentEnd];
        if (!scopeStack)
            scopeStack = [NSMutableArray arrayWithObject:_rootScope];

        // Parse the range
        NSUInteger previousTokenStart = lineRange.location;
        while (lineRange.location < NSMaxRange(nextRange))
        {
            // Mark the whole line as unparsed so we don't miss parts of it if we get interrupted
            OSSpinLockLock(&_pendingChangesLock);
            [_unparsedRanges addIndexesInRange:lineRange];
            OSSpinLockUnlock(&_pendingChangesLock);
            
            // Delete all scopes in the line
            [self _removeScopesInRange:lineRange];
            
            // Setup the line
            NSString *uncachedString;
            if (![self.codeFile string:&uncachedString inRange:lineRange expectedGeneration:startingGeneration])
                return;
            
            CStringCachingString *line = [CStringCachingString stringWithString:uncachedString];
            NSUInteger position = 0;
            // Parse the line
            for (;;)
            {
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
                    resultRange.location += lineRange.location;
                    // Handle content name nested scope
                    if (syntaxNode.contentName)
                    {
                        if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope generation:startingGeneration])
                            return;
                        previousTokenStart = resultRange.location;
                        scope.length = resultRange.location - scope.location;
                        [scopeStack removeLastObject];
                        scope = [scopeStack lastObject];
                    }
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = NSMaxRange(resultRange);
                    // Handle end captures
                    [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult offset:lineRange.location inScope:scope generation:startingGeneration];
                    scope.length = NSMaxRange(resultRange) - scope.location;
                    ECASSERT([scopeStack count]);
                    [scopeStack removeLastObject];
                    // We don't need to make sure position advances since we changed the stack
                    // This could bite us if there's a begin and end regexp that match in the same position
                    position = NSMaxRange([endResult bodyRange]);
                }
                else if (firstSyntaxNode.match)
                {
                    // Handle a match pattern
                    NSRange resultRange = [firstResult bodyRange];
                    resultRange.location += lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = resultRange.location;
                    TMScope *matchScope = [scope newChildScope];
                    matchScope.identifier = firstSyntaxNode.scopeName;
                    matchScope.syntaxNode = firstSyntaxNode;
                    matchScope.location = resultRange.location;
                    matchScope.length = resultRange.length;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:matchScope generation:startingGeneration])
                        return;
                    previousTokenStart = NSMaxRange(resultRange);
                    // Handle match pattern captures
                    [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult offset:lineRange.location inScope:matchScope generation:startingGeneration];
                    // We need to make sure position increases, or it would loop forever with a 0 width match
                    NSUInteger newPosition = NSMaxRange([firstResult bodyRange]);
                    if (position == newPosition)
                        ++position;
                    else
                        position = newPosition;
                }
                else if (firstSyntaxNode.begin)
                {
                    // Handle a new span pattern
                    NSRange resultRange = [firstResult bodyRange];
                    resultRange.location += lineRange.location;
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = resultRange.location;
                    TMScope *spanScope = [scope newChildScope];
                    spanScope.identifier = firstSyntaxNode.scopeName;
                    spanScope.syntaxNode = firstSyntaxNode;
                    spanScope.location = resultRange.location;
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
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:scope generation:startingGeneration])
                        return;
                    previousTokenStart = NSMaxRange(resultRange);
                    if (![self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult offset:lineRange.location inScope:spanScope generation:startingGeneration])
                        return;
                    [scopeStack addObject:spanScope];
                    // Handle content name nested scope
                    if (firstSyntaxNode.contentName)
                    {
                        TMScope *contentScope = [spanScope newChildScope];
                        contentScope.identifier = firstSyntaxNode.contentName;
                        contentScope.syntaxNode = firstSyntaxNode;
                        contentScope.location = NSMaxRange(resultRange);
                        contentScope.endRegexp = spanScope.endRegexp;
                        [scopeStack addObject:contentScope];
                    }
                    // We don't need to make sure position advances since we changed the stack
                    // This could bite us if there's a begin and end regexp that match in the same position
                    position = NSMaxRange([firstResult bodyRange]);
                }
                else
                {
                    break;
                }
                
                // We need to break if we hit the end of the line, failing to do so not only runs another cycle that doesn't find anything 99% of the time, but also can cause problems with matches that include the newline which have to be the last match for the line in the remaining 1% of the cases
                if (position >= lineRange.length)
                    break;
            }
            if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(lineRange) - previousTokenStart) withScope:[scopeStack lastObject] generation:startingGeneration])
                return;
            // Stretch all remaining scopes to cover to the end of the line
            for (TMScope *scope in scopeStack)
            {
                NSUInteger stretchedLength = NSMaxRange(lineRange) - scope.location;
                if (stretchedLength > scope.length)
                    scope.length = stretchedLength;
            }
            // Remove the line range from the unparsed ranges
            OSSpinLockLock(&_pendingChangesLock);
            [_unparsedRanges removeIndexesInRange:lineRange];
            OSSpinLockUnlock(&_pendingChangesLock);
            // proceed to next line
            lineRange = NSMakeRange(NSMaxRange(lineRange), 0);
            if (![self.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:startingGeneration])
                return;
        }
        // The lineRange now refers to the first line after the unparsed range we just finished parsing. We check whether the scope stack at the end of the range we just finished parsing and the scope stack at the beginning of the range that was parsed before match, if they don't, it means the changes influenced this line too, so we add it to the unparsed changes
        NSArray *nextScopeStack = [self _scopeStackAtOffset:lineRange.location options:TMUnitScopeQueryContainedOnly];
        __block BOOL reparseLine = NO;
        if (scopeStack.count == nextScopeStack.count)
        {
            [scopeStack enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if (obj == [nextScopeStack objectAtIndex:idx])
                    return;
                reparseLine = YES;
                *stop = YES;
            }];
        }
        OSSpinLockLock(&_pendingChangesLock);
        if (reparseLine || (nextScopeStack && nextScopeStack.count != scopeStack.count))
            [_unparsedRanges addIndex:lineRange.location];
        nextRange = [_unparsedRanges firstRange];
        OSSpinLockUnlock(&_pendingChangesLock);
    }
    _scopesGeneration = startingGeneration;
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
            NSRange scopeRange = NSMakeRange(scope.location, scope.length);
            if (NSMaxRange(scopeRange) <= oldRange.location)
            {
                // If the scope is before the affected range, continue to the next scope
                continue;
            }
            else if (scopeRange.location >= oldRange.location && scopeRange.location < oldRangeEnd)
            {
                // If the scope's start is within the affected range it's going to get removed during regeneration, just continue to the next scope
                continue;
            }
            else if (scopeRange.location >= oldRangeEnd)
            {
                // If the scope is past the affected range, shift the location
                scope.location += offset;
            }
            else if (NSMaxRange(scopeRange) < oldRangeEnd)
            {
                // If the affected range overlaps the tail of the scope, cut it off
                scope.length -= NSIntersectionRange(NSMakeRange(scope.location, scope.length), oldRange).length;
            }
            else
            {
                // If the scope is none of the above, the affected range is completely contained in it, let's stretch it to cover the difference
                ECASSERT(oldRange.length < scopeRange.length && scopeRange.location < oldRange.location && NSMaxRange(scopeRange) >= NSMaxRange(oldRange));
                scope.length += offset;
            }
            
            // Recurse over the scope's children
            if (scope.children.count)
                [scopeEnumeratorStack addObject:scope.children.objectEnumerator];
        }
        [scopeEnumeratorStack removeLastObject];
    }
}

- (void)_removeScopesInRange:(NSRange)range
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
    NSMutableArray *childScopeIndexStack = [[NSMutableArray alloc] init];
    TMScope *scope = _rootScope;
    NSUInteger childScopeIndex = 0;
    for (;;)
    {
        if (childScopeIndex + 1 <= scope.children.count)
        {
            TMScope *childScope = [scope.children objectAtIndex:childScopeIndex];
            NSRange childScopeRange = NSMakeRange(childScope.location, childScope.length);
            if (NSMaxRange(childScopeRange) <= range.location)
            {
                // If the child scope is before the affected range, continue to the next scope
                ++childScopeIndex;
                continue;
            }
            else if (childScopeRange.location >= range.location && childScopeRange.location < NSMaxRange(range))
            {
                // If the child scope's start is within the affected range, delete it
                [self _removedScope:childScope];
                [scope.children removeObjectAtIndex:childScopeIndex];
                continue;
            }
            else if (childScopeRange.location < NSMaxRange(range))
            {
                // If it's neither of the above two cases, but it doesn't start after the line either, it means it overlaps, recurse over it's children
                [childScopeIndexStack addObject:[NSNumber numberWithUnsignedInteger:childScopeIndex]];
                childScopeIndex = 0;
                scope = childScope;
                continue;
            }
        }
        // If we got here it means we're done enumerating this scope's children, go back to enumerating it's siblings
        if (!childScopeIndexStack.count)
            break;
        childScopeIndex = [[childScopeIndexStack lastObject] unsignedIntegerValue];
        [childScopeIndexStack removeLastObject];
        ++childScopeIndex;
        scope = scope.parent;
    }
}

- (void)_addedScope:(TMScope *)scope
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
    
}

- (void)_removedScope:(TMScope *)scope
{
    ECASSERT(!OSSpinLockTry(&_scopesLock));
    
}

- (BOOL)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope generation:(CodeFileGeneration)generation
{
    NSDictionary *attributes = [self.codeFile.theme attributesForScope:scope];
    if (![attributes count])
        return YES;
    return [self.codeFile setAttributes:attributes range:tokenRange expectedGeneration:generation];
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
