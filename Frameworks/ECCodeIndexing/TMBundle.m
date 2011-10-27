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
{
    NSInteger _contentAccessCount;
}
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

- (NSDictionary *)bundlePlist
{
    ECASSERT(_contentAccessCount > 0);
    if (!_bundlePlist)
        _bundlePlist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:[self.bundleURL URLByAppendingPathComponent:_bundleInfoPlist] options:NSDataReadingUncached error:NULL] options:NSPropertyListImmutable format:NULL error:NULL];
    return _bundlePlist;
}

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
    self.bundleURL = bundleURL;
    [self beginContentAccess];
    self.bundleName = [self.bundlePlist objectForKey:_bundleNameKey];
    if (!self.bundleName)
        return nil;
    [self endContentAccess];
    return self;
}

- (BOOL)beginContentAccess
{
    ECASSERT(_contentAccessCount >= 0);
    ++_contentAccessCount;
    return YES;
}

- (void)endContentAccess
{
    ECASSERT(_contentAccessCount > 0);
    --_contentAccessCount;
}

- (void)discardContentIfPossible
{
    ECASSERT(_contentAccessCount >= 0);
    if (_contentAccessCount > 0)
        return;
    _bundlePlist = nil;
    _syntaxes = nil;
}

- (BOOL)isContentDiscarded
{
    return !_bundlePlist && !_syntaxes;
}

@end
