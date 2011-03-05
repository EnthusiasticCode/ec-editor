//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeIndex(Private).h"
#import "ECCodeUnit.h"
#import "ECCodeUnit(Private).h"
#import <ECAdditions/NSURL+ECAdditions.h>
#import <objc/runtime.h>
// TODO: plugins are hardcoded for now
#import "ECClangCodeIndex.h"

@interface ECCodeIndex ()
@property (nonatomic, copy) NSDictionary *indexesByLanguage;
@property (nonatomic, copy) NSDictionary *indexesByExtension;
@property (nonatomic, copy, getter = getLanguageToExtensionMap) NSDictionary *languageToExtensionMap;
@property (nonatomic, copy, getter = getExtensionToLanguageMap) NSDictionary *extensionToLanguageMap;
@property (nonatomic, retain) NSMutableDictionary *codeUnitPointers;
@property (nonatomic, retain) NSMutableDictionary *filePointers;
- (BOOL)loadPlugins;
- (ECCodeIndex *)indexForLanguage:(NSString *)language;
- (ECCodeIndex *)indexForExtension:(NSString *)extension;
- (void)addObserversForUnitsToFile:(NSObject<ECCodeIndexingFileObserving> *)file;
- (void)removeObserversForUnitsFromFile:(NSObject<ECCodeIndexingFileObserving> *)file;
@end

#pragma mark -

@implementation ECCodeIndex

@synthesize indexesByLanguage = _indexesByLanguage;
@synthesize indexesByExtension = _indexesByExtension;
@synthesize languageToExtensionMap = _languageToExtensionMap;
@synthesize extensionToLanguageMap = _extensionToLanguageMap;
@synthesize codeUnitPointers = _codeUnitPointers;
@synthesize filePointers = _filePointers;

#pragma mark -
#pragma mark Initialization and deallocation

- (void)dealloc
{
    self.indexesByLanguage = nil;
    self.indexesByExtension = nil;
    self.languageToExtensionMap = nil;
    self.extensionToLanguageMap = nil;
    self.codeUnitPointers = nil;
    self.filePointers = nil;
    [super dealloc];
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
    self.codeUnitPointers = [NSMutableDictionary dictionary];
    self.filePointers = [NSMutableDictionary dictionary];
    return self;
}

#pragma mark -
#pragma mark Public Methods

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

- (NSArray *)observedFiles
{
    return [self.filePointers allValues];
}

- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    if ([self.filePointers objectForKey:file.URL])
        return NO;
    [self addObserversForUnitsToFile:file];
    [file addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionPrior context:NULL];
    return YES;
}

- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    [self removeObserversForUnitsFromFile:file];
    [file removeObserver:self forKeyPath:@"URL"];
    [self.filePointers removeObjectForKey:file.URL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL isPriorToChange = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPriorToChange)
        [self removeObserversForUnitsFromFile:object];
    NSURL *newURL = [change objectForKey:NSKeyValueChangeNewKey];
    if (newURL)
        [self addObserversForUnitsToFile:object];
}

- (ECCodeUnit *)unitForURL:(NSURL *)url
{
    return [self unitForURL:url withLanguage:nil];
}

- (ECCodeUnit *)unitForURL:(NSURL *)url withLanguage:(NSString *)language
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    if (!url)
        return nil;
    ECCodeUnit *unit;
    unit = [[self.codeUnitPointers objectForKey:url] nonretainedObjectValue];
    if (unit)
        return unit;
    if (language)
        unit = [[self indexForLanguage:language] unitForURL:url withLanguage:language];
    else
        unit = [[self.indexesByExtension objectForKey:[url pathExtension]] unitForURL:url withLanguage:nil];
    if (!unit)
        return nil;
    unit.index = self;
    [self.codeUnitPointers setObject:[NSValue valueWithNonretainedObject:unit] forKey:url];
    for (NSObject<ECCodeIndexingFileObserving> *file in self.filePointers)
        [unit addObserversToFile:file];
    return unit;
}

#pragma mark -
#pragma mark Private methods

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

- (ECCodeIndex *)indexForLanguage:(NSString *)language
{
    return [self.indexesByLanguage objectForKey:language];
}

- (ECCodeIndex *)indexForExtension:(NSString *)extension
{
    return [self.indexesByExtension objectForKey:extension];
}

- (void)addObserversForUnitsToFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    for (ECCodeUnit *unit in [self.codeUnitPointers allValues])
        [unit addObserversToFile:file];
}

- (void)removeObserversForUnitsFromFile:(NSObject<ECCodeIndexingFileObserving> *)file
{
    for (ECCodeUnit *unit in [self.codeUnitPointers allValues])
        [unit removeObserversFromFile:file];
}

#pragma mark -
#pragma mark Categories

- (void)removeTranslationUnitForURL:(NSURL *)url
{
    [self.codeUnitPointers removeObjectForKey:url];
}

@end
