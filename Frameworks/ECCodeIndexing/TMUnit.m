//
//  TMUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexing+Internal.h"
#import <ECFoundation/ECFileBuffer.h>
#import "TMScope.h"
#import "TMBundle.h"
#import "TMSyntax.h"
#import "TMPattern.h"
#import "OnigRegexp.h"

static NSMutableDictionary *_extensionClasses;

static NSString * const _patternCaptureName = @"name";

@interface TMUnit ()
{
    NSOperationQueue *_consumerOperationQueue;
    TMIndex *_index;
    ECFileBuffer *_fileBuffer;
    NSString *_rootScopeIdentifier;
    NSMutableDictionary *_extensions;
    TMSyntax *__syntax;
    NSMutableDictionary *_firstMatches;
    NSString *_contents;
    TMScope *__scope;
}
- (TMSyntax *)_syntax;
- (TMScope *)_scope;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMPattern *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMPattern *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures;
- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
@end

@implementation TMUnit

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

- (id)initWithIndex:(TMIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
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
        __syntax = [TMSyntax syntaxWithScope:rootScopeIdentifier];
    }
    else
    {
        __syntax = [TMSyntax syntaxForFileBuffer:fileBuffer];
        _rootScopeIdentifier = __syntax.scopeIdentifier;
    }
    ECASSERT(__syntax && _rootScopeIdentifier);
    [__syntax beginContentAccess];
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
    [__syntax endContentAccess];
    [_fileBuffer removeConsumer:self];
}

- (TMIndex *)index
{
    return _index;
}

- (ECFileBuffer *)fileBuffer
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

- (void)visitScopesWithBlock:(TMUnitVisitResult (^)(NSString *, NSRange, NSString *, NSString *, NSArray *))block
{
    [self visitScopesInRange:NSMakeRange(0, [self _scope].length) options:TMUnitVisitOptionsAbsoluteRange withBlock:block];
}

- (void)visitScopesInRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult (^)(NSString *, NSRange, NSString *, NSString *, NSArray *))block
{
    static NSRange (^intersectionOfRangeRelativeToRange)(NSRange range, NSRange inRange) = ^(NSRange range, NSRange inRange){
        NSRange intersectionRange = NSIntersectionRange(range, inRange);
        intersectionRange.location -= inRange.location;
        return intersectionRange;
    };
    TMScope *currentScope = [self _scope];
    NSMutableArray *scopeIdentifiersStack = [NSMutableArray arrayWithObject:currentScope];
    while (currentScope)
    {
        NSLog(@"%@: {%d, %d}", currentScope.identifier, currentScope.offset, currentScope.length);
        NSRange currentScopeRange = NSMakeRange(currentScope.baseOffset, currentScope.length);
        if (options & TMUnitVisitOptionsRelativeRange)
            currentScopeRange = intersectionOfRangeRelativeToRange(currentScopeRange, range);
        TMUnitVisitResult result = block(currentScope.identifier, currentScopeRange, currentScope.spelling, currentScope.parent.identifier, [scopeIdentifiersStack copy]);
        if (result == TMUnitVisitResultBreak)
            break;
        if (result == TMUnitVisitResultRecurse && currentScope.children)
        {
            currentScope = [currentScope.children objectAtIndex:0];
            continue;
        }
        while (currentScope)
        {
            NSUInteger currentScopeIndex = [currentScope.parent.children indexOfObject:currentScope];
            if (currentScopeIndex + 1 < [currentScope.parent.children count])
            {
                currentScope = [currentScope.parent.children objectAtIndex:currentScopeIndex + 1];
                break;
            }
            currentScope = currentScope.parent;
        }
    }
}

- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

#pragma mark - ECFileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    return _consumerOperationQueue;
}

#pragma mark - Private Methods

- (TMSyntax *)_syntax
{
    return __syntax;
}

