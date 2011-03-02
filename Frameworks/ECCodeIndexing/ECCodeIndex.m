//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"
#import <ECAdditions/NSURL+ECAdditions.h>
#import <objc/runtime.h>
// TODO: plugins are hardcoded for now
#import "ECClangCodeIndex.h"

@interface ECCodeIndex ()
@property (nonatomic, copy) NSDictionary *indexesByLanguage;
@property (nonatomic, copy) NSDictionary *indexesByExtension;
@property (nonatomic, copy, getter = getLanguageToExtensionMap) NSDictionary *languageToExtensionMap;
@property (nonatomic, copy, getter = getExtensionToLanguageMap) NSDictionary *extensionToLanguageMap;
- (BOOL)loadPlugins;
- (ECCodeIndex *)indexForLanguage:(NSString *)language;
- (ECCodeIndex *)indexForExtension:(NSString *)extension;
@end

@implementation ECCodeIndex

@synthesize indexesByLanguage = _indexesByLanguage;
@synthesize indexesByExtension = _indexesByExtension;
@synthesize languageToExtensionMap = _languageToExtensionMap;
@synthesize extensionToLanguageMap = _extensionToLanguageMap;

- (ECCodeIndex *)indexForLanguage:(NSString *)language
{
    return [self.indexesByLanguage objectForKey:language];
}

- (ECCodeIndex *)indexForExtension:(NSString *)extension
{
    return [self.indexesByExtension objectForKey:extension];
}

- (void)dealloc
{
    self.indexesByLanguage = nil;
    self.indexesByExtension = nil;
    self.languageToExtensionMap = nil;
    self.extensionToLanguageMap = nil;
    [super dealloc];
}

- (BOOL)loadPlugins
{
    // TODO: implement some priority system for plugin loading
    int numClasses;
    numClasses = objc_getClassList(NULL, 0);
    if (!numClasses)
        return NO;
    Class *classes = NULL;
    NSMutableArray *indexClasses;
    indexClasses = [[NSMutableArray alloc] initWithCapacity:numClasses];
    classes = malloc(sizeof(Class) * numClasses);
    objc_getClassList(classes, numClasses);
    for (int i = 0; i < numClasses; i++)
    {
        if (class_getSuperclass(classes[i]) == [ECCodeIndex class])
            [indexClasses addObject:classes[i]];
    }
    free(classes);
    ECCodeIndex *index;
    NSMutableDictionary *indexesByLanguage = [NSMutableDictionary dictionary];
    NSMutableDictionary *indexesByExtension = [NSMutableDictionary dictionary];
    NSMutableDictionary *languageToExtensionMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *extensionToLanguageMap = [NSMutableDictionary dictionary];
    for (Class indexClass in indexClasses)
    {
        index = [[indexClass alloc] init];
        NSDictionary *pluginLanguageToExtensionMappingDictionary = [index languageToExtensionMap];
        for (NSString *language in [pluginLanguageToExtensionMappingDictionary allKeys])
        {
            if ([languageToExtensionMap objectForKey:language])
                continue;
            [indexesByLanguage setObject:index forKey:language];
            [languageToExtensionMap setObject:[pluginLanguageToExtensionMappingDictionary objectForKey:language] forKey:language];
        }
        NSDictionary *pluginExtensionToLanguageMappingDictionary = [index extensionToLanguageMap];
        for (NSString *extension in [pluginExtensionToLanguageMappingDictionary allKeys])
        {
            if ([extensionToLanguageMap objectForKey:extension])
                continue;
            [indexesByExtension setObject:index forKey:extension];
            [extensionToLanguageMap setObject:[pluginExtensionToLanguageMappingDictionary objectForKey:extension] forKey:extension];
        }
        [index release];
    }
    [indexClasses release];
    self.indexesByLanguage = indexesByLanguage;
    self.indexesByExtension = indexesByExtension;
    self.languageToExtensionMap = languageToExtensionMap;
    self.extensionToLanguageMap = extensionToLanguageMap;
    return YES;
}

- (id)init
{
    self = [super init];
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return self;
    if (!self)
        return nil;
    if (![self loadPlugins])
    {
        [self release];
        return nil;
    }
    return self;
}

- (NSDictionary *)languageToExtensionMap
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    return self.languageToExtensionMap;
}

- (NSDictionary *)extensionToLanguageMap
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    return self.extensionToLanguageMap;
}

- (NSString *)languageForExtension:(NSString *)extension
{
    return [[self extensionToLanguageMap] objectForKey:extension];
}

- (NSString *)extensionForLanguage:(NSString *)language
{
    return [[self languageToExtensionMap] objectForKey:language];
}

- (NSSet *)trackedFiles
{
    return [NSSet set];
}

- (BOOL)trackFile:(id<ECCodeIndexingFileTracking>)file
{
    return YES;
}

- (ECCodeUnit *)unitForURL:(NSURL *)url
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    return [[self.indexesByExtension objectForKey:[url pathExtension]] unitForURL:url];
}

- (ECCodeUnit *)unitForURL:(NSURL *)url withLanguage:(NSString *)language
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    return [[self.indexesByLanguage objectForKey:language] unitForURL:url withLanguage:language];
}

@end
