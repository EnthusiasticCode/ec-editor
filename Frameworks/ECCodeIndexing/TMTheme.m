//
//  TMTheme.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMTheme.h"

static NSString * const _themeFileExtension = @"tmTheme";
static NSString * const _themeNameKey = @"name";

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

@end
