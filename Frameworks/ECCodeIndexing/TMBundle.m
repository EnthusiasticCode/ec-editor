//
//  TMBundle.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMBundle.h"

static NSString * const _bundleExtension = @"tmbundle";
static NSString * const _bundleInfoPlist = @"info.plist";
static NSString * const _bundleNameKey = @"name";

static NSURL *_bundleDirectory;
static NSDictionary *_bundleURLs;

@interface TMBundle ()
+ (void)_indexBundles;
- (id)initWithBundleURL:(NSURL *)bundleURL;
@property (nonatomic, strong) NSURL *bundleURL;
@property (nonatomic, strong) NSString *bundleName;
@end

@implementation TMBundle

#pragma mark - Class methods

+ (NSURL *)bundleDirectory
{
    return _bundleDirectory;
}

+ (void)setBundleDirectory:(NSURL *)bundleDirectory
{
    if (bundleDirectory == _bundleDirectory)
        return;
    _bundleDirectory = bundleDirectory;
    [self _indexBundles];
}

+ (void)_indexBundles
{
    NSMutableDictionary *bundleURLs = [NSMutableDictionary dictionary];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:[self bundleDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
        TMBundle *bundle = [[self alloc] initWithBundleURL:fileURL];
        if (bundle)
            [bundleURLs setValue:fileURL forKey:bundle.bundleName];
    }
    _bundleURLs = [bundleURLs copy];
}

+ (NSArray *)bundleNames
{
    return [_bundleURLs allKeys];
}

+ (TMBundle *)bundleWithName:(NSString *)bundleName
{
    return [[self alloc] initWithBundleURL:[_bundleURLs objectForKey:bundleName]];
}

#pragma mark - Properties

@synthesize bundleURL = _bundleURL;
@synthesize bundleName = _bundleName;

- (id)initWithBundleURL:(NSURL *)bundleURL
{
    self = [super init];
    if (!self)
        return nil;
    if (![[bundleURL pathExtension] isEqualToString:_bundleExtension])
        return nil;
    NSData *plistData = [NSData dataWithContentsOfURL:[bundleURL URLByAppendingPathComponent:_bundleInfoPlist] options:NSDataReadingUncached error:NULL];
    if (!plistData)
        return nil;
    NSDictionary *bundlePlist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:NULL];
    if (!bundlePlist)
        return nil;
    NSString *bundleName = [bundlePlist objectForKey:_bundleNameKey];
    if (!bundleName)
        return nil;
    self.bundleURL = bundleURL;
    self.bundleName = bundleName;
    return self;
}

@end
