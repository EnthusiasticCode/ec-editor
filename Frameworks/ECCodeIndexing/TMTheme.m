//
//  TMTheme.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMTheme.h"
#import <CoreText/CoreText.h>
#import "UIColor+HexColor.h"

NSString * const TMThemeBackgroundColorAttributeName = @"BackgroundColor";
NSString * const TMThemeFontStyleAttributeName = @"FontStyle";

static NSString * const _themeFileExtension = @"tmTheme";
static NSString * const _themeNameKey = @"name";
static NSString * const _themeSettingsKey = @"settings";
static NSString * const _themeSettingsNameKey = @"name";
static NSString * const _themeSettingsScopeKey = @"scope";


@interface TMTheme ()

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *settings;

@end

@implementation TMTheme

#pragma mark - Class methods

+ (TMTheme *)themeWithName:(NSString *)name bundle:(NSBundle *)bundle
{
    if (bundle == nil)
        bundle = [NSBundle mainBundle];
    
    return [[self alloc] initWithFileURL:[bundle URLForResource:name withExtension:_themeFileExtension]];
}

#pragma mark - Properties

@synthesize fileURL = _fileURL;
@synthesize name = _name;
@synthesize settings = _settings;

- (id)initWithFileURL:(NSURL *)fileURL
{
    if (!(self = [super init]))
        return nil;
    
    if (![[fileURL pathExtension] isEqualToString:_themeFileExtension])
        return nil;
    
    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    
    NSString *name = [plist objectForKey:_themeNameKey];
    if (!name)
        return nil;
    
    _fileURL = fileURL;
    _name = name;
    
    // Preprocess settings
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithCapacity:[[plist objectForKey:_themeSettingsKey] count]];
    for (NSDictionary *plistSetting in [plist objectForKey:_themeSettingsKey])
    {
        NSString *settingScope = [plistSetting objectForKey:_themeSettingsScopeKey];
        if (!settingScope)
            continue;
        
        NSMutableDictionary *setting = [[NSMutableDictionary alloc] initWithCapacity:[[plistSetting objectForKey:_themeSettingsKey] count]];
        
        // Pre-map settings with Core Text attributes
        [[plistSetting objectForKey:_themeSettingsKey] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            ECASSERT([value isKindOfClass:[NSString class]]);
            
            if ([key isEqualToString:@"fontStyle"]) {
                [setting setObject:value forKey:TMThemeFontStyleAttributeName];
            }
            else if ([key isEqualToString:@"foreground"]) {
                [setting setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
            }
            else {
                [setting setObject:value forKey:key];
            }
        }];
        
        ECASSERT([settings objectForKey:settingScope] == nil && "Scope should be unique");
        
        // Setting's scope can have multiple scopes separated by a comma
        for (NSString *singleSettingScope in [settingScope componentsSeparatedByString:@","])
        {
            if (singleSettingScope.length == 0)
                continue;
            
            [settings setObject:setting forKey:[singleSettingScope stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
    }
    _settings = settings;
    
    return self;
}

- (NSDictionary *)attributesForScopeStack:(NSArray *)scopesStack
{
    // TODO premap every key of the settings with CT attributes
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    for (NSString *scope in scopesStack)
    {
        [self.settings enumerateKeysAndObjectsUsingBlock:^(NSString *settingScope, NSDictionary *settingAttributes, BOOL *stop) {
            if (![scope hasPrefix:settingScope])
                return;
            [attributes addEntriesFromDictionary:settingAttributes];
        }];
    }
    return attributes;
}

@end
