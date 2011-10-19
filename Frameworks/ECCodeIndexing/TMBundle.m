//
//  TMBundle.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMBundle.h"
#import "TMSyntax.h"

static NSString * const _bundleExtension = @"tmbundle";
static NSString * const _bundleInfoPlist = @"info.plist";
static NSString * const _bundleNameKey = @"name";
static NSString * const _syntaxDirectory = @"Syntaxes";

@interface TMBundle ()
- (id)initWithBundleURL:(NSURL *)bundleURL;
@property (nonatomic, strong) NSURL *bundleURL;
@property (nonatomic, strong) NSString *bundleName;
@property (nonatomic, strong) NSDictionary *bundlePlist;
@end

@implementation TMBundle

#pragma mark - Properties

@synthesize bundleURL = _bundleURL;
@synthesize bundleName = _bundleName;
@synthesize bundlePlist = _bundlePlist;
@synthesize syntaxes = _syntaxes;

- (NSArray *)syntaxes
{
    if (!_syntaxes)
    {
        NSMutableArray *syntaxes = [NSMutableArray array];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:[self.bundleURL URLByAppendingPathComponent:_syntaxDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
        {
            TMSyntax *syntax = [[TMSyntax alloc] initWithFileURL:fileURL];
            if (!syntax)
                continue;
            [syntaxes addObject:syntax];
        }
        _syntaxes = [syntaxes copy];
    }
    return _syntaxes;
}

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
    self.bundlePlist = bundlePlist;
    return self;
}

@end
