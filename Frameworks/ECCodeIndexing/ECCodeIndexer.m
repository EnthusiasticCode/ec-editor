//
//  ECCodeIndexer.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndexer.h"
#import "ECCodeIndexingFile.h"
#import "ECCodeIndexerPlugin.h"
#import <ECAdditions/NSURL+ECAdditions.h>
#import <objc/runtime.h>
// TODO: plugins are hardcoded for now
#import "ECClangCodeIndexer.h"

@interface ECCodeIndexer ()
@property (nonatomic, copy) NSDictionary *pluginsByLanguage;
@property (nonatomic, copy) NSDictionary *pluginsByExtension;
@property (nonatomic, copy) NSDictionary *languageToExtensionMappingDictionary;
@property (nonatomic, copy) NSDictionary *extensionToLanguageMappingDictionary;
@property (nonatomic, copy) NSSet *methodsToForwardToPlugins;
@property (nonatomic, retain) NSMutableDictionary *files;
- (BOOL)setupPluginDictionaries;
- (BOOL)setupPluginMethodForwarding;
- (BOOL)loadPlugins;
- (id<ECCodeIndexerPlugin>)pluginForLanguage:(NSString *)language;
- (id<ECCodeIndexerPlugin>)pluginForExtension:(NSString *)extension;
- (id<ECCodeIndexerPlugin>)pluginForFile:(ECCodeIndexingFile *)file;
- (void)forwardInvocationToPlugin:(NSInvocation *)invocation;
@end

@implementation ECCodeIndexer

@synthesize pluginsByLanguage = _pluginsByLanguage;
@synthesize pluginsByExtension = _pluginsByExtension;
@synthesize languageToExtensionMappingDictionary = _languageToExtensionMappingDictionary;
@synthesize extensionToLanguageMappingDictionary = _extensionToLanguageMappingDictionary;
@synthesize methodsToForwardToPlugins = _methodsToForwardToPlugins;
@synthesize files = _files;

- (NSSet *)loadedFiles
{
    return [NSSet setWithArray:[self.files allKeys]];
}

- (void)dealloc
{
    self.pluginsByLanguage = nil;
    self.pluginsByExtension = nil;
    self.languageToExtensionMappingDictionary = nil;
    self.extensionToLanguageMappingDictionary = nil;
    self.methodsToForwardToPlugins = nil;
    self.files = nil;
    [super dealloc];
}

- (BOOL)setupPluginDictionaries
{
    // TODO: plugin architecture or something like that
    // TODO: implement some priority system for subclass loading
    NSArray *pluginClasses = [NSArray arrayWithObjects:[ECClangCodeIndexer class], nil];
    id<ECCodeIndexer> plugin;
    NSMutableDictionary *pluginsByLanguage = [NSMutableDictionary dictionary];
    NSMutableDictionary *pluginsByExtension = [NSMutableDictionary dictionary];
    NSMutableDictionary *languageToExtensionMappingDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *extensionToLanguageMappingDictionary = [NSMutableDictionary dictionary];
    for (Class pluginClass in pluginClasses)
    {
        if (![pluginClass conformsToProtocol:@protocol(ECCodeIndexer)])
            continue;
        plugin = [[pluginClass alloc] init];
        NSDictionary *pluginLanguageToExtensionMappingDictionary = [plugin languageToExtensionMappingDictionary];
        for (NSString *language in [pluginLanguageToExtensionMappingDictionary allKeys])
        {
            if ([languageToExtensionMappingDictionary objectForKey:language])
                continue;
            [pluginsByLanguage setObject:plugin forKey:language];
            [languageToExtensionMappingDictionary setObject:[pluginLanguageToExtensionMappingDictionary objectForKey:language] forKey:language];
        }
        NSDictionary *pluginExtensionToLanguageMappingDictionary = [plugin extensionToLanguageMappingDictionary];
        for (NSString *extension in [pluginExtensionToLanguageMappingDictionary allKeys])
        {
            if ([extensionToLanguageMappingDictionary objectForKey:extension])
                continue;
            [pluginsByExtension setObject:plugin forKey:extension];
            [extensionToLanguageMappingDictionary setObject:[pluginExtensionToLanguageMappingDictionary objectForKey:extension] forKey:extension];
        }
        [plugin release];
    }
    self.pluginsByLanguage = pluginsByLanguage;
    self.pluginsByExtension = pluginsByExtension;
    self.languageToExtensionMappingDictionary = languageToExtensionMappingDictionary;
    self.extensionToLanguageMappingDictionary = extensionToLanguageMappingDictionary;
    return YES;
}

