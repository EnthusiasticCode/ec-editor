//
//  TMUnit.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"
#import "TMIndex.h"
#import "TMScope+Internal.h"
#import "TMTheme.h"
#import "TMBundle.h"
#import "TMPreference.h"
#import "TMSyntaxNode.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "NSString+CStringCaching.h"
#import "NSIndexSet+StringRanges.h"
#import "ACProjectFile.h"
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

@interface TMUnit () <CodeFilePresenter>

- (void)_setHasPendingChanges;
- (void)_generateScopes;
- (BOOL)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack generation:(CodeFileGeneration)generation;
- (BOOL)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope generation:(CodeFileGeneration)generation;
- (BOOL)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope generation:(CodeFileGeneration)generation;
- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern;

@end

@implementation TMUnit {
    ACProjectFile *_projectFile;
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

@synthesize loading = _isLoading;

#pragma mark - Internal Methods

+ (void)initialize {
    if (self != [TMUnit class])
        return;
    _numberedCapturesRegexp = [OnigRegexp compile:@"\\\\([1-9])" options:OnigOptionCaptureGroup];
    _namedCapturesRegexp = [OnigRegexp compile:@"\\\\k<(.*?)>" options:OnigOptionCaptureGroup];
    ASSERT(_numberedCapturesRegexp && _namedCapturesRegexp);
}

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key {
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

- (id)initWithProjectFile:(ACProjectFile *)projectFile {
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    self = [super init];
    if (!self)
        return nil;
    
    _projectFile = projectFile;
    
    [projectFile.codeFile addPresenter:self];

    _scopesLock = OS_SPINLOCK_INIT;
    
    _internalQueue = [[NSOperationQueue alloc] init];
    _internalQueue.maxConcurrentOperationCount = 1;

    OSSpinLockLock(&_scopesLock);
    _rootScope = [TMScope newRootScopeWithIdentifier:_projectFile.syntax.scopeName syntaxNode:_projectFile.syntax];
    OSSpinLockUnlock(&_scopesLock);
    
    _pendingChangesLock = OS_SPINLOCK_INIT;
    Change *firstChange = [[Change alloc] init];
    firstChange->generation = [projectFile.codeFile currentGeneration];
    firstChange->oldRange = NSMakeRange(0, 0);
    firstChange->newRange = NSMakeRange(0, [projectFile.codeFile length]);
    _pendingChanges = [NSMutableArray arrayWithObject:firstChange];
    OSSpinLockLock(&_pendingChangesLock);
    [self _setHasPendingChanges];
    OSSpinLockUnlock(&_pendingChangesLock);
    
    _unparsedRanges = [[NSMutableIndexSet alloc] init];
    _patternsIncludedByPattern = [NSMutableDictionary dictionary];
    
    _extensions = [[NSMutableDictionary alloc] init];
    [_extensionClasses enumerateKeysAndObjectsUsingBlock:^(NSString *extensionClassesSyntaxIdentifier, NSDictionary *extensionClasses, BOOL *outerStop) {
        if (![_projectFile.syntaxIdentifier isEqualToString:extensionClassesSyntaxIdentifier])
            return;
        [extensionClasses enumerateKeysAndObjectsUsingBlock:^(NSString *extensionClassSyntaxIdentifier, Class extensionClass, BOOL *innerStop) {
            id extension = [[extensionClass alloc] initWithCodeUnit:self];
            if (!extension)
                return;
            [_extensions setObject:extension forKey:extensionClassSyntaxIdentifier];
        }];
    }];
    
    return self;
}

- (id)extensionForKey:(id)key
{
    return [_extensions objectForKey:key];
}

#pragma mark - Public Methods

- (void)rootScopeWithCompletionHandler:(void (^)(TMScope *))completionHandler
{
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    BOOL generationsMatch = NO;
    if (OSSpinLockTry(&_scopesLock))
    {
        generationsMatch = [_projectFile.codeFile currentGeneration] == _scopesGeneration;
        TMScope *scopeCopy = nil;
        if (generationsMatch)
            scopeCopy = [_rootScope copy];
        OSSpinLockUnlock(&_scopesLock);
        if (generationsMatch)
            completionHandler(scopeCopy);
    }
    
    if (!generationsMatch)
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self rootScopeWithCompletionHandler:completionHandler];
        } afterDelay:0.2];
}

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(TMScope *))completionHandler
{
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    BOOL generationsMatch = NO;
    if (OSSpinLockTry(&_scopesLock))
    {
        generationsMatch = [_projectFile.codeFile currentGeneration] == _scopesGeneration;
        TMScope *scopeCopy = nil;
        if (generationsMatch)
            scopeCopy = [[[_rootScope scopeStackAtOffset:offset options:TMScopeQueryRight] lastObject] copy];
        OSSpinLockUnlock(&_scopesLock);
        if (generationsMatch)
            completionHandler(scopeCopy);
    }
    
    if (!generationsMatch)
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self scopeAtOffset:offset withCompletionHandler:completionHandler];
        } afterDelay:0.2];
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
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
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