- (TMScope *)_scope
{
    if (!__scope)
    {
        _firstMatches = [NSMutableDictionary dictionary];
        _contents = [self.fileBuffer string];
        __scope = [[TMScope alloc] initWithIdentifier:[self rootScopeIdentifier] string:_contents];
        [self _addChildScopesToScope:__scope inRange:NSMakeRange(0, [_contents length]) relativeToOffset:0 withPatterns:[[self _syntax] patterns] stopOnRegexp:nil withName:nil captures:nil];
        _firstMatches = nil;
    }
    return __scope;
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMPattern *)pattern
{
    return [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withRegexp:[pattern match] name:[pattern name] captures:[pattern captures]];
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMPattern *)pattern
{
    NSString *patternName = [pattern name];
    TMScope *spanScope = nil;
    if (patternName)
    {
        ECASSERT([[pattern name] isKindOfClass:[NSString class]]);
        spanScope = [scope newChildScopeWithIdentifier:patternName];
    }
    OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:[pattern begin]];
    if (!beginResult)
        return NSMaxRange(range);
    if (spanScope)
        offset = [beginResult bodyRange].location;
    NSRange childPatternsRange = NSMakeRange(NSMaxRange([beginResult bodyRange]), range.length - [beginResult bodyRange].length);
    if ([pattern beginCaptures])
        offset = [self _addChildScopesToScope:spanScope ? spanScope : scope inRange:range relativeToOffset:offset withRegexp:[pattern begin] name:[[[pattern beginCaptures] objectForKey:@"0"] objectForKey:_patternCaptureName] captures:[pattern beginCaptures]];
    if (spanScope)
        offset = NSMaxRange([beginResult bodyRange]);
    offset = [self _addChildScopesToScope:spanScope ? spanScope : scope inRange:childPatternsRange relativeToOffset:offset withPatterns:[pattern patterns] stopOnRegexp:[pattern end] withName:[[[pattern endCaptures] objectForKey:@"0"] objectForKey:_patternCaptureName] captures:[pattern endCaptures]];
    ECASSERT(offset <= NSMaxRange(range));
    if (spanScope)
    {
        [spanScope setOffset:[beginResult bodyRange].location];
        [spanScope setLength:offset - [beginResult bodyRange].location];
    }
    return offset;
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures
{
    BOOL matchFound;
    do
    {
        matchFound = NO;
        NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in patterns)
        {
            ECASSERT([childPattern match] || [childPattern begin]);
            OnigRegexp *patternRegexp = [childPattern match] ? [childPattern match] : [childPattern begin];
            OnigResult *result = [self _firstMatchInRange:range forRegexp:patternRegexp];
            if (!result)
                continue;
            NSRange resultRange = [result bodyRange];
            if (resultRange.location > firstMatchRange.location || (resultRange.location == firstMatchRange.location && resultRange.length < firstMatchRange.length))
                continue;
            firstMatchRange = resultRange;
            firstMatchPattern = childPattern;
            matchFound = YES;
        }
        OnigResult *stopResult = regexp ? [self _firstMatchInRange:range forRegexp:regexp] : nil;
        if (stopResult && [stopResult bodyRange].location < firstMatchRange.location)
            return [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withRegexp:regexp name:name captures:captures];
        if (!firstMatchPattern)
            break;
        if ([firstMatchPattern match])
            offset = [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withMatchPattern:firstMatchPattern];
        else
            offset = [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withSpanPattern:firstMatchPattern];
        ECASSERT(offset <= NSMaxRange(range));
        range.length -= offset - range.location;
        range.location = offset;
    }
    while (matchFound);
    return NSMaxRange(range);
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures
{
    TMScope *capturesScope = nil;
    if (name)
    {
        ECASSERT([name isKindOfClass:[NSString class]]);
        capturesScope = [scope newChildScopeWithIdentifier:name];
    }
    OnigResult *result = [self _firstMatchInRange:range forRegexp:regexp];
    if (!result)
        return NSMaxRange(range);
    if (capturesScope)
    {
        [capturesScope setOffset:[result bodyRange].location - offset];
        [capturesScope setLength:[result bodyRange].length];
    }
    if (captures)
    {
        NSUInteger numMatchRanges = [result count];
        for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
        {
            NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
            if (!currentMatchRange.length)
                continue;
            NSString *currentCaptureName = [[captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
            if (!currentCaptureName)
                continue;
            ECASSERT([currentCaptureName isKindOfClass:[NSString class]]);
            TMScope *currentCaptureScope = [capturesScope ? capturesScope : scope newChildScopeWithIdentifier:currentCaptureName];
            [currentCaptureScope setOffset:currentMatchRange.location - offset];
            [currentCaptureScope setLength:currentMatchRange.length];
            offset = NSMaxRange(currentMatchRange);
        }
    }
    return NSMaxRange([result bodyRange]);
}

- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
{
    OnigResult *result = [_firstMatches objectForKey:regexp];
    if (result && (id)result != [NSNull null] && [result rangeAt:0].location >= range.location && NSMaxRange([result rangeAt:0]) <= NSMaxRange(range))
        return result;
    if ((id)result == [NSNull null])
        return nil;
    result = [regexp search:_contents range:range];
    if (result)
        [_firstMatches setObject:result forKey:regexp];
    else
        [_firstMatches setObject:[NSNull null] forKey:regexp];
    return result;
}

@end
