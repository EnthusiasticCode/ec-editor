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

@interface ECClangCodeIndex()
@property (nonatomic) CXIndex index;
@end

@implementation ECClangCodeIndex

@synthesize index = index_;

- (void)dealloc
{
    clang_disposeIndex(self.index);
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    self.index = clang_createIndex(0, 0);
    return self;
}

- (NSDictionary *)languageToExtensionMap
{
    NSArray *languages = [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", nil];
    NSArray *extensionForLanguages = [NSArray arrayWithObjects:@"c", @"m", @"cc", @"mm", nil];
    return [NSDictionary dictionaryWithObjects:extensionForLanguages forKeys:languages];
}

- (NSDictionary *)extensionToLanguageMap
{
    NSArray *extensions = [NSArray arrayWithObjects:@"c", @"m", @"cc", @"mm", @"h", nil];
    NSArray *languageForextensions = [NSArray arrayWithObjects:@"C", @"Objective C", @"C++", @"Objective C++", @"C", nil];
    return [NSDictionary dictionaryWithObjects:languageForextensions forKeys:extensions];
}

- (id<ECCodeUnitPlugin>)unitPluginForFile:(NSString *)file withLanguage:(NSString *)language
{
    return [ECClangCodeUnit unitForFile:file index:self.index language:language];
}

@end
