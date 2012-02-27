//
//  TMSyntaxNode.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMSyntaxNode.h"
#import "TMBundle.h"
#import "OnigRegexp.h"
#import "CodeFile.h"

static NSString * const _syntaxDirectory = @"Syntaxes";

static NSString * const _scopeIdentifierKey = @"scopeName";
static NSString * const _fileTypesKey = @"fileTypes";
static NSString * const _firstLineMatchKey = @"firstLineMatch";
static NSString * const _foldingStartMarkerKey = @"foldingStartMarker";
static NSString * const _foldingStopMarkerKey = @"foldingStopMarker";
static NSString * const _matchKey = @"match";
static NSString * const _beginKey = @"begin";
static NSString * const _endKey = @"end";
static NSString * const _nameKey = @"name";
static NSString * const _contentNameKey = @"contentName";
static NSString * const _capturesKey = @"captures";
static NSString * const _beginCapturesKey = @"beginCaptures";
static NSString * const _endCapturesKey = @"endCaptures";
static NSString * const _patternsKey = @"patterns";
static NSString * const _repositoryKey = @"repository";
static NSString * const _includeKey = @"include";

static NSMutableDictionary *_syntaxesWithIdentifier;
static NSMutableArray *_syntaxesWithoutIdentifier;

@interface TMSyntaxNode ()
- (id)_initWithDictionary:(NSDictionary *)dictionary syntax:(TMSyntaxNode *)syntax;
@end

@implementation TMSyntaxNode

#pragma mark - Class Methods

+ (void)initialize
{
    if (self != [TMSyntaxNode class])
        return;
    // This class takes a long time to initialize, we have to make sure it doesn't do so on the main queue
    ECASSERT([NSOperationQueue currentQueue] != [NSOperationQueue mainQueue]);
    _syntaxesWithIdentifier = [[NSMutableDictionary alloc] init];
    _syntaxesWithoutIdentifier = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *bundleURL in [TMBundle bundleURLs])
        for (NSURL *syntaxURL in [fileManager contentsOfDirectoryAtURL:[bundleURL URLByAppendingPathComponent:_syntaxDirectory] includingPropertiesForKeys:nil options:0 error:NULL])
        {
            NSData *plistData = [NSData dataWithContentsOfURL:syntaxURL options:NSDataReadingUncached error:NULL];
            if (!plistData)
                continue;
            NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:NULL];
            if (!plist)
                continue;
            TMSyntaxNode *syntax = [[self alloc] _initWithDictionary:plist syntax:nil];
            if (!syntax)
                continue;
            if (syntax.scopeName)
                [_syntaxesWithIdentifier setObject:syntax forKey:syntax.scopeName];
            else
                [_syntaxesWithoutIdentifier addObject:syntax];
        }
    _syntaxesWithIdentifier = [_syntaxesWithIdentifier copy];
}

+ (TMSyntaxNode *)syntaxWithScopeIdentifier:(NSString *)scopeIdentifier
{
    if (!scopeIdentifier)
        return nil;
    return [_syntaxesWithIdentifier objectForKey:scopeIdentifier];
}

+ (TMSyntaxNode *)syntaxForCodeFile:(CodeFile *)codeFile
{
    if (!codeFile)
        return nil;
    static TMSyntaxNode *(^syntaxWithPredicateBlock)(BOOL (^)(TMSyntaxNode *)) = ^TMSyntaxNode *(BOOL (^predicateBlock)(TMSyntaxNode *)) {
        for (TMSyntaxNode *syntax in [_syntaxesWithIdentifier objectEnumerator])
            if (predicateBlock(syntax))
                return syntax;
        for (TMSyntaxNode *syntax in _syntaxesWithoutIdentifier)
            if (predicateBlock(syntax))
                return syntax;
        return nil;
    };
    TMSyntaxNode *foundSyntax = syntaxWithPredicateBlock(^BOOL(TMSyntaxNode *syntax) {
        for (NSString *fileType in syntax.fileTypes)
            if ([fileType isEqualToString:[[codeFile fileURL] pathExtension]])
                return YES;
        return NO;
    });
    if (!foundSyntax)
        foundSyntax = syntaxWithPredicateBlock(^BOOL(TMSyntaxNode *syntax) {
            NSRange firstLineRange = [codeFile lineRangeForRange:NSMakeRange(0, 0)];
            NSString *firstLine = [codeFile stringInRange:firstLineRange];
            if (firstLine && [syntax.firstLineMatch search:firstLine])
                return YES;
            return NO;
        });
    return foundSyntax;
}

