//
//  TMBundle.m
//  CodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMBundle.h"

static NSString * const _bundleExtension = @"tmbundle";

static NSArray *_bundleURLs;

@implementation TMBundle

+ (void)initialize
{
    if (self != [TMBundle class])
        return;
    // This class takes a long time to initialize, we have to make sure it doesn't do so on the main queue
#if ! TEST
    ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
#endif
    NSMutableArray *bundleURLs = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    for (NSURL *bundleURL in [fileManager contentsOfDirectoryAtURL:[[NSBundle bundleForClass:self] bundleURL] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL])
    {
        if (![[bundleURL pathExtension] isEqualToString:_bundleExtension])
            continue;
        [bundleURLs addObject:bundleURL];
    }
    _bundleURLs = [bundleURLs copy];    
}

+ (NSArray *)bundleURLs
{
    return _bundleURLs;
}

@end
