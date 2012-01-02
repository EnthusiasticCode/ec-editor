//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex+Internal.h"
#import <ECFoundation/ECFileBuffer.h>
#import "TMBundle.h"
#import "TMSyntax.h"
#import "TMPattern.h"
#import "OnigRegexp.h"

static NSMutableDictionary *_extensionClasses;

static NSString * const _patternCaptureName = @"name";
static NSString * const _tokenAttributeName = @"TMTokenAttributeName";

@interface ECCodeScope : NSObject

/// The string containing the scope
@property (nonatomic, strong) NSString *containingString;
/// The identifier of the scope's class
@property (nonatomic, strong) NSString *identifier;
/// The range of the scope within the containingString
@property (nonatomic) NSRange range;
/// The spelling of the scope as it appears in the containingString
@property (nonatomic, readonly) NSString *spelling;
/// The parent scope, if one exists
@property (nonatomic, weak) ECCodeScope *parent;
/// The children scopes, if any exist
@property (nonatomic, strong) NSArray *children;
/// Identifiers of the scope and all ancestor scopes
- (NSArray *)identifiersStack;

@end

@implementation ECCodeScope

@synthesize containingString = _containingString;
@synthesize identifier = _identifier;
@synthesize range = _range;
@synthesize parent = _parent;
@synthesize children = _children;

- (NSString *)spelling
{
    return [self.containingString substringWithRange:self.range];
}

+ (NSSet *)keyPathsForValuesAffectingSpelling
{
    return [NSSet setWithObjects:@"containingString", @"range", nil];
}

- (NSArray *)identifiersStack
{
    NSMutableArray *identifiersStack = [NSMutableArray array];
    ECCodeScope *currentScope = self;
    while (currentScope)
    {
        [identifiersStack insertObject:currentScope.identifier atIndex:0];
        currentScope = currentScope.parent;
    }
    return identifiersStack;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{%d,%d} : %@ (%d children)", [self range].location, [self range].length, [self identifier], [[self children] count]];
}

@end

@interface ECCodeUnit ()
{
    NSOperationQueue *_consumerOperationQueue;
    ECCodeIndex *_index;
    ECFileBuffer *_fileBuffer;
    NSString *_rootScopeIdentifier;
    NSMutableDictionary *_extensions;
    TMSyntax *__syntax;
    NSMutableDictionary *_firstMatches;
    NSMutableArray *_tokens;
    NSArray *__topLevelScopes;
}
- (TMSyntax *)_syntax;
- (NSArray *)_topLevelScopes;
- (ECCodeScope *)_scopeContainingRange:(NSRange)range;
- (NSArray *)_createScopesInRange:(NSRange)range withMatchPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesInRange:(NSRange)range withSpanPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesInRange:(NSRange)range withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesInRange:(NSRange)range withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesForCaptures:(NSDictionary *)captures inResult:(OnigResult *)result;
- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
@end

@implementation ECCodeUnit

+ (void)registerExtension:(Class)extensionClass forScopeIdentifier:(NSString *)scopeIdentifier forKey:(id)key
{
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *extensionClassesForScope = [_extensionClasses objectForKey:scopeIdentifier];
    if (!extensionClassesForScope)
    {
        extensionClassesForScope = [[NSMutableDictionary alloc] init];
        [_extensionClasses setObject:extensionClassesForScope forKey:scopeIdentifier];
    }
    [extensionClassesForScope setObject:extensionClass forKey:key];
}

- (id)initWithIndex:(ECCodeIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    ECASSERT(index && fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _consumerOperationQueue = [NSOperationQueue currentQueue];
    _index = index;
    _fileBuffer = fileBuffer;
    [_fileBuffer addConsumer:self];
    _rootScopeIdentifier = rootScopeIdentifier;
    __syntax = [TMSyntax syntaxWithScope:rootScopeIdentifier];
    ECASSERT(__syntax);
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

- (ECCodeIndex *)index
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

- (NSArray *)_topLevelScopes
{
    if (!__topLevelScopes)
    {
        __topLevelScopes = [self _createScopesInRange:NSMakeRange(0, [[self fileBuffer] length]) withPatterns:[[self _syntax] patterns] stopOnRegexp:nil withName:nil captures:nil remainingRange:NULL];
    }
    return __topLevelScopes;
}

- (ECCodeScope *)_scopeContainingRange:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [[self fileBuffer] length]);
    NSArray *currentScopes = [self _topLevelScopes];
    ECCodeScope *containingScope = nil;
    BOOL childScopeContainsRange = NO;
    do
    {
        childScopeContainsRange = NO;
        for (ECCodeScope *currentScope in currentScopes)
        {
            if ([currentScope range].location > range.location || NSMaxRange([currentScope range]) < NSMaxRange(range))
                continue;
            containingScope = currentScope;
            currentScopes = [currentScope children];
            childScopeContainsRange = YES;
            break;
        }
    }
    while (childScopeContainsRange);
    return containingScope;
}