#pragma mark - Public Methods

@synthesize rootSyntax = _rootSyntax;
@synthesize scopeName = _scopeName;
@synthesize fileTypes = _fileTypes;
@synthesize firstLineMatch = _firstLineMatch;
@synthesize foldingStartMarker = _foldingStartMarker;
@synthesize foldingStopMarker = _foldingStopMarker;
@synthesize match = _match;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize name = _name;
@synthesize contentName = _contentName;
@synthesize captures = _captures;
@synthesize beginCaptures = _beginCaptures;
@synthesize endCaptures = _endCaptures;
@synthesize patterns = _patterns;
@synthesize repository = _repository;
@synthesize include = _include;

#pragma mark - Private Methods

- (id)_initWithDictionary:(NSDictionary *)dictionary syntax:(TMSyntaxNode *)syntax
{
    ECASSERT(dictionary);
    self = [super init];
    if (!self)
        return nil;
    if (!syntax)
        syntax = self;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:_scopeIdentifierKey] ||
            [key isEqualToString:_fileTypesKey] ||
            [key isEqualToString:_endKey] ||
            [key isEqualToString:_nameKey] ||
            [key isEqualToString:_contentNameKey] ||
            [key isEqualToString:_capturesKey] ||
            [key isEqualToString:_beginCapturesKey] ||
            [key isEqualToString:_endCapturesKey] ||
            [key isEqualToString:_includeKey])
        {
            if (([obj respondsToSelector:@selector(length)] && [obj length]) || ([obj respondsToSelector:@selector(count)] && [obj count]))
                [self setValue:obj forKey:key];
        }
        else if ([key isEqualToString:_firstLineMatchKey] ||
                 [key isEqualToString:_foldingStartMarkerKey] ||
                 [key isEqualToString:_foldingStopMarkerKey] ||
                 [key isEqualToString:_matchKey] ||
                 [key isEqualToString:_beginKey])
        {
            if ([obj length])
                [self setValue:[OnigRegexp compile:obj options:OnigOptionCaptureGroup] forKey:key];
        }
        else if ([key isEqualToString:_patternsKey])
        {
            NSMutableArray *patterns = [[NSMutableArray alloc] init];
            for (NSDictionary *dictionary in obj)
                [patterns addObject:[[[self class] alloc] _initWithDictionary:dictionary syntax:syntax]];
            if ([patterns count])
                [self setValue:[patterns copy] forKey:key];
        }
        else if ([key isEqualToString:_repositoryKey])
        {
            NSMutableDictionary *repository = [[NSMutableDictionary alloc] init];
            [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [repository setObject:[[[self class] alloc] _initWithDictionary:obj syntax:syntax] forKey:key];
            }];
            if ([repository count])
                [self setValue:[repository copy] forKey:key];
        }
    }];
    _rootSyntax = syntax;
    if (_captures && !_beginCaptures)
        _beginCaptures = _captures;
    if (_captures && !_endCaptures)
        _endCaptures = _captures;
    if (_name && !_scopeName && _rootSyntax)
        _scopeName = _name;
    return self;
}

- (NSUInteger)hash
{
    if (_scopeName)
        return [_scopeName hash];
    else if (_include)
        return [_include hash];
    else
        return [_patterns hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end

