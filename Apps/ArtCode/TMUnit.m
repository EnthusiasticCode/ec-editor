//
//  TMUnit.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"
#import "TMIndex+Internal.h"
#import "FileBuffer.h"
#import "TMScope+Internal.h"
#import "TMBundle.h"
#import "TMSyntaxNode.h"
#import "OnigRegexp.h"
#import "CStringCachingString.h"

static NSMutableDictionary *_extensionClasses;

static NSString * const _captureName = @"name";
static OnigRegexp *_numberedCapturesRegexp;
static OnigRegexp *_namedCapturesRegexp;

@interface TMUnit ()
{
    NSOperationQueue *_consumerOperationQueue;
    TMIndex *_index;
    FileBuffer *_fileBuffer;
    NSString *_rootScopeIdentifier;
    NSMutableDictionary *_extensions;
    TMSyntaxNode *__syntax;
    NSString *_contents;
    TMScope *__scope;
    NSMutableDictionary *_patternsIncludedByPattern;
    NSUInteger _generation;
}
- (TMSyntaxNode *)_syntax;
- (TMScope *)_scope;
- (void)_generateScopesWithScope:(TMScope *)scope inRange:(NSRange)range;
- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result offset:(NSUInteger)offset inScope:(TMScope *)scope;
- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern;
@end

@implementation TMUnit