- (void)_setHasPendingChanges
{
    ASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    ASSERT(!OSSpinLockTry(&_pendingChangesLock));
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
    ASSERT(!OSSpinLockTry(&_scopesLock));
    ASSERT([NSOperationQueue currentQueue] == _internalQueue);

    // This is going to be the reference generation, if it changes we break out immediately because we know we're about to be called again
    CodeFileGeneration startingGeneration = 0;
    
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
        ASSERT(oldRange.location == newRange.location);
        // Adjust the scope tree to account for the change
        [_rootScope shiftByReplacingRange:oldRange withRange:newRange];
        // Replace the ranges in the unparsed ranges, add a placeholder if the change was a deletion so we know the part right after the deletion needs to be reparsed
        [_unparsedRanges replaceIndexesInRange:oldRange withIndexesInRange:newRange];
        if (!newRange.length)
            [_unparsedRanges addIndex:newRange.location];
        OSSpinLockLock(&_pendingChangesLock);
    }
    // We're done applying the current pending changes, reset the hasPendingChanges flag
    _hasPendingChanges = NO;
    
    // Clip off unparsed ranges that are past the end of the file (it can happen because of placeholder ranges on deletion)
    NSUInteger fileLength;
    if (![_projectFile.codeFile length:&fileLength expectedGeneration:startingGeneration])
    {
        OSSpinLockUnlock(&_pendingChangesLock);
        return;
    }
    [_unparsedRanges removeIndexesInRange:NSMakeRange(fileLength, NSUIntegerMax - fileLength)];
    
    // Get the next unparsed range
    NSRange nextRange = [_unparsedRanges firstRange];
    OSSpinLockUnlock(&_pendingChangesLock);
        
    NSMutableArray *scopeStack = nil;
    
    // Parse the next range
    while (nextRange.location != NSNotFound)
    {
        // Get the first line range
        NSRange lineRange = NSMakeRange(nextRange.location, 0);
        if (![_projectFile.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:startingGeneration])
            return;
        // Zero length line means end of file
        if (!lineRange.length)
            return;

        // Setup the scope stack
        if (!scopeStack)
            scopeStack = [_rootScope scopeStackAtOffset:lineRange.location options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
        if (!scopeStack)
            scopeStack = [NSMutableArray arrayWithObject:_rootScope];

        // Parse the range
        while (lineRange.location < NSMaxRange(nextRange))
        {
            // Mark the whole line as unparsed so we don't miss parts of it if we get interrupted
            OSSpinLockLock(&_pendingChangesLock);
            [_unparsedRanges addIndexesInRange:lineRange];
            OSSpinLockUnlock(&_pendingChangesLock);
            
            // Delete all scopes in the line
            [_rootScope removeChildScopesInRange:lineRange];
            
            // Setup the line
            NSString *line;
            if (![_projectFile.codeFile string:&line inRange:lineRange expectedGeneration:startingGeneration])
                return;
            
            // Parse the line
            BOOL success = [self _generateScopesWithLine:line range:lineRange scopeStack:scopeStack generation:startingGeneration];
            
            // Stretch all remaining scopes to cover to the end of the line
            for (TMScope *scope in scopeStack)
            {
                NSUInteger stretchedLength = NSMaxRange(lineRange) - scope.location;
                if (stretchedLength > scope.length)
                    scope.length = stretchedLength;
            }
            
            if (!success)
                return;
            
            // Remove the line range from the unparsed ranges
            OSSpinLockLock(&_pendingChangesLock);
            [_unparsedRanges removeIndexesInRange:lineRange];
            OSSpinLockUnlock(&_pendingChangesLock);
            // proceed to next line
            lineRange = NSMakeRange(NSMaxRange(lineRange), 0);
            if (![_projectFile.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:startingGeneration])
                return;
        }
        // The lineRange now refers to the first line after the unparsed range we just finished parsing. Try to merge the scope tree at the start, if it fails, we'll have to parse the line manually
        BOOL mergeSuccessful = [_rootScope attemptMergeAtOffset:lineRange.location];
        
        // If we need to reparse the line, we add it to the unparsed ranges
        OSSpinLockLock(&_pendingChangesLock);
        if (!mergeSuccessful)
            [_unparsedRanges addIndex:lineRange.location];
        // Get the next unparsed range
        nextRange = [_unparsedRanges firstRange];
        OSSpinLockUnlock(&_pendingChangesLock);
        
        // If we're reparsing the line, we can reuse the same scope stack, if not, we need to reset it to nil so the next cycle gets a new one
        if (mergeSuccessful)
            scopeStack = nil;
    }
    
#if DEBUG
    [_rootScope performSelector:@selector(_checkConsistency)];
#endif
    
    _scopesGeneration = startingGeneration;
}

