//
//  TMSyntax.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntax+Internal.h"
#import "TMBundle+Internal.h"
#import "TMPattern+Internal.h"
#import "ECCodeIndex.h"
#import "OnigRegexp.h"
#import <ECFoundation/ECDiscardableMutableDictionary.h>
#import <ECFoundation/ECFileBuffer.h>

static NSString * const _syntaxNameKey = @"name";
static NSString * const _syntaxScopeKey = @"scopeName";
static NSString * const _syntaxFileTypesKey = @"fileTypes";
static NSString * const _syntaxFirstLineMatchKey = @"firstLineMatch";
static NSString * const _syntaxPatternsKey = @"patterns";
static NSString * const _syntaxRepositoryKey = @"repository";

static ECDiscardableMutableDictionary *_syntaxes;

@interface TMSyntax ()
{
    NSInteger _contentAccessCount;
    NSURL *_fileURL;
    ECFileBuffer *_fileBuffer;
    NSString *_name;
    NSString *_scopeIdentifier;
    NSArray *__fileTypes;
    OnigRegexp *__firstLineMatch;
    NSDictionary *_plist;
    NSArray *_patterns;
    NSDictionary *_repository;
}
- (id)_initWithFileURL:(NSURL *)fileURL;
- (NSArray *)_fileTypes;
- (OnigRegexp *)_firstLineMatch;
+ (TMSyntax *)_syntaxWithPredicateBlock:(BOOL(^)(TMSyntax *syntax))predicateBlock;
@end

@implementation TMSyntax

#pragma mark - Public Class Methods

+ (TMSyntax *)syntaxWithScope:(NSString *)scope
{
    if (!scope)
        return nil;
    return [_syntaxes objectForKey:scope];
}

+ (TMSyntax *)syntaxForFileBuffer:(ECFileBuffer *)fileBuffer
{
    ECASSERT(fileBuffer);
    TMSyntax *foundSyntax = [self _syntaxWithPredicateBlock:^BOOL(TMSyntax *syntax) {
        for (NSString *fileType in [syntax _fileTypes])
            if ([fileType isEqualToString:[[fileBuffer fileURL] pathExtension]])
                return YES;
        return NO;
    }];
    if (!foundSyntax)
        foundSyntax = [self _syntaxWithPredicateBlock:^BOOL(TMSyntax *syntax) {
            NSString *fileContents = [fileBuffer stringInRange:NSMakeRange(0, [fileBuffer length])];
            NSString *firstLine = [fileContents substringWithRange:[fileContents lineRangeForRange:NSMakeRange(0, 1)]];
            if ([[syntax _firstLineMatch] search:firstLine])
                return YES;
            return NO;
        }];
    return foundSyntax;
}

#pragma mark - Internal Class Methods

+ (void)loadAllSyntaxes
{
    _syntaxes = [ECDiscardableMutableDictionary dictionary];
    for (NSURL *syntaxURL in [TMBundle syntaxFileURLs])
    {
        TMSyntax *syntax = [[TMSyntax alloc] _initWithFileURL:syntaxURL];
        if (!syntax)
            continue;
        [syntax endContentAccess];
        [_syntaxes setObject:syntax forKey:[syntax scopeIdentifier]];
    }
}

#pragma mark - Private Class Methods

+ (TMSyntax *)_syntaxWithPredicateBlock:(BOOL (^)(TMSyntax *))predicateBlock
{
    ECASSERT(predicateBlock);
    for (TMSyntax *syntax in [_syntaxes objectEnumerator])
        if (predicateBlock(syntax))
            return syntax;
    return nil;
}

#pragma mark - Public Methods

- (NSString *)name
{
    return _name;
}

- (NSString *)scopeIdentifier
{
    return _scopeIdentifier;
}

- (NSArray *)patterns
{
    ECASSERT(_contentAccessCount > 0);
    if (!_patterns)
    {
        NSLog(@"%@", _plist);
        ECASSERT([_plist objectForKey:_syntaxPatternsKey]);
        NSMutableArray *patterns = [NSMutableArray array];
        for (NSDictionary *patternDictionary in [_plist objectForKey:_syntaxPatternsKey])
            [patterns addObjectsFromArray:[TMPattern patternsWithSyntax:self inDictionary:patternDictionary]];
        _patterns = [patterns copy];
    }
    return _patterns;
}

#pragma mark - Internal Methods

- (NSDictionary *)repository
{
    ECASSERT(_contentAccessCount > 0);
    return [_plist objectForKey:_syntaxRepositoryKey];
}

- (NSArray *)patternsDictionaries
{
    ECASSERT(_contentAccessCount > 0);
    return [_plist objectForKey:_syntaxPatternsKey];
}

#pragma mark - Private Methods

- (id)_initWithFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    self = [super init];
    if (!self)
        return nil;
    _contentAccessCount = 1;
    _fileURL = fileURL;
    _plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    _name = [_plist objectForKey:_syntaxNameKey];
    if (!_name)
        return nil;
    _scopeIdentifier = [_plist objectForKey:_syntaxScopeKey];
    __fileTypes = [_plist objectForKey:_syntaxFileTypesKey];
    NSString *firstLineMatchRegex = [_plist objectForKey:_syntaxFirstLineMatchKey];
    if (firstLineMatchRegex)
        __firstLineMatch = [OnigRegexp compile:firstLineMatchRegex ignorecase:NO multiline:YES];
    return self;
}

- (NSArray *)_fileTypes
{
    return __fileTypes;
}

- (OnigRegexp *)_firstLineMatch
{
    return __firstLineMatch;
}

#pragma mark - NSDiscardableContent

- (BOOL)beginContentAccess
{
    ECASSERT(_contentAccessCount >= 0);
    ++_contentAccessCount;
    return YES;
}

- (void)endContentAccess
{
    ECASSERT(_contentAccessCount > 0);
    --_contentAccessCount;
}

- (void)discardContentIfPossible
{
    ECASSERT(_contentAccessCount >= 0);
    if (_contentAccessCount > 0)
        return;
    _patterns = nil;
    _repository = nil;
    _plist = nil;
}

- (BOOL)isContentDiscarded
{
    ECASSERT(_contentAccessCount >= 0);
    return !_patterns && !_repository && !_plist;
}

@end

