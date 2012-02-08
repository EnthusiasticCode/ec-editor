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
#import "FileBuffer.h"

static NSString * const _syntaxDirectory = @"Syntaxes";

NSString * const TMSyntaxScopeIdentifierKey = @"scopeName";
NSString * const TMSyntaxFileTypesKey = @"fileTypes";
NSString * const TMSyntaxFirstLineMatchKey = @"firstLineMatch";
NSString * const TMSyntaxFoldingStartMarker = @"foldingStartMarker";
NSString * const TMSyntaxFoldingStopMarker = @"foldingStopMarker";
NSString * const TMSyntaxMatchKey = @"match";
NSString * const TMSyntaxBeginKey = @"begin";
NSString * const TMSyntaxEndKey = @"end";
NSString * const TMSyntaxNameKey = @"name";
NSString * const TMSyntaxContentNameKey = @"contentName";
NSString * const TMSyntaxCapturesKey = @"captures";
NSString * const TMSyntaxBeginCapturesKey = @"beginCaptures";
NSString * const TMSyntaxEndCapturesKey = @"endCaptures";
NSString * const TMSyntaxPatternsKey = @"patterns";
NSString * const TMSyntaxRepositoryKey = @"repository";
NSString * const TMSyntaxIncludeKey = @"include";

static NSMutableDictionary *_allSyntaxes;

@interface TMSyntaxNode ()
{
    __weak TMSyntaxNode *_rootSyntax;
    NSDictionary *_attributes;
}
- (id)_initWithDictionary:(NSDictionary *)dictionary syntax:(TMSyntaxNode *)syntax;
@end

@implementation TMSyntaxNode

#pragma mark - Class Methods

+ (void)initialize
{
    if (self != [TMSyntaxNode class])
        return;
    _allSyntaxes = [[NSMutableDictionary alloc] init];
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
            [_allSyntaxes setObject:syntax forKey:[[syntax attributes] objectForKey:TMSyntaxScopeIdentifierKey]];
        }
    _allSyntaxes = [_allSyntaxes copy];
}

+ (TMSyntaxNode *)syntaxWithScopeIdentifier:(NSString *)scopeIdentifier
{
    if (!scopeIdentifier)
        return nil;
    return [_allSyntaxes objectForKey:scopeIdentifier];
}

+ (TMSyntaxNode *)syntaxForFileBuffer:(FileBuffer *)fileBuffer
{
    ECASSERT(fileBuffer);
    static TMSyntaxNode *(^syntaxWithPredicateBlock)(BOOL (^)(TMSyntaxNode *)) = ^TMSyntaxNode *(BOOL (^predicateBlock)(TMSyntaxNode *)){
        for (TMSyntaxNode *syntax in [_allSyntaxes objectEnumerator])
            if (predicateBlock(syntax))
                return syntax;
        return nil;
    };
    TMSyntaxNode *foundSyntax = syntaxWithPredicateBlock(^BOOL(TMSyntaxNode *syntax) {
        for (NSString *fileType in [[syntax attributes] objectForKey:TMSyntaxFileTypesKey])
            if ([fileType isEqualToString:[[fileBuffer fileURL] pathExtension]])
                return YES;
        return NO;
    });
    if (!foundSyntax)
        foundSyntax = syntaxWithPredicateBlock(^BOOL(TMSyntaxNode *syntax) {
            NSString *fileContents = [fileBuffer stringInRange:NSMakeRange(0, [fileBuffer length])];
            NSString *firstLine = [fileContents substringWithRange:[fileContents lineRangeForRange:NSMakeRange(0, 1)]];
            if ([[[syntax attributes] objectForKey:TMSyntaxFirstLineMatchKey]  search:firstLine])
                return YES;
            return NO;
        });
    return foundSyntax;
}

#pragma mark - Public Methods

- (TMSyntaxNode *)rootSyntax
{
    return _rootSyntax;
}

- (NSDictionary *)attributes
{
    return _attributes;
}

#pragma mark - Private Methods

- (id)_initWithDictionary:(NSDictionary *)dictionary syntax:(TMSyntaxNode *)syntax
{
    ECASSERT(dictionary);
    self = [super init];
    if (!self)
        return nil;
    if (!syntax)
        syntax = self;
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:TMSyntaxScopeIdentifierKey] ||
            [key isEqualToString:TMSyntaxFileTypesKey] ||
            [key isEqualToString:TMSyntaxEndKey] ||
            [key isEqualToString:TMSyntaxNameKey] ||
            [key isEqualToString:TMSyntaxContentNameKey] ||
            [key isEqualToString:TMSyntaxCapturesKey] ||
            [key isEqualToString:TMSyntaxBeginCapturesKey] ||
            [key isEqualToString:TMSyntaxEndCapturesKey] ||
            [key isEqualToString:TMSyntaxIncludeKey])
            [attributes setObject:obj forKey:key];
        else if ([key isEqualToString:TMSyntaxFirstLineMatchKey] ||
                 [key isEqualToString:TMSyntaxFoldingStartMarker] ||
                 [key isEqualToString:TMSyntaxFoldingStopMarker] ||
                 [key isEqualToString:TMSyntaxMatchKey] ||
                 [key isEqualToString:TMSyntaxBeginKey])
            [attributes setObject:[OnigRegexp compile:obj options:OnigOptionCaptureGroup | OnigOptionNotbol | OnigOptionNoteol] forKey:key];
        else if ([key isEqualToString:TMSyntaxPatternsKey])
        {
            NSMutableArray *patterns = [[NSMutableArray alloc] init];
            for (NSDictionary *dictionary in obj)
                [patterns addObject:[[[self class] alloc] _initWithDictionary:dictionary syntax:syntax]];
            [attributes setObject:[patterns copy] forKey:key];
        }
        else if ([key isEqualToString:TMSyntaxRepositoryKey])
        {
            NSMutableDictionary *repository = [[NSMutableDictionary alloc] init];
            [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [repository setObject:[[[self class] alloc] _initWithDictionary:obj syntax:syntax] forKey:key];
            }];
            [attributes setObject:[repository copy] forKey:key];
        }
    }];
    _rootSyntax = syntax;
    _attributes = [attributes copy];
    return self;
}

@end
            