- (BOOL)_generateScopesWithLine:(NSString *)line range:(NSRange)lineRange scopeStack:(NSMutableArray *)scopeStack generation:(CodeFileGeneration)generation
{
    line = [line stringByCachingCString];
    NSUInteger position = 0;
    NSUInteger previousTokenStart = lineRange.location;
    NSUInteger lineEnd = NSMaxRange(lineRange);
    
    // Check for a span scope with a missing content scope
    {
        TMScope *scope = [scopeStack lastObject];
        if (scope.type == TMScopeTypeSpan && ! scope.flags & TMScopeHasContentScope && scope.syntaxNode.contentName)
        {
            TMScope *contentScope = [scope newChildScopeWithIdentifier:scope.syntaxNode.contentName syntaxNode:scope.syntaxNode location:lineRange.location type:TMScopeTypeContent];
            ASSERT(scope.endRegexp);
            contentScope.endRegexp = scope.endRegexp;
            scope.flags |= TMScopeHasContentScope;
            [scopeStack addObject:contentScope];
        }
    }
    
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
            ASSERT(patternRegexp);
            OnigResult *result = [patternRegexp search:line start:position];
            if (!result || (firstResult && [firstResult bodyRange].location <= [result bodyRange].location))
                continue;
            firstResult = result;
            firstSyntaxNode = pattern;
        }
        
        // Find the end match
        OnigResult *endResult = [scope.endRegexp search:line start:position];
        
        ASSERT(!firstSyntaxNode || firstResult);
     
        // Handle the matches
        if (endResult && (!firstResult || [firstResult bodyRange].location >= [endResult bodyRange].location ))
        {
            // Handle end result first
            NSRange resultRange = [endResult bodyRange];
            resultRange.location += lineRange.location;
            // Handle content name nested scope
            if (scope.type == TMScopeTypeContent)
            {
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope generation:generation])
                    return NO;
                previousTokenStart = resultRange.location;
                scope.length = resultRange.location - scope.location;
                if (!scope.length)
                    [scope removeFromParent];
                [scopeStack removeLastObject];
                scope = [scopeStack lastObject];
            }
            if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:scope generation:generation])
                return NO;
            previousTokenStart = NSMaxRange(resultRange);
            // Handle end captures
            if (resultRange.length)
            {
                [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult type:TMScopeTypeEnd offset:lineRange.location parentScope:scope generation:generation];
                scope.flags |= TMScopeHasEndScope;
            }
            scope.length = NSMaxRange(resultRange) - scope.location;
            scope.flags |= TMScopeHasEnd;
            if (!scope.length)
                [scope removeFromParent];
            ASSERT([scopeStack count]);
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
            if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope generation:generation])
                return NO;
            previousTokenStart = resultRange.location;
            if (resultRange.length)
            {
                TMScope *matchScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.scopeName syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeMatch];
                matchScope.length = resultRange.length;
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:matchScope generation:generation])
                    return NO;
                previousTokenStart = NSMaxRange(resultRange);
                // Handle match pattern captures
                [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult type:TMScopeTypeMatch offset:lineRange.location parentScope:matchScope generation:generation];
            }
            // We need to make sure position increases, or it would loop forever with a 0 width match
            position = NSMaxRange([firstResult bodyRange]);
            if (!resultRange.length)
                ++position;
        }
        else if (firstSyntaxNode.begin)
        {
            // Handle a new span pattern
            NSRange resultRange = [firstResult bodyRange];
            resultRange.location += lineRange.location;
            if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, resultRange.location - previousTokenStart) withScope:scope generation:generation])
                return NO;
            previousTokenStart = resultRange.location;
            TMScope *spanScope = [scope newChildScopeWithIdentifier:firstSyntaxNode.scopeName syntaxNode:firstSyntaxNode location:resultRange.location type:TMScopeTypeSpan];
            spanScope.flags |= TMScopeHasBegin;
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
            ASSERT(spanScope.endRegexp);
            if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, NSMaxRange(resultRange) - previousTokenStart) withScope:spanScope generation:generation])
                return NO;
            previousTokenStart = NSMaxRange(resultRange);
            // Handle begin captures
            if (resultRange.length)
            {
                if (![self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult type:TMScopeTypeBegin offset:lineRange.location parentScope:spanScope generation:generation])
                    return NO;
                spanScope.flags |= TMScopeHasBeginScope;
            }
            [scopeStack addObject:spanScope];
            // Handle content name nested scope
            if (firstSyntaxNode.contentName)
            {
                TMScope *contentScope = [spanScope newChildScopeWithIdentifier:firstSyntaxNode.contentName syntaxNode:firstSyntaxNode location:NSMaxRange(resultRange) type:TMScopeTypeContent];
                contentScope.endRegexp = spanScope.endRegexp;
                spanScope.flags |= TMScopeHasContentScope;
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
    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, lineEnd - previousTokenStart) withScope:[scopeStack lastObject] generation:generation])
        return NO;
    return YES;
}

