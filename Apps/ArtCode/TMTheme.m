//
//  TMTheme.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMTheme.h"
#import "UIColor+HexColor.h"
#import "NSString+TextMateScopeSelectorMatching.h"

static NSString * const _themeFileExtension = @"tmTheme";
static NSString * const _themeNameKey = @"name";
static NSString * const _themeSettingsKey = @"settings";
static NSString * const _themeSettingsNameKey = @"name";
static NSString * const _themeSettingsScopeKey = @"scope";

NSString * const TMThemeBackgroundColorEnvironmentAttributeKey = @"background";
NSString * const TMThemeCaretColorEnvironmentAttributeKey = @"caret";
NSString * const TMThemeForegroundColorEnvironmentAttributeKey = @"foreground";
NSString * const TMThemeLineHighlightColorEnvironmentAttributeKey = @"lineHighlight";
NSString * const TMThemeSelectionColorEnvironmentAttributeKey = @"selection";

static CTFontRef _sharedFont = NULL;
static CTFontRef _sharedItalicFont = NULL;
static CTFontRef _sharedBoldFont = NULL;
static TMTheme *_currentTheme = nil;
static NSDictionary *_sharedAttributes = nil;


@interface TMTheme ()

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *settings;

@end

@implementation TMTheme {
  NSCache *_scopeAttribuesCache;
  NSDictionary *_environmentAttributes;
  NSDictionary *_commonAttributes;
}

#pragma mark - Properties

@synthesize fileURL = _fileURL, name = _name, settings = _settings;

- (NSDictionary *)environmentAttributes
{
  return _environmentAttributes;
}

- (NSDictionary *)commonAttributes
{
  if ([_environmentAttributes objectForKey:TMThemeForegroundColorEnvironmentAttributeKey] == nil)
    return [[self class] sharedAttributes];
  // TODO may need not to cache if shared font is changed
  if (!_commonAttributes)
  {
    NSMutableDictionary *common = [NSMutableDictionary dictionaryWithDictionary:[[self class] sharedAttributes]];
    [common setObject:(__bridge id)[[_environmentAttributes objectForKey:TMThemeForegroundColorEnvironmentAttributeKey] CGColor] forKey:(__bridge id)kCTForegroundColorAttributeName];
    _commonAttributes = common;
  }
  return _commonAttributes;
}

#pragma mark - Public methods

