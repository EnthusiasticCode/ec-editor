//
//  TMTheme.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMTheme.h"
#import <CoreText/CoreText.h>
#import "UIColor+HexColor.h"
#import "TextRenderer.h"
#import "TMScope.h"

static NSString * const _themeFileExtension = @"tmTheme";
static NSString * const _themeNameKey = @"name";
static NSString * const _themeSettingsKey = @"settings";
static NSString * const _themeSettingsNameKey = @"name";
static NSString * const _themeSettingsScopeKey = @"scope";

static CTFontRef _defaultFont = NULL;
static CTFontRef _defaultItalicFont = NULL;
static CTFontRef _defaultBoldFont = NULL;
static NSDictionary *_defaultAttributes = nil;

@interface TMTheme ()

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *settings;

@end

@implementation TMTheme {
    NSCache *_scopeAttribuesCache;
}

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
    NSMutableDictionary *themeSettings = [[NSMutableDictionary alloc] initWithCapacity:[[plist objectForKey:_themeSettingsKey] count]];
    for (NSDictionary *plistSetting in [plist objectForKey:_themeSettingsKey])
    {
        // TODO manage default settings for background, caret
        NSString *settingScopes = [plistSetting objectForKey:_themeSettingsScopeKey];
        if (!settingScopes)
            continue;
        
        NSMutableDictionary *styleSettings = [[NSMutableDictionary alloc] initWithCapacity:[[plistSetting objectForKey:_themeSettingsKey] count]];
        
        // Pre-map settings with Core Text attributes
        [[plistSetting objectForKey:_themeSettingsKey] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            ECASSERT([value isKindOfClass:[NSString class]]);
            
            if ([key isEqualToString:@"fontStyle"]) { // italic, bold, underline
                if ([value isEqualToString:@"italic"] && _defaultItalicFont) {
                    [styleSettings setObject:(__bridge id)_defaultItalicFont forKey:(__bridge id)kCTFontAttributeName];
                }
                else if ([value isEqualToString:@"bold"] && _defaultBoldFont) {
                    [styleSettings setObject:(__bridge id)_defaultBoldFont forKey:(__bridge id)kCTFontAttributeName];
                }
                else if ([value isEqualToString:@"underline"]) {
                    [styleSettings setObject:[NSNumber numberWithUnsignedInt:kCTUnderlineStyleSingle] forKey:(__bridge id)kCTUnderlineStyleAttributeName];
                }
            }
            else if ([key isEqualToString:@"foreground"]) {
                [styleSettings setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
            }
            else if ([key isEqualToString:@"background"]) {
                [styleSettings setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:TextRendererRunBackgroundColorAttributeName];
            }
            else {
                [styleSettings setObject:value forKey:key];
            }
        }];
        
        [themeSettings setObject:styleSettings forKey:settingScopes];
    }
    _settings = themeSettings;
    _scopeAttribuesCache = [NSCache new];

    return self;
}

- (NSDictionary *)attributesForScope:(TMScope *)scope
{
    NSMutableDictionary *resultAttributes = nil;
    if ((resultAttributes = [_scopeAttribuesCache objectForKey:scope.qualifiedIdentifier]))
        return resultAttributes;
    
    NSMutableDictionary *scoredAttributes = [NSMutableDictionary new];
    [_settings enumerateKeysAndObjectsUsingBlock:^(NSString *settingScope, NSDictionary *attributes, BOOL *stop) {
        float score = [scope scoreForScopeSelector:settingScope];
        if (score > 0)
            [scoredAttributes setObject:attributes forKey:[NSNumber numberWithFloat:score]];
    }];
    
    resultAttributes = [NSMutableDictionary dictionaryWithCapacity:[scoredAttributes count]];
    for (NSNumber *score in [[scoredAttributes allKeys] sortedArrayUsingSelector:@selector(compare:)])
    {
        [resultAttributes addEntriesFromDictionary:[scoredAttributes objectForKey:score]];
    }
    
    [_scopeAttribuesCache setObject:resultAttributes forKey:scope.qualifiedIdentifier];
    return resultAttributes;
}

@end