- (BOOL)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result type:(TMScopeType)type offset:(NSUInteger)offset parentScope:(TMScope *)scope generation:(CodeFileGeneration)generation
{
    ASSERT(!OSSpinLockTry(&_scopesLock));
    ASSERT([NSOperationQueue currentQueue] == _internalQueue);
    ASSERT(type == TMScopeTypeMatch || type == TMScopeTypeBegin || type == TMScopeTypeEnd);
    ASSERT(scope && result && [result bodyRange].length);
    if (!dictionary || !result)
        return YES;
    TMScope *capturesScope = scope;
    if (type != TMScopeTypeMatch)
    {
        capturesScope = [scope newChildScopeWithIdentifier:[(NSDictionary *)[dictionary objectForKey:@"0"] objectForKey:_captureName] syntaxNode:nil location:[result bodyRange].location + offset type:type];
        capturesScope.length = [result bodyRange].length;
        if (![self _parsedTokenInRange:NSMakeRange(capturesScope.location, capturesScope.length) withScope:capturesScope generation:generation])
            return NO;
    }
    NSMutableArray *capturesScopesStack = [NSMutableArray arrayWithObject:capturesScope];
    NSUInteger numMatchRanges = [result count];
    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
    {
        NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
        currentMatchRange.location += offset;
        if (!currentMatchRange.length)
            continue;
        NSString *currentCaptureName = [[dictionary objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_captureName];
        if (!currentCaptureName)
            continue;
        while (currentMatchRange.location < capturesScope.location || NSMaxRange(currentMatchRange) > capturesScope.location + capturesScope.length)
        {
            ASSERT([capturesScopesStack count]);
            [capturesScopesStack removeLastObject];
            capturesScope = [capturesScopesStack lastObject];
        }
        TMScope *currentCaptureScope = [capturesScope newChildScopeWithIdentifier:currentCaptureName syntaxNode:nil location:currentMatchRange.location type:TMScopeTypeCapture];
        currentCaptureScope.length = currentMatchRange.length;
        if (![self _parsedTokenInRange:NSMakeRange(currentCaptureScope.location, currentCaptureScope.length) withScope:currentCaptureScope generation:generation])
            return NO;
        [capturesScopesStack addObject:currentCaptureScope];
        capturesScope = currentCaptureScope;
    }
    return YES;
}

- (BOOL)_parsedTokenInRange:(NSRange)tokenRange withScope:(TMScope *)scope generation:(CodeFileGeneration)generation
{
    NSDictionary *attributes = [_projectFile.codeFile.theme attributesForScope:scope];
    if (![attributes count])
        return YES;
    return [_projectFile.codeFile setAttributes:attributes range:tokenRange expectedGeneration:generation];
}

- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern
{
    ASSERT([NSOperationQueue currentQueue] == _internalQueue);
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
            ASSERT(containerPattern.include || containerPattern.patterns);
            ASSERT(!containerPattern.include || !containerPattern.patterns);
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
                    ASSERT(firstCharacter != '$' || [containerPattern.include isEqualToString:@"$base"] || [containerPattern.include isEqualToString:@"$self"]);
                    TMSyntaxNode *includedSyntax = nil;
                    if ([containerPattern.include isEqualToString:@"$base"])
                        includedSyntax = _projectFile.syntax;
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
                ASSERT(patternsCount);
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

@implementation Change

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
