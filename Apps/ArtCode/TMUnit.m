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
#import "RangeSet.h"
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
    NSRange range;
    NSString *replacementString;
}
@end

@implementation Change
@end

@interface TMUnit () <CodeFilePresenter>
{
    TMSyntaxNode *_syntax;
    NSMutableString *_contents;
    CodeFileGeneration _scopesGeneration;
    TMScope *_rootScope;
    NSOperationQueue *_internalQueue;
    OSSpinLock _pendingChangesLock;
    NSMutableArray *_pendingChanges;
    OSSpinLock _needsGenerateScopesLock;
    BOOL _needsGenerateScopes;
    MutableRangeSet *_unparsedRanges;
    MutableRangeSet *_blankRanges;
    NSMutableDictionary *_patternsIncludedByPattern;
    NSMutableDictionary *_extensions;
}
- (NSMutableArray *)_scopeStackAtOffset:(NSUInteger)offset;
- (void)_setNeedsGenerateScopes;
- (void)_generateScopes;
- (BOOL)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result offset:(NSUInteger)offset inScope:(TMScope *)scope generation:(CodeFileGeneration)generation;
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
    _contents = [[NSMutableString alloc] init];
    if (rootScopeIdentifier)
        _syntax = [TMSyntaxNode syntaxWithScopeIdentifier:rootScopeIdentifier];
    else
        _syntax = [TMSyntaxNode syntaxForCodeFile:codeFile];
    _rootScope = [[TMScope alloc] init];
    _rootScope.identifier = _syntax.scopeName;
    _rootScope.syntaxNode = _syntax;
    _internalQueue = [[NSOperationQueue alloc] init];
    _internalQueue.maxConcurrentOperationCount = 1;
    _pendingChangesLock = OS_SPINLOCK_INIT;
    Change *firstChange = [[Change alloc] init];
    firstChange->generation = [_codeFile currentGeneration];
    firstChange->range = NSMakeRange(0, 0);
    firstChange->replacementString = [_codeFile string];
    _pendingChanges = [NSMutableArray arrayWithObject:firstChange];
    _needsGenerateScopesLock = OS_SPINLOCK_INIT;
    [self _setNeedsGenerateScopes];
    _unparsedRanges = [[MutableRangeSet alloc] init];
    _blankRanges = [[MutableRangeSet alloc] init];
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

- (void)dealloc
{
    [_codeFile removePresenter:self];
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
        completionHandler([_rootScope copy]);
    else
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self rootScopeWithCompletionHandler:completionHandler];
        } afterDelay:0.3];
}

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void (^)(TMScope *))completionHandler
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    if ([_codeFile currentGeneration] == _scopesGeneration)
        completionHandler([[[self _scopeStackAtOffset:offset] lastObject] copy]);
    else
        [[NSOperationQueue currentQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
            [self scopeAtOffset:offset withCompletionHandler:completionHandler];
        } afterDelay:0.3];
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
    change->range = range;
    change->replacementString = [string string];
    OSSpinLockLock(&_pendingChangesLock);
    [_pendingChanges addObject:change];
    OSSpinLockUnlock(&_pendingChangesLock);
    [self _setNeedsGenerateScopes];    
}

#pragma mark - Private Methods

- (NSMutableArray *)_scopeStackAtOffset:(NSUInteger)offset
{
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:_rootScope];
    BOOL recurse = NO;
    while (recurse)
        for (TMScope *childScope in [[scopeStack lastObject] children])
            if (childScope.location <= offset && childScope.location + childScope.length > offset)
            {
                recurse = YES;
                break;
            }
    return scopeStack;
}

- (void)_setNeedsGenerateScopes
{
    ECASSERT([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]);
    OSSpinLockLock(&_needsGenerateScopesLock);
    if (_needsGenerateScopes)
    {
        OSSpinLockUnlock(&_needsGenerateScopesLock);
        return;
    }
    _needsGenerateScopes = YES;
    _isLoading = YES;
    __weak TMUnit *weakSelf = self;
    [_internalQueue addOperationWithBlock:^{
        [weakSelf _generateScopes];
    }];
    OSSpinLockUnlock(&_needsGenerateScopesLock);
}

