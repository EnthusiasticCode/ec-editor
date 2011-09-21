//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"

static NSMutableDictionary *_extensionClassesByLanguage;
static NSMutableOrderedSet *_extensionClasses;

@interface ECCodeIndex ()
@property (nonatomic, strong, readonly) NSMutableDictionary *extensionsByExtensionClass;
- (ECCodeIndex *)extensionForClass:(Class)extensionClass;
@end

@implementation ECCodeIndex

@synthesize extensionsByExtensionClass = _extensionsByExtensionClass;

- (NSMutableDictionary *)extensionsByExtensionClass
{
    if (!_extensionsByExtensionClass)
        _extensionsByExtensionClass = [[NSMutableDictionary alloc] init];
    return _extensionsByExtensionClass;
}

+ (void)registerExtension:(Class)extensionClass
{
    ECASSERT([extensionClass isSubclassOfClass:self]);
    if (!_extensionClassesByLanguage)
        _extensionClassesByLanguage = [[NSMutableDictionary alloc] init];
    for (NSString *language in [extensionClass supportedLanguages])
    {
        NSMutableOrderedSet *registeredExtensionsForLanguage = [_extensionClassesByLanguage objectForKey:language];
        if (!registeredExtensionsForLanguage)
        {
            registeredExtensionsForLanguage = [[NSMutableOrderedSet alloc] init];
            [_extensionClassesByLanguage setObject:registeredExtensionsForLanguage forKey:language];
        }
        [registeredExtensionsForLanguage addObject:extensionClass];
    }
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableOrderedSet alloc] init];
    [_extensionClasses addObject:extensionClass];
}

+ (NSArray *)supportedLanguages
{
    NSLog(@"%@", _extensionClassesByLanguage);
    return [_extensionClassesByLanguage allKeys];
}

+ (float)supportForFile:(NSURL *)fileURL
{
    float support = 0.0;
    for (Class extensionClass in _extensionClasses)
        support = MAX([extensionClass supportForFile:fileURL], support);
    return support;
}

- (ECCodeUnit *)unitWithFileURL:(NSURL *)fileURL
{
    float winningSupport = 0.0;
    Class winningExtensionClass;
    for (Class extensionClass in _extensionClasses)
    {
        float support = [extensionClass supportForFile:fileURL];
        if (support <= winningSupport)
            continue;
        winningSupport = support;
        winningExtensionClass = extensionClass;
    }
    if (winningSupport == 0.0)
        return nil;
    ECCodeIndex *extension = [self extensionForClass:winningExtensionClass];
    return [extension unitWithFileURL:fileURL];
}

- (ECCodeUnit *)unitWithFileURL:(NSURL *)fileURL withLanguage:(NSString *)language
{
    float winningSupport = 0.0;
    Class winningExtensionClass;
    for (Class extensionClass in [_extensionClassesByLanguage objectForKey:language])
    {
        float support = [extensionClass supportForFile:fileURL];
        if (support <= winningSupport)
            continue;
        winningSupport = support;
        winningExtensionClass = extensionClass;
    }
    if (winningSupport == 0.0)
        return nil;
    ECCodeIndex *extension = [self extensionForClass:winningExtensionClass];
    return [extension unitWithFileURL:fileURL withLanguage:language];
}

- (ECCodeIndex *)extensionForClass:(Class)extensionClass
{
    NSString *className = NSStringFromClass(extensionClass);
    ECCodeIndex *extension = [self.extensionsByExtensionClass objectForKey:className];
    if (!extension)
    {
        extension = [[extensionClass alloc] init];
        [self.extensionsByExtensionClass setObject:extension forKey:className];
    }
    return extension;
}
@end