- (NSArray *)_createScopesInRange:(NSRange)range withMatchPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange
{
    return [self _createScopesInRange:range withRegexp:[pattern match] name:[pattern name] captures:[pattern captures] remainingRange:remainingRange];
}

- (NSArray *)_createScopesInRange:(NSRange)range withSpanPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange
{
    NSRange localRemainingRange;
    if (remainingRange)
        *remainingRange = range;
    NSMutableArray *childScopes = [NSMutableArray array];
    if ([pattern beginCaptures])
    {
        NSArray *beginScopes = [self _createScopesInRange:range withRegexp:[pattern begin] name:[[[pattern beginCaptures] objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName] captures:[pattern beginCaptures] remainingRange:&localRemainingRange];
        if (![beginScopes count])
            return nil;
        [childScopes addObjectsFromArray:beginScopes];
    }
    else
    {
        OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:[pattern begin]];
        if (!beginResult)
            return nil;
        localRemainingRange.location = NSMaxRange([beginResult bodyRange]);
        localRemainingRange.length = NSMaxRange(range) - localRemainingRange.location;
    }
    [childScopes addObjectsFromArray:[self _createScopesInRange:localRemainingRange withPatterns:[pattern patterns] stopOnRegexp:[pattern end] withName:[[[pattern endCaptures] objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName] captures:[pattern endCaptures] remainingRange:&localRemainingRange]];
    if (remainingRange)
        *remainingRange = localRemainingRange;
    if (![pattern name])
        return childScopes;
    ECCodeScope *scope = [[ECCodeScope alloc] init];
    scope.containingString = [[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])];
    ECASSERT([[pattern name] isKindOfClass:[NSString class]]);
    scope.identifier = [pattern name];
    scope.range = NSMakeRange(range.location, localRemainingRange.location - range.location);
    if ([childScopes count])
    {
        for (ECCodeScope *childScope in childScopes)
            childScope.parent = scope;
        scope.children = childScopes;
    }
    ECASSERT([scope range].length);
    return [NSArray arrayWithObject:scope];
}

- (NSArray *)_createScopesInRange:(NSRange)range withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange
{
    NSRange currentRange = range;
    NSMutableArray *scopes = [NSMutableArray array];
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
            NSArray *endCaptures = [self _createScopesInRange:currentRange withRegexp:regexp name:name captures:captures remainingRange:remainingRange];
            if ([endCaptures count])
                [scopes addObjectsFromArray:endCaptures];
            return scopes;
        }
        if (!firstMatchPattern)
            break;
        if ([firstMatchPattern match])
            [scopes addObjectsFromArray:[self _createScopesInRange:currentRange withMatchPattern:firstMatchPattern remainingRange:&currentRange]];
        else
            [scopes addObjectsFromArray:[self _createScopesInRange:currentRange withSpanPattern:firstMatchPattern remainingRange:&currentRange]];
    }
    if (remainingRange)
        *remainingRange = currentRange;
    return scopes;
}

- (NSArray *)_createScopesInRange:(NSRange)range withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange
{
    OnigResult *result = [self _firstMatchInRange:range forRegexp:regexp];
    if (!result)
        return nil;
    NSArray *captureScopes = nil;
    if (captures)
        captureScopes = [self _createScopesForCaptures:captures inResult:result];
    if (remainingRange)
    {
        remainingRange->location = NSMaxRange([result bodyRange]);
        remainingRange->length = NSMaxRange(range) - remainingRange->location;
    }
    if (!name)
        return captureScopes;
    ECCodeScope *scope = [[ECCodeScope alloc] init];
    scope.containingString = [[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])];
    ECASSERT([name isKindOfClass:[NSString class]]);
    scope.identifier = name;
    scope.range = [result bodyRange];
    if ([captureScopes count])
    {
        for (ECCodeScope *captureScope in captureScopes)
            captureScope.parent = scope;
        scope.children = captureScopes;
    }
    return [NSArray arrayWithObject:scope];
}

- (NSArray *)_createScopesForCaptures:(NSDictionary *)captures inResult:(OnigResult *)result
{
    NSMutableArray *captureScopes = [NSMutableArray array];
    NSUInteger numMatchRanges = [result count];
    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
    {
        NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
        if (!currentMatchRange.length)
            continue;
        NSString *currentCaptureName = [[captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
        if (!currentCaptureName)
            continue;
        ECCodeScope *scope = [[ECCodeScope alloc] init];
        scope.containingString = [[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])];
        ECASSERT([currentCaptureName isKindOfClass:[NSString class]]);
        scope.identifier = currentCaptureName;
        scope.range = currentMatchRange;
        [captureScopes addObject:scope];
    }
    return captureScopes;
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
