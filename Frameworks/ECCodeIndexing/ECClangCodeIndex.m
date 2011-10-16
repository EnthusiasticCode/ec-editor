//
//  ECClangCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <clang-c/Index.h>
#import "ECClangCodeIndex.h"
#import "ECClangCodeUnit.h"

@implementation ECClangCodeIndex

@synthesize index = index_;

- (void)dealloc
{
    clang_disposeIndex(self.index);
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    self.index = clang_createIndex(0, 1);
    return self;
}

+ (void)load
{
    [ECCodeIndex registerExtension:self];
}

+ (void)registerExtension:(Class)extensionClass
{
    ECASSERT(NO); // ECClangCodeIndex does not support extensions at the moment
}

+ (NSArray *)supportedLanguages
{
    return [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", nil];
}

+ (float)supportForFile:(NSURL *)fileURL
{
    ECASSERT([fileURL isFileURL]);
    NSString *fileExtension = [fileURL pathExtension];
    NSArray *supportedFileExtensions = [NSArray arrayWithObjects:@"h", @"c", @"cc", @"m", @"mm", nil];
    for (NSString *supportedExtension in supportedFileExtensions)
        if ([fileExtension isEqualToString:supportedExtension])
            return 1.0;
    return 0.0;
}

- (id<ECCodeUnit>)unitWithFileURL:(NSURL *)fileURL
{
    return [self unitWithFileURL:fileURL withLanguage:nil];
}

- (id<ECCodeUnit>)unitWithFileURL:(NSURL *)fileURL withLanguage:(NSString *)language
{
    return [[ECClangCodeUnit alloc] initWithIndex:self fileURL:fileURL language:language];
}

@end
