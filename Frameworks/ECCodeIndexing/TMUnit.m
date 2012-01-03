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
    TMScope *__scope;
}
- (TMSyntax *)_syntax;
- (TMScope *)_scope;
- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withMatchPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange;
- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withSpanPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange;
- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange;
- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange;
- (void)_addChildScopesToScope:(TMScope *)scope forCaptures:(NSDictionary *)captures inResult:(OnigResult *)result;
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
        __scope = [[TMScope alloc] initWithIdentifier:[self rootScopeIdentifier] string:[self.fileBuffer string]];
        [self _addChildScopesToScope:__scope inRange:NSMakeRange(0, NSUIntegerMax) withPatterns:[[self _syntax] patterns] stopOnRegexp:nil withName:nil captures:nil remainingRange:NULL];
    }
    return __scope;
}

- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withMatchPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange
{
    return [self _addChildScopesToScope:scope inRange:range withRegexp:[pattern match] name:[pattern name] captures:[pattern captures] remainingRange:remainingRange];
}

- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withSpanPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange
{
    NSString *patternName = [pattern name];
    TMScope *spanScope = nil;
    if (patternName)
    {
        ECASSERT([[pattern name] isKindOfClass:[NSString class]]);
        spanScope = [scope newChildScopeWithIdentifier:patternName];
    }
    NSRange localRemainingRange;
    if (remainingRange)
        *remainingRange = range;
    if ([pattern beginCaptures])
        [self _addChildScopesToScope:spanScope ? spanScope : scope inRange:range withRegexp:[pattern begin] name:[[[pattern beginCaptures] objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName] captures:[pattern beginCaptures] remainingRange:&localRemainingRange];
    else
    {
        OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:[pattern begin]];
        if (!beginResult)
            return;
        localRemainingRange.location = NSMaxRange([beginResult bodyRange]);
        localRemainingRange.length = NSMaxRange(range) - localRemainingRange.location;
    }
    [self _addChildScopesToScope:spanScope ? spanScope : scope inRange:localRemainingRange withPatterns:[pattern patterns] stopOnRegexp:[pattern end] withName:[[[pattern endCaptures] objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName] captures:[pattern endCaptures] remainingRange:&localRemainingRange];
    if (remainingRange)
        *remainingRange = localRemainingRange;
    if (spanScope)
    {
        [spanScope setBaseOffset:range.location];
        [spanScope setLength:localRemainingRange.location - range.location];
    }
}

- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange
{
    NSRange currentRange = range;
    while (currentRange.length)
    {
        NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in patterns)
        {
            ECASSERT([childPattern match] || [childPattern begin]);
            OnigRegexp *patternRegexp = [childPattern match] ? [childPattern match] : [childPattern begin];
            OnigResult *result = [self _firstMatchInRange:currentRange forRegexp:patternRegexp];
            if (!result)
                continue;
            NSRange resultRange = [result bodyRange];
            if (resultRange.location > firstMatchRange.location || (resultRange.location == firstMatchRange.location && resultRange.length < firstMatchRange.length))
                continue;
            firstMatchRange = resultRange;
            firstMatchPattern = childPattern;
        }
        OnigResult *stopResult = regexp ? [self _firstMatchInRange:range forRegexp:regexp] : nil;
        if (stopResult && [stopResult bodyRange].location < firstMatchRange.location)
        {
            [self _addChildScopesToScope:scope inRange:currentRange withRegexp:regexp name:name captures:captures remainingRange:remainingRange];
            return;
        }
        if (!firstMatchPattern)
            break;
        if ([firstMatchPattern match])
            [self _addChildScopesToScope:scope inRange:currentRange withMatchPattern:firstMatchPattern remainingRange:&currentRange];
        else
            [self _addChildScopesToScope:scope inRange:currentRange withSpanPattern:firstMatchPattern remainingRange:&currentRange];
    }
    if (remainingRange)
        *remainingRange = currentRange;
}

- (void)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange
{
    TMScope *capturesScope = nil;
    if (name)
    {
        ECASSERT([name isKindOfClass:[NSString class]]);
        capturesScope = [scope newChildScopeWithIdentifier:name];
    }
    OnigResult *result = [self _firstMatchInRange:range forRegexp:regexp];
    if (!result)
        return;
    if (captures)
        [self _addChildScopesToScope:capturesScope ? capturesScope : scope forCaptures:captures inResult:result];
    if (remainingRange)
    {
        remainingRange->location = NSMaxRange([result bodyRange]);
        remainingRange->length = NSMaxRange(range) - remainingRange->location;
    }
    if (capturesScope)
    {
        [capturesScope setBaseOffset:[result bodyRange].location];
        [capturesScope setLength:[result bodyRange].length];
    }
}

- (void)_addChildScopesToScope:(TMScope *)scope forCaptures:(NSDictionary *)captures inResult:(OnigResult *)result
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
        TMScope *currentCaptureScope = [scope newChildScopeWithIdentifier:currentCaptureName];
        [currentCaptureScope setBaseOffset:currentMatchRange.location];
        [currentCaptureScope setLength:currentMatchRange.length];
    }
}

- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
{
    OnigResult *result = [_firstMatches objectForKey:regexp];
    if (result && (id)result != [NSNull null] && [result rangeAt:0].location >= range.location && NSMaxRange([result rangeAt:0]) <= NSMaxRange(range))
        return result;
    if ((id)result == [NSNull null])
        return nil;
    result = [regexp search:[[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])] range:range];
    if (result)
        [_firstMatches setObject:result forKey:regexp];
    else
        [_firstMatches setObject:[NSNull null] forKey:regexp];
    return result;
}

@end
