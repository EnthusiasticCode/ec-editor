//
//  TMSyntax.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntax.h"
#import "TMBundle.h"
#import "TMPattern.h"
#import "OnigRegexp.h"
#import "FileBuffer.h"

static NSString * const _syntaxDirectory = @"Syntaxes";

static NSString * const _syntaxNameKey = @"name";
static NSString * const _syntaxScopeKey = @"scopeName";
static NSString * const _syntaxFileTypesKey = @"fileTypes";
static NSString * const _syntaxFirstLineMatchKey = @"firstLineMatch";
static NSString * const _syntaxPatternsKey = @"patterns";
static NSString * const _syntaxRepositoryKey = @"repository";

static NSMutableDictionary *_allSyntaxes;

@interface TMSyntax ()
{
    NSURL *_fileURL;
    FileBuffer *_fileBuffer;
    NSString *_name;
    NSString *_scopeIdentifier;
    NSArray *__fileTypes;
    OnigRegexp *__firstLineMatch;
    NSDictionary *__plist;
    NSArray *_patterns;
    NSDictionary *_repository;
}
- (NSDictionary *)_plist;
- (NSArray *)_fileTypes;
- (OnigRegexp *)_firstLineMatch;
+ (TMSyntax *)_syntaxWithPredicateBlock:(BOOL(^)(TMSyntax *syntax))predicateBlock;
@end

@implementation TMSyntax

#pragma mark - Public Class Methods

+ (NSDictionary *)allSyntaxes
{
    if (!_allSyntaxes)
    {
        _allSyntaxes = [NSMutableDictionary dictionary];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *bundleURL in [TMBundle bundleURLs])
            for (NSURL *syntaxURL in [fileManager contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:_syntaxDirectory] includingPropertiesForKeys:nil options:0 error:NULL])
            {
                TMSyntax *syntax = [[self alloc] initWithFileURL:syntaxURL];
                if (syntax)
                    [_allSyntaxes setObject:syntax forKey:[syntax scopeIdentifier]];
            }
    }
    return _allSyntaxes;
}

+ (TMSyntax *)syntaxWithScope:(NSString *)scope
{
    if (!scope)
        return nil;
    return [_allSyntaxes objectForKey:scope];
}

+ (TMSyntax *)syntaxForFileBuffer:(FileBuffer *)fileBuffer
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

#pragma mark - Private Class Methods

+ (TMSyntax *)_syntaxWithPredicateBlock:(BOOL (^)(TMSyntax *))predicateBlock
{
    ECASSERT(predicateBlock);
    for (TMSyntax *syntax in [[self allSyntaxes] objectEnumerator])
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
    if (!_patterns)
    {
        ECASSERT([[self _plist] objectForKey:_syntaxPatternsKey]);
        NSMutableArray *patterns = [NSMutableArray array];
        for (NSDictionary *dictionary in [[self _plist] objectForKey:_syntaxPatternsKey])
            [patterns addObject:[TMPattern patternWithDictionary:dictionary inSyntax:self]];
        _patterns = [patterns copy];
    }
    return _patterns;
}

#pragma mark - Internal Methods

- (NSDictionary *)repository
{
    return [[self _plist] objectForKey:_syntaxRepositoryKey];
}

- (NSArray *)patternsDictionaries
{
    return [[self _plist] objectForKey:_syntaxPatternsKey];
}

#pragma mark - Private Methods

- (id)initWithFileURL:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    self = [super init];
    if (!self)
        return nil;
    _fileURL = fileURL;
    __plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:_fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    _name = [__plist objectForKey:_syntaxNameKey];
    if (!_name)
        return nil;
    _scopeIdentifier = [__plist objectForKey:_syntaxScopeKey];
    __fileTypes = [__plist objectForKey:_syntaxFileTypesKey];
    NSString *firstLineMatchRegex = [__plist objectForKey:_syntaxFirstLineMatchKey];
    if (firstLineMatchRegex)
        __firstLineMatch = [OnigRegexp compile:firstLineMatchRegex ignorecase:NO multiline:YES];
    return self;
}

- (NSDictionary *)_plist
{
    if (!__plist)
        __plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:_fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    return __plist;
}

- (NSArray *)_fileTypes
{
    return __fileTypes;
}

- (OnigRegexp *)_firstLineMatch
{
    return __firstLineMatch;
}

@end

