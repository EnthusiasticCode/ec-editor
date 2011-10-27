//
//  TMCodeIndex.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexSubclass.h"
#import "TMCodeIndex.h"
#import "TMCodeParser.h"
#import "TMBundle.h"
#import "TMSyntax.h"
#import "OnigRegexp.h"

@interface TMCodeIndex ()
+ (TMSyntax *)_syntaxForFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope;
+ (TMSyntax *)_syntaxForFile:(NSURL *)fileURL;
+ (TMSyntax *)_syntaxWithLanguage:(NSString *)language;
+ (TMSyntax *)_syntaxWithPredicateBlock:(BOOL(^)(TMSyntax *syntax))predicateBlock;
@end

@implementation TMCodeIndex

+ (void)load
{
    [ECCodeIndex registerExtension:self];
}

+ (float)implementsProtocol:(Protocol *)protocol forFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    ECASSERT(fileURL);
    if (protocol != @protocol(ECCodeParser))
        return 0.0;
    if (![self _syntaxForFile:fileURL language:language scope:scope])
        return 0.0;
    return 0.5;
}

- (id)codeUnitImplementingProtocol:(Protocol *)protocol withFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    ECASSERT(protocol);
    ECASSERT(fileURL);
    if (protocol == @protocol(ECCodeParser))
        return [[TMCodeParser alloc] initWithIndex:self fileURL:fileURL syntax:[[self class] _syntaxForFile:fileURL language:language scope:scope]];
    return nil;
}

+ (TMSyntax *)_syntaxForFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    TMSyntax *syntax = [self syntaxWithScope:scope];
    if (!syntax)
        syntax = [self _syntaxWithLanguage:language];
    if (!syntax)
        syntax = [self _syntaxForFile:fileURL];
    return syntax;
}

+ (TMSyntax *)_syntaxForFile:(NSURL *)fileURL
{
    TMSyntax *foundSyntax = [self _syntaxWithPredicateBlock:^BOOL(TMSyntax *syntax) {
        for (NSString *fileType in syntax.fileTypes)
            if ([fileType isEqualToString:[fileURL pathExtension]])
                return YES;
        return NO;
    }];
    if (!foundSyntax)
        foundSyntax = [self _syntaxWithPredicateBlock:^BOOL(TMSyntax *syntax) {
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
            __block NSString *firstLine = nil;
            [fileCoordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
                NSString *fileContents = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL];
                firstLine = [fileContents substringWithRange:[fileContents lineRangeForRange:NSMakeRange(0, 1)]];
            }];
            if ([syntax.firstLineMatch search:firstLine])
                return YES;
            return NO;
        }];
    return foundSyntax;
}

+ (TMSyntax *)_syntaxWithLanguage:(NSString *)language
{
    return [self _syntaxWithPredicateBlock:^BOOL(TMSyntax *syntax) {
        return [syntax.name isEqualToString:language];
    }];
}

+ (TMSyntax *)syntaxWithScope:(NSString *)scope
{
    return [self _syntaxWithPredicateBlock:^BOOL(TMSyntax *syntax) {
        return [syntax.scope isEqualToString:scope];
    }];
}

+ (TMSyntax *)_syntaxWithPredicateBlock:(BOOL (^)(TMSyntax *))predicateBlock
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:[self bundleDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
        TMBundle *bundle = [[TMBundle alloc] initWithBundleURL:fileURL];
        if (bundle)
            for (TMSyntax *syntax in bundle.syntaxes)
                if (predicateBlock(syntax))
                    return syntax;
    }
    return nil;
}

@end
