//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <objc/runtime.h>
#import "ECCodeIndex.h"
#import "ECCodeIndex(Private).h"
#import "ECCodeIndexPlugin.h"
#import "ECCodeUnit.h"
#import "ECCodeUnit(Private).h"

#import "ECClangCodeIndex.h"

@interface ECCodeIndex ()
@property (nonatomic, copy) NSDictionary *pluginsByLanguage;
@property (nonatomic, copy) NSDictionary *languageToExtensionMap;
@property (nonatomic, copy) NSDictionary *extensionToLanguageMap;
@property (nonatomic, strong) NSMutableDictionary *codeUnitPointers;
@property (nonatomic, strong) NSMutableDictionary *filePointers;
- (BOOL)loadPlugins;
- (id<ECCodeIndexPlugin>)pluginForLanguage:(NSString *)language;
- (void)addObserversForUnitsToFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject;
- (void)removeObserversForUnitsFromFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject;
@end

#pragma mark -

@implementation ECCodeIndex

@synthesize pluginsByLanguage = _pluginsByLanguage;
@synthesize languageToExtensionMap = _languageToExtensionMap;
@synthesize extensionToLanguageMap = _extensionToLanguageMap;
@synthesize codeUnitPointers = _codeUnitPointers;
@synthesize filePointers = _filePointers;

#pragma mark -
#pragma mark Initialization and deallocation


- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    if (![self loadPlugins])
    {
        return nil;
    }
    self.codeUnitPointers = [NSMutableDictionary dictionary];
    self.filePointers = [NSMutableDictionary dictionary];
    return self;
}

#pragma mark -
#pragma mark Public Methods

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

- (BOOL)addObserversToFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject
{
    if ([self.filePointers objectForKey:fileObject.file])
        return NO;
    [self addObserversForUnitsToFile:fileObject];
    [fileObject addObserver:self forKeyPath:@"file" options:NSKeyValueObservingOptionPrior context:NULL];
    return YES;
}

- (void)removeObserversFromFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject
{
    [self removeObserversForUnitsFromFile:fileObject];
    [fileObject removeObserver:self forKeyPath:@"file"];
    [self.filePointers removeObjectForKey:fileObject.file];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL isPriorToChange = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPriorToChange)
        [self removeObserversForUnitsFromFile:object];
    NSString *newFile = [change objectForKey:NSKeyValueChangeNewKey];
    if (newFile)
        [self addObserversForUnitsToFile:object];
}

- (ECCodeUnit *)unitForFile:(NSString *)file
{
    return [self unitForFile:file withLanguage:nil];
}

- (ECCodeUnit *)unitForFile:(NSString *)file withLanguage:(NSString *)language
{
    if (!file)
        return nil;
    if (!language)
        language = [self languageForExtension:[file pathExtension]];
    ECCodeUnit *unit;
    unit = [[self.codeUnitPointers objectForKey:file] nonretainedObjectValue];
    if (unit)
    {
        if ([unit.language isEqual:language])
            return unit;
        else
            return nil;
    }
    unit = [ECCodeUnit unitWithIndex:self file:file language:language plugin:[[self pluginForLanguage:language] unitPluginForFile:file withLanguage:language]];
    if (!unit)
        return nil;
    [self.codeUnitPointers setObject:[NSValue valueWithNonretainedObject:unit] forKey:file];
    for (NSObject<ECCodeIndexingFileObserving> *fileObject in self.filePointers)
        [unit addObserversToFile:fileObject];
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
    NSArray *pluginClasses = [NSArray arrayWithObjects:[ECClangCodeIndex class], nil];
    id<ECCodeIndexPlugin> plugin;
    NSMutableDictionary *pluginsByLanguage = [NSMutableDictionary dictionary];
    NSMutableDictionary *languageToExtensionMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *extensionToLanguageMap = [NSMutableDictionary dictionary];
    for (Class pluginClass in pluginClasses)
    {
        plugin = [[pluginClass alloc] init];
        NSDictionary *pluginLanguageToExtensionMappingDictionary = [plugin languageToExtensionMap];
        for (NSString *language in [pluginLanguageToExtensionMappingDictionary allKeys])
        {
            if ([languageToExtensionMap objectForKey:language])
                continue;
            [pluginsByLanguage setObject:plugin forKey:language];
            [languageToExtensionMap setObject:[pluginLanguageToExtensionMappingDictionary objectForKey:language] forKey:language];
        }
        NSDictionary *pluginExtensionToLanguageMappingDictionary = [plugin extensionToLanguageMap];
        for (NSString *extension in [pluginExtensionToLanguageMappingDictionary allKeys])
        {
            if ([extensionToLanguageMap objectForKey:extension])
                continue;
            [extensionToLanguageMap setObject:[pluginExtensionToLanguageMappingDictionary objectForKey:extension] forKey:extension];
        }
    }
    self.pluginsByLanguage = pluginsByLanguage;
    self.languageToExtensionMap = languageToExtensionMap;
    self.extensionToLanguageMap = extensionToLanguageMap;
    return YES;
}

- (ECCodeIndex *)pluginForLanguage:(NSString *)language
{
    return [self.pluginsByLanguage objectForKey:language];
}

- (void)addObserversForUnitsToFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject
{
    for (ECCodeUnit *unit in [self.codeUnitPointers allValues])
        [unit addObserversToFile:fileObject];
}

- (void)removeObserversForUnitsFromFile:(NSObject<ECCodeIndexingFileObserving> *)fileObject
{
    for (ECCodeUnit *unit in [self.codeUnitPointers allValues])
        [unit removeObserversFromFile:fileObject];
}

#pragma mark -
#pragma mark Categories

- (void)removeTranslationUnitForFile:(NSString *)file
{
    [self.codeUnitPointers removeObjectForKey:file];
}

@end
