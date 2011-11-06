//
//  ECCodeIndex.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeIndex+Subclass.h"

static NSMutableArray *_extensionClasses;

@interface ECCodeIndex ()
{
    NSMutableArray *_extensions;
    NSMutableDictionary *_fileBuffers;
}
@end

@implementation ECCodeIndex

- (id)init
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return [super init];
    self = [super init];
    if (!self)
        return nil;
    _extensions = [NSMutableArray arrayWithCapacity:[_extensionClasses count]];
    for (Class extensionClass in _extensionClasses)
        [_extensions addObject:[[extensionClass alloc] init]];
    _fileBuffers = [NSMutableDictionary dictionary];
    return self;
}

- (void)setUnsavedContent:(NSString *)content forFile:(NSURL *)fileURL
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return;
    ECASSERT(fileURL);
    if (content)
        [_fileBuffers setObject:content forKey:fileURL];
    else
        [_fileBuffers removeObjectForKey:fileURL];
}

- (ECCodeUnit *)codeUnitForFile:(NSURL *)fileURL language:(NSString *)language scope:(NSString *)scope
{
    if (![self isMemberOfClass:[ECCodeIndex class]])
        return nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:[fileURL path]])
        return nil;
    float winningSupport = 0.0;
    ECCodeIndex *winningExtension = nil;
    for (ECCodeIndex *extension in _extensions)
    {
        float support = [extension supportForFile:fileURL language:language scope:scope];
        if (support <= winningSupport)
            continue;
        winningSupport = support;
        winningExtension = extension;
    }
    ECASSERT(winningSupport >= 0.0 && winningSupport < 1.0);
    if (winningSupport == 0.0)
        return nil;
    return [winningExtension codeUnitForFile:fileURL language:language scope:scope];
}

@end

@implementation ECCodeIndex (Internal)

+ (void)registerExtension:(Class)extensionClass
{
    if (self != [ECCodeIndex class])
        return;
    ECASSERT([extensionClass isSubclassOfClass:self]);
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableArray alloc] init];
    [_extensionClasses addObject:extensionClass];
}

- (NSString *)contentsForFile:(NSURL *)fileURL
{
    ECASSERT(fileURL);
    NSString *contents = [_fileBuffers objectForKey:fileURL];
    if (!contents)
    {
        NSError *error = nil;
        contents = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
        if (error)
            contents = nil;
        else
            [_fileBuffers setObject:contents forKey:fileURL];
    }
    return contents;
}

@end