- (id)initWithFileURL:(NSURL *)fileURL
{
  // Initialize default attributes
  [[self class] sharedAttributes];
  
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
  NSMutableDictionary *themeSettings = [[NSMutableDictionary alloc] initWithCapacity:[(NSDictionary *)[plist objectForKey:_themeSettingsKey] count]];
  NSMutableDictionary *environmentAttributes = [NSMutableDictionary new];
  for (NSDictionary *plistSetting in [plist objectForKey:_themeSettingsKey])
  {
    // TODO manage default settings for background, caret
    NSString *settingScopes = [plistSetting objectForKey:_themeSettingsScopeKey];
    if (!settingScopes)
    {
      // Load environment styles
      [[plistSetting objectForKey:_themeSettingsKey] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        UIColor *color = [UIColor colorWithHexString:value];
        if (color)
          [environmentAttributes setObject:color forKey:key];
        else
          [environmentAttributes setObject:value forKey:key];
      }];
      _environmentAttributes = [environmentAttributes copy];
      continue;
    }
    
    NSMutableDictionary *styleSettings = [[NSMutableDictionary alloc] initWithCapacity:[(NSDictionary *)[plistSetting objectForKey:_themeSettingsKey] count]];
    
    // Pre-map settings with Core Text attributes
    [[plistSetting objectForKey:_themeSettingsKey] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
      ASSERT([value isKindOfClass:[NSString class]]);
      
      if ([key isEqualToString:@"fontStyle"]) { // italic, bold, underline
        if ([value isEqualToString:@"italic"] && _sharedItalicFont) {
          [styleSettings setObject:(__bridge id)_sharedItalicFont forKey:(__bridge id)kCTFontAttributeName];
        }
        else if ([value isEqualToString:@"bold"] && _sharedBoldFont) {
          [styleSettings setObject:(__bridge id)_sharedBoldFont forKey:(__bridge id)kCTFontAttributeName];
        }
        else if ([value isEqualToString:@"underline"]) {
          [styleSettings setObject:[NSNumber numberWithUnsignedInt:kCTUnderlineStyleSingle] forKey:(__bridge id)kCTUnderlineStyleAttributeName];
        }
      }
      else if ([key isEqualToString:@"foreground"]) {
        [styleSettings setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
      }
      else if ([key isEqualToString:@"background"]) {
// TODO: adding this couples TMTheme with TextRenderer, a bit excessive
        //[styleSettings setObject:(__bridge id)[UIColor colorWithHexString:value].CGColor forKey:TextRendererRunBackgroundColorAttributeName];
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

- (NSDictionary *)attributesForQualifiedIdentifier:(NSString *)qualifiedIdentifier
{
  NSDictionary *resultAttributes = nil;
  resultAttributes = [_scopeAttribuesCache objectForKey:qualifiedIdentifier];
  if (resultAttributes) {
    return resultAttributes;
  }
  
  __block NSDictionary *scopeAttributes = nil;
  __block float maxScore = 0;
  [_settings enumerateKeysAndObjectsUsingBlock:^(NSString *settingScope, NSDictionary *attributes, BOOL *stop) {
    float score = [qualifiedIdentifier scoreForScopeSelector:settingScope];
    if (score > maxScore)
    {
      scopeAttributes = attributes;
      maxScore = score;
    }
  }];
  
  NSMutableDictionary *newResultAttributes = [[NSMutableDictionary alloc] init];
  if (self.commonAttributes) {
    [newResultAttributes addEntriesFromDictionary:self.commonAttributes];
  }
  if (scopeAttributes) {
    [newResultAttributes addEntriesFromDictionary:scopeAttributes];
  }
  
  resultAttributes = [newResultAttributes copy];
  
  [_scopeAttribuesCache setObject:resultAttributes forKey:qualifiedIdentifier];

  return resultAttributes;
}

#pragma mark - Class methods

+ (TMTheme *)themeWithName:(NSString *)name bundle:(NSBundle *)bundle
{
  if (bundle == nil)
    bundle = [NSBundle bundleForClass:self];
  
  return [[self alloc] initWithFileURL:[bundle URLForResource:name withExtension:_themeFileExtension]];
}

+ (TMTheme *)defaultTheme {
  return [TMTheme themeWithName:@"Mac Classic" bundle:NSBundle.mainBundle];
}

+ (TMTheme *)currentTheme {
  if (!_currentTheme) {
    _currentTheme = [self defaultTheme];
  }
  return _currentTheme;
}

+ (void)setCurrentTheme:(TMTheme *)theme {
  if (theme == _currentTheme) {
    return;
  }
  _currentTheme = theme;
}

+ (NSDictionary *)sharedAttributes
{
  // TODO load from application preference plist
  if (!_sharedFont)
    [self setSharedFontName:@"Inconsolata-dz" size:14];
  
  if (!_sharedAttributes)
  {
    _sharedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                         (__bridge id)_sharedFont, kCTFontAttributeName,
                         [NSNumber numberWithInt:0], kCTLigatureAttributeName, nil];
  }
  return _sharedAttributes;
}

+ (void)setSharedFontName:(NSString *)fontName size:(CGFloat)pointSize
{
  _sharedFont = CTFontCreateWithName((__bridge CFStringRef)fontName, pointSize, NULL);
  _sharedItalicFont = CTFontCreateCopyWithSymbolicTraits(_sharedFont, 0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
  _sharedBoldFont = CTFontCreateCopyWithSymbolicTraits(_sharedFont, 0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
}

@end