- (void)_generateScopes
{
    ECASSERT([NSOperationQueue currentQueue] == _internalQueue);
    TMScope *scope = _rootScope;
    
    // Setup the scope stack
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:scope];
    while (scope.parent)
    {
        scope = scope.parent;
        [scopeStack insertObject:scope atIndex:0];
    }
    
    // Save the current generation
    CodeFileGeneration currentGeneration;
    NSRange range = NSMakeRange(0, [self.codeFile lengthWithGeneration:&currentGeneration]);
    
    // Parse the range
    NSUInteger previousTokenStart = 0;
    NSUInteger previousTokenEnd = 0;
    NSRange lineRange = NSMakeRange(range.location, 0);
    for (;;)
    {
        if (lineRange.location >= NSMaxRange(range))
            break;
        // Setup the line
        if (![self.codeFile lineRange:&lineRange forRange:lineRange expectedGeneration:currentGeneration])
            return;
        if (lineRange.location < range.location)
            lineRange = NSMakeRange(range.location, NSMaxRange(lineRange) - range.location);
        NSString *uncachedString;
        if (![self.codeFile string:&uncachedString inRange:lineRange expectedGeneration:currentGeneration])
            return;
        CStringCachingString *line = [CStringCachingString stringWithString:uncachedString];
        NSUInteger position = 0;
//        NSLog(@"parsing %@: %@", NSStringFromRange(lineRange), line);
        for (;;)
        {
            scope = [scopeStack lastObject];
            TMSyntaxNode *syntaxNode = scope.syntaxNode;
            
//            NSLog(@"current syntaxNode: %@", [syntaxNode scopeName]);
            
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
                    if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:currentGeneration])
                        return;
                    previousTokenStart = previousTokenEnd;
                    scope.length = resultRange.location + lineRange.location - scope.location;
                    scope.completelyParsed = YES;
                    [scopeStack removeLastObject];
                    scope = [scopeStack lastObject];
                }
                previousTokenEnd = NSMaxRange(resultRange) + lineRange.location;
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:currentGeneration])
                    return;
                previousTokenStart = previousTokenEnd;
                // Handle end captures
                [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult offset:lineRange.location inScope:scope generation:currentGeneration];
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
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:currentGeneration])
                    return;
                previousTokenStart = previousTokenEnd;
                TMScope *matchScope = [scope newChildScope];
                matchScope.identifier = firstSyntaxNode.scopeName;
                matchScope.syntaxNode = firstSyntaxNode;
                matchScope.location = resultRange.location + lineRange.location;
                matchScope.length = resultRange.length;
                matchScope.completelyParsed = YES;
                previousTokenEnd = NSMaxRange(resultRange) + lineRange.location;
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:matchScope generation:currentGeneration])
                    return;
                previousTokenStart = previousTokenEnd;
                // Handle match pattern captures
                [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult offset:lineRange.location inScope:matchScope generation:currentGeneration];
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
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:currentGeneration])
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
                if (![self _parsedTokenInRange:NSMakeRange(previousTokenStart, previousTokenEnd - previousTokenStart) withScope:scope generation:currentGeneration])
                    return;
                previousTokenStart = previousTokenEnd;
                if (![self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult offset:lineRange.location inScope:spanScope generation:currentGeneration])
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
        // proceed to next line
        lineRange = NSMakeRange(NSMaxRange(lineRange), 0);
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
        NSDictionary *attributes = [self.codeFile.theme attributesForScope:capturesScope];
        if ([attributes count])
            [self.codeFile addAttributes:attributes range:NSMakeRange(capturesScope.location, capturesScope.length) expectedGeneration:generation];
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
