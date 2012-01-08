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
#import <ECUIKit/ECTextRenderer.h>

static NSString * const _themeFileExtension = @"tmTheme";
static NSString * const _themeNameKey = @"name";
static NSString * const _themeSettingsKey = @"settings";
static NSString * const _themeSettingsNameKey = @"name";
static NSString * const _themeSettingsScopeKey = @"scope";

static CTFontRef _defaultFont = NULL;
static CTFontRef _defaultItalicFont = NULL;
static CTFontRef _defaultBoldFont = NULL;
static NSDictionary *_defaultAttributes = nil;

@interface TMTheme () {
    NSArray *_settingsOrderedScopes;
}

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

+ (NSDictionary *)defaultAttributes
{
    // TODO load from application preference plist
    if (!_defaultFont) {
        _defaultFont = CTFontCreateWithName((__bridge CFStringRef)@"Inconsolata-dz", 14, NULL);
        _defaultItalicFont = CTFontCreateCopyWithSymbolicTraits(_defaultFont, 0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
        _defaultBoldFont = CTFontCreateCopyWithSymbolicTraits(_defaultFont, 0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
    }
    if (!_defaultAttributes)
    {
        _defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                              (__bridge id)_defaultFont, kCTFontAttributeName,
                              [NSNumber numberWithInt:0], kCTLigatureAttributeName, nil];
    }
    return _defaultAttributes;
}

#pragma mark - Properties

@synthesize fileURL = _fileURL, name = _name, settings = _settings;

- (id)initWithFileURL:(NSURL *)fileURL
{
    // Initialize default attributes
    [[self class] defaultAttributes];
    
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
            
            if ([key isEqualToString:@"fontStyle"]) { // italic, bold, underline
                if ([value isEqualToString:@"italic"] && _defaultItalicFont) {
                    [setting setObject:(__bridge id)_defaultItalicFont forKey:(__bridge id)kCTFontAttributeName];
                }
                else if ([value isEqualToString:@"bold"] && _defaultBoldFont) {
                    [setting setObject:(__bridge id)_defaultBoldFont forKey:(__bridge id)kCTFontAttributeName];
                }
                else if ([value isEqualToString:@"underline"]) {
                    [setting setObject:[NSNumber numberWithUnsignedInt:kCTUnderlineStyleSingle] forKey:(__bridge id)kCTUnderlineStyleAttributeName];
                }
            }
            else if ([key isEqualToString:@"foreground"]) {
                [setting setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
            }
            else if ([key isEqualToString:@"background"]) {
                [setting setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:ECTextRendererRunBackgroundColorAttributeName];
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
    _settingsOrderedScopes = [[_settings allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSInteger diff = [[obj2 componentsSeparatedByString:@"."] count] - [[obj1 componentsSeparatedByString:@"."] count];
        if (diff > 0)
            return NSOrderedDescending;
        else if (diff < 0)
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    return self;
}

- (NSDictionary *)attributesForScopeIdentifier:(NSString *)scopeIdentifier
{
    NSDictionary *attributes = [self.settings objectForKey:scopeIdentifier];
    if (attributes)
        return attributes;
    
    for (NSUInteger i = [scopeIdentifier length] - 1; i != 0; --i)
    {
        if ([scopeIdentifier characterAtIndex:i] == L'.')
        {
            attributes = [self.settings objectForKey:[scopeIdentifier substringToIndex:i]];
            if (attributes)
                return attributes;
        }
    }
    
    return nil;
}

@end
