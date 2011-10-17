//
//  TMTheme.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMTheme.h"
#import "NSString+ECCodeScopes.h"

static NSString * const _themeFileExtension = @"tmTheme";
static NSString * const _themeNameKey = @"name";
static NSString * const _themeSettingsKey = @"settings";
static NSString * const _themeSettingsScopeKey = @"scope";
static NSString * const _themeSettingsSettingsKey = @"settings";

static NSURL *_themeDirectory;
static NSDictionary *_themeFileURLs;

@interface TMTheme ()
+ (void)_indexThemes;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *plist;
- (id)initWithFileURL:(NSURL *)fileURL;
@end

@implementation TMTheme

#pragma mark - Class methods

+ (NSURL *)themeDirectory
{
    return _themeDirectory;
}

+ (void)setThemeDirectory:(NSURL *)themeDirectory
{
    if (themeDirectory == _themeDirectory)
        return;
    _themeDirectory = themeDirectory;
    [self _indexThemes];
}

+ (NSArray *)themeNames
{
    return [_themeFileURLs allKeys];
}

+ (TMTheme *)themeWithName:(NSString *)name
{
    return [[self alloc] initWithFileURL:[_themeFileURLs objectForKey:name]];
}

+ (void)_indexThemes
{
    NSMutableDictionary *themeFileURLs = [NSMutableDictionary dictionary];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:[self themeDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
        TMTheme *theme = [[self alloc] initWithFileURL:fileURL];
        if (!theme)
            continue;
        [themeFileURLs setObject:fileURL forKey:theme.name];
    }
    _themeFileURLs = [themeFileURLs copy];
}

#pragma mark - Properties

@synthesize fileURL = _fileURL;
@synthesize name = _name;
@synthesize plist = _plist;

- (id)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (!self)
        return nil;
    if (![[fileURL pathExtension] isEqualToString:_themeFileExtension])
        return nil;
    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    NSString *name = [plist objectForKey:_themeNameKey];
    if (!name)
        return nil;
    self.fileURL = fileURL;
    self.name = name;
    self.plist = plist;
    return self;
}

- (NSDictionary *)attributesForScopeStack:(NSArray *)scopeStack
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    for (NSString *scope in scopeStack)
    {
        for (NSDictionary *settings in [self.plist objectForKey:_themeSettingsKey])
        {
            NSString *settingScope = [settings objectForKey:_themeSettingsScopeKey];
            if (settingScope && ![scope containsScope:settingScope])
                continue;
            [[settings objectForKey:_themeSettingsSettingsKey] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [attributes setObject:obj forKey:key];
            }];
        }
    }
    return [attributes copy];
}

@end