+ (void)initialize
{
    if (self != [TMUnit class])
        return;
    _numberedCapturesRegexp = [OnigRegexp compile:@"\\([1-9])"];
    _namedCapturesRegexp = [OnigRegexp compile:@"\\k<(.*?)>"];
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

- (id)initWithIndex:(TMIndex *)index fileBuffer:(FileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    ECASSERT(index && fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _consumerOperationQueue = [NSOperationQueue currentQueue];
    _index = index;
    _fileBuffer = fileBuffer;
    [_fileBuffer addConsumer:self];
    if (rootScopeIdentifier)
    {
        _rootScopeIdentifier = rootScopeIdentifier;
        __syntax = [TMSyntaxNode syntaxWithScopeIdentifier:rootScopeIdentifier];
    }
    else
    {
        __syntax = [TMSyntaxNode syntaxForFileBuffer:fileBuffer];
        _rootScopeIdentifier = __syntax.scopeName;
    }
    ECASSERT(__syntax && _rootScopeIdentifier);
    _patternsIncludedByPattern = [NSMutableDictionary dictionary];
    _generation = 1;
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
    [_fileBuffer removeConsumer:self];
}

- (TMIndex *)index
{
    return _index;
}

- (FileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (NSString *)rootScopeIdentifier
{
    return _rootScopeIdentifier;
}

- (id)extensionForKey:(id)key
{
    return [_extensions objectForKey:key];
}

- (void)visitScopesWithBlock:(TMUnitVisitResult (^)(TMScope *, NSRange))block
{
    [self visitScopesInRange:NSMakeRange(0, [self _scope].length) withBlock:block];
}

- (void)visitScopesInRange:(NSRange)range withBlock:(TMUnitVisitResult (^)(TMScope *, NSRange))block
{
    static NSRange (^intersectionOfRangeRelativeToRange)(NSRange range, NSRange inRange) = ^(NSRange range, NSRange inRange){
        NSRange intersectionRange = NSIntersectionRange(range, inRange);
        intersectionRange.location -= inRange.location;
        return intersectionRange;
    };
    // Visit the root scope
    TMScope *scope = [self _scope];
    NSRange scopeRange = NSMakeRange(scope.location, scope.length);
    ECASSERT(range.location <= NSMaxRange(scopeRange) && NSMaxRange(range) >= scopeRange.location);
    scopeRange = intersectionOfRangeRelativeToRange(scopeRange, range);
    TMUnitVisitResult result = block(scope, scopeRange);
    if (result != TMUnitVisitResultRecurse)
        return;
    // Setup the scope enumerator stack
    NSMutableArray *enumeratorStack = [[NSMutableArray alloc] init];
    [enumeratorStack addObject:[scope.children objectEnumerator]];
    while ([enumeratorStack count])
    {
        while ((scope = [[enumeratorStack lastObject] nextObject]))
        {
            NSRange scopeRange = NSMakeRange(scope.location, scope.length);
            if (scopeRange.location > NSMaxRange(range))
                return;
            if (NSMaxRange(scopeRange) < range.location)
                continue;
            ECASSERT(range.location <= NSMaxRange(scopeRange) && NSMaxRange(range) >= scopeRange.location);
            scopeRange = intersectionOfRangeRelativeToRange(scopeRange, range);
            TMUnitVisitResult result = block(scope, scopeRange);
            if (result == TMUnitVisitResultBreak)
                return;
            if (result == TMUnitVisitResultContinue)
                continue;
            if (result == TMUnitVisitResultBackOut)
                break;
            if ([scope children])
                [enumeratorStack addObject:[[scope children] objectEnumerator]];
        }
        [enumeratorStack removeLastObject];
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

#pragma mark - FileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    return _consumerOperationQueue;
}

#pragma mark - Private Methods

- (TMSyntaxNode *)_syntax
{
    return __syntax;
}

- (TMScope *)_scope
{
    if (!__scope)
    {
        __scope = [[TMScope alloc] init];
        __scope.identifier = [self rootScopeIdentifier];
        __scope.syntaxNode = [self _syntax];
        [self _generateScopesWithScope:__scope inRange:NSMakeRange(0, [self.fileBuffer length])];
    }
    return __scope;
}

- (void)_generateScopesWithScope:(TMScope *)scope inRange:(NSRange)range
{
    ECASSERT(scope);
    
    // Setup the scope stack
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:scope];
    while (scope.parent)
    {
        scope = scope.parent;
        [scopeStack insertObject:scope atIndex:0];
    }
    
    // Parse the range
    NSRange lineRange = NSMakeRange(range.location, 0);
    for (;;)
    {
        if (lineRange.location >= NSMaxRange(range))
            break;
        // Setup the line
        lineRange = [self.fileBuffer lineRangeForRange:lineRange];
        if (lineRange.location < range.location)
            lineRange = NSMakeRange(range.location, NSMaxRange(lineRange) - range.location);
        CStringCachingString *line = [CStringCachingString stringWithString:[self.fileBuffer stringInRange:lineRange]];
        NSUInteger position = 0;
        
//        NSLog(@"parsing %@: %@", NSStringFromRange(lineRange), line);
        for (;;)
        {
            scope = [scopeStack lastObject];
            TMSyntaxNode *syntaxNode = scope.syntaxNode;
            
//            NSLog(@"current syntaxNode: %@", [syntaxNode scopeName]);
            
            // Create the end regexp
            OnigRegexp *endRegexp = nil;
            if (syntaxNode.end)
            {
                NSMutableString *end = [NSMutableString stringWithString:syntaxNode.end];
                NSRange beginLineRange = [self.fileBuffer lineRangeForRange:NSMakeRange(scope.location, 0)];
                NSString *beginLine = [self.fileBuffer stringInRange:beginLineRange];
                OnigResult *beginResult = [syntaxNode.begin match:beginLine start:scope.location - beginLineRange.location];
                [_numberedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
                    int captureNumber = [[result stringAt:1] intValue];
                    if (captureNumber >= 0 && [beginResult count] > captureNumber)
                        return [beginResult stringAt:captureNumber];
                    else
                        return nil;
                }];
                [_namedCapturesRegexp gsub:end block:^NSString *(OnigResult *result, BOOL *stop) {
                    NSString *captureName = [result stringAt:1];
                    int captureNumber = [beginResult indexForName:captureName];
                    if (captureNumber >= 0 && [beginResult count] > captureNumber)
                        return [beginResult stringAt:captureNumber];
                    else
                        return nil;
                }];
                endRegexp = [OnigRegexp compile:end options:OnigOptionCaptureGroup];
            }
            
            // Find the first matching pattern
            TMSyntaxNode *firstSyntaxNode = nil;
            OnigResult *firstResult = nil;
            if (syntaxNode.patterns)
            {
                NSArray *patterns = [self _patternsIncludedByPattern:syntaxNode];
                for (TMSyntaxNode *pattern in patterns)
                {
                    ECASSERT(pattern.match || pattern.begin);
                    OnigRegexp *patternRegexp = pattern.match ? pattern.match : pattern.begin;
                    OnigResult *result = [patternRegexp search:line start:position];
                    if (!result || (firstResult && [firstResult bodyRange].location <= [result bodyRange].location))
                        continue;
                    firstResult = result;
                    firstSyntaxNode = pattern;
                }
            }
            
            // Find the end match
            OnigResult *endResult = nil;
            if (endRegexp)
                endResult = [endRegexp search:line start:position];
            
            ECASSERT(!firstSyntaxNode || firstResult);
            
            // Handle the matches
            if (endResult && (!firstResult || [firstResult bodyRange].location >= [endResult bodyRange].location ))
                // Handle end result first
            {
                if (syntaxNode.contentName)
                {
                    scope.length = [endResult bodyRange].location + lineRange.location - scope.location;
                    scope.completelyParsed = YES;
                    [scopeStack removeLastObject];
                    scope = [scopeStack lastObject];
                }
                [self _generateScopesWithCaptures:syntaxNode.endCaptures result:endResult offset:lineRange.location inScope:scope];
                scope.length = NSMaxRange([endResult bodyRange]) + lineRange.location - scope.location;
                scope.completelyParsed = YES;
                if ([scopeStack count] == 1)
                    return;
                [scopeStack removeLastObject];
                // We don't need to make sure position advances since we changed the stack
                // This could bite us if there's a begin and end regexp that match in the same position
                position = NSMaxRange([endResult bodyRange]);
            }
            else if (firstSyntaxNode.match)
                // Handle pattern result
            {
                TMScope *matchScope = [scope newChildScope];
                matchScope.identifier = firstSyntaxNode.scopeName;
                matchScope.syntaxNode = firstSyntaxNode;
                matchScope.location = [firstResult bodyRange].location + lineRange.location;
                matchScope.length = [firstResult bodyRange].length;
                matchScope.completelyParsed = YES;
                [self _generateScopesWithCaptures:firstSyntaxNode.captures result:firstResult offset:lineRange.location inScope:matchScope];
                // We need to make sure position increases, or it would loop forever with a 0 width match
                NSUInteger newPosition = NSMaxRange([firstResult bodyRange]);
                if (position == newPosition)
                    ++position;
                else
                    position = newPosition;
            }
            else if (firstSyntaxNode.begin)
            {
                TMScope *spanScope = [scope newChildScope];
                spanScope.identifier = firstSyntaxNode.scopeName;
                spanScope.syntaxNode = firstSyntaxNode;
                spanScope.location = [firstResult bodyRange].location + lineRange.location;
                [self _generateScopesWithCaptures:firstSyntaxNode.beginCaptures result:firstResult offset:lineRange.location inScope:spanScope];
                [scopeStack addObject:spanScope];
                if (firstSyntaxNode.contentName)
                {
                    TMScope *contentScope = [spanScope newChildScope];
                    contentScope.identifier = firstSyntaxNode.contentName;
                    contentScope.syntaxNode = firstSyntaxNode;
                    contentScope.location = NSMaxRange([firstResult bodyRange]) + lineRange.location;
                    [scopeStack addObject:contentScope];
                }
                // We don't need to make sure position advances since we changed the stack
                // This could bite us if there's a begin and end regexp that match in the same position
                position = NSMaxRange([firstResult bodyRange]);
            }
            else
                break;
            
            // We need to break if we hit the end of the line, failing to do so not only runs another cycle that doesn't find anything 99% of the time, but also can cause problems with matches that include the newline which have to be the last match for the line in the remaining 1%
            if (position >= lineRange.length)
                break;
        }
        lineRange = NSMakeRange(NSMaxRange(lineRange), 0);
    }
    
    // Close off all remaining scopes
    NSUInteger rangeEnd = NSMaxRange(range);
    for (TMScope *scope in scopeStack)
        scope.length = rangeEnd - scope.location;
}

- (void)_generateScopesWithCaptures:(NSDictionary *)dictionary result:(OnigResult *)result offset:(NSUInteger)offset inScope:(TMScope *)scope
{
    ECASSERT(scope);
    if (!dictionary || !result)
        return;
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
    }
}

- (NSArray *)_patternsIncludedByPattern:(TMSyntaxNode *)pattern
{
    NSMutableArray *includedPatterns = [_patternsIncludedByPattern objectForKey:pattern];
    if (includedPatterns)
        return includedPatterns;
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
        [containerPatternIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
            TMSyntaxNode *containerPattern = [includedPatterns objectAtIndex:idx];
            [includedPatterns removeObjectAtIndex:idx];
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
                    [includedPatterns insertObject:[patternSyntax.repository objectForKey:[containerPattern.include substringFromIndex:1]] atIndex:idx];
                }
                else
                {
                    ECASSERT(firstCharacter != '$' || [containerPattern.include isEqualToString:@"$base"] || [containerPattern.include isEqualToString:@"$self"]);
                    TMSyntaxNode *includedSyntax = nil;
                    if ([containerPattern.include isEqualToString:@"$base"])
                        includedSyntax = [self _syntax];
                    else if ([containerPattern.include isEqualToString:@"$self"])
                        includedSyntax = [containerPattern rootSyntax];
                    else
                        includedSyntax = [TMSyntaxNode syntaxWithScopeIdentifier:containerPattern.include];
                    for (TMSyntaxNode *pattern in includedSyntax.patterns)
                        [includedPatterns insertObject:pattern atIndex:idx];
                }
            }
            else
            {
                NSUInteger patternsCount = [containerPattern.patterns count];
                [includedPatterns insertObjects:containerPattern.patterns atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, patternsCount)]];
            }
            [dereferencedPatterns addObject:containerPattern];
        }];
    }
    while ([containerPatternIndexes count]);
    [_patternsIncludedByPattern setObject:includedPatterns forKey:pattern];
    return includedPatterns;
}

@end