- (BOOL)setupPluginMethodForwarding
{
    // get all optional instance methods from ECCodeIndexerPluginForwarding protocol
    struct objc_method_description *methodsInProtocol;
    unsigned methodCount;
    methodsInProtocol = protocol_copyMethodDescriptionList(@protocol(ECCodeIndexerPluginForwarding), NO, YES, &methodCount);
    NSMutableSet *methodsToForwardToPlugins = [NSMutableSet setWithCapacity:methodCount];
    for (unsigned i = 1; i < methodCount; i++)
    {
        [methodsToForwardToPlugins addObject:NSStringFromSelector(methodsInProtocol[i].name)];
    }
    free(methodsInProtocol);
    self.methodsToForwardToPlugins = methodsToForwardToPlugins;
    return YES;
}

- (BOOL)loadPlugins
{
    if (![self setupPluginDictionaries])
        return NO;
    if (![self setupPluginMethodForwarding])
        return NO;
    return YES;
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    if (![self loadPlugins])
    {
        [self release];
        return nil;
    }
    self.files = [NSMutableDictionary dictionary];
    return self;
}

- (id<ECCodeIndexerPlugin>)pluginForLanguage:(NSString *)language
{
    return [self.pluginsByLanguage objectForKey:language];
}

- (id<ECCodeIndexerPlugin>)pluginForExtension:(NSString *)extension
{
    return [self.pluginsByExtension objectForKey:extension];
}

- (id<ECCodeIndexerPlugin>)pluginForFile:(ECCodeIndexingFile *)file
{
    if (file.language)
        return [self pluginForLanguage:file.language];
    return [self pluginForExtension:[file.URL pathExtension]];
}

- (BOOL)loadFile:(NSURL *)fileURL
{
    if (![fileURL isFileURLAndExists])
        return NO;
    ECCodeIndexingFile *file = [ECCodeIndexingFile fileWithURL:fileURL];
    [self.files setObject:file forKey:fileURL];
    [[self pluginForExtension:[fileURL pathExtension]] loadFile:file];
    return YES;
}

- (BOOL)unloadFile:(NSURL *)fileURL
{
    ECCodeIndexingFile *file = [self.files objectForKey:fileURL];
    [[self pluginForFile:file] unloadFile:file];
    [self.files removeObjectForKey:fileURL];
    return YES;
}

- (BOOL)setLanguage:(NSString *)language forFile:(NSURL *)fileURL
{
    ECCodeIndexingFile *file = [self.files objectForKey:fileURL];
    if (!file)
        return NO;
    if ([file.language isEqualToString:language])
        return YES;
    [[self pluginForFile:file] unloadFile:file];
    file.language = language;
    [[self pluginForFile:file] loadFile:file];
    return YES;
}

- (BOOL)setBuffer:(NSString *)buffer forFile:(NSURL *)fileURL
{
    ECCodeIndexingFile *file = [self.files objectForKey:fileURL];
    if (!file)
        return NO;
    if ([file.buffer isEqualToString:buffer])
        return YES;
    file.buffer = buffer;
    file.dirty = YES;
    return YES;
}

- (void)forwardInvocationToPlugin:(NSInvocation *)invocation
{
    // arg0 = self, arg1 = _cmd
    // arg2 = fileURL in all methods ECCodeIndexer should forward to the plugins
    // get the fileURL, substitute it for the corresponding file, then forward the invocation to the right plugin
    NSURL *fileURL;
    [invocation getArgument:&fileURL atIndex:2];
    ECCodeIndexingFile *file = [self.files objectForKey:fileURL];
    [invocation setArgument:&file atIndex:2];
    id<ECCodeIndexerPlugin> plugin = [self pluginForFile:file];
    if (![plugin respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:nil];
    [invocation invokeWithTarget:plugin];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (![self.methodsToForwardToPlugins containsObject:NSStringFromSelector([invocation selector])])
        [super forwardInvocation:invocation];
    [self forwardInvocationToPlugin:invocation];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([self.methodsToForwardToPlugins containsObject:NSStringFromSelector(selector)])
        return YES;
    if ([[self class] instancesRespondToSelector:selector])
        return YES;
    return [super respondsToSelector:selector];
}

@end
