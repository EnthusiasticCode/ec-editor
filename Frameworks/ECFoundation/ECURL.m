//
//  ACURL.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECURL.h"

@implementation NSURL (ECURL)

+ (NSURL *)applicationDocumentsDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

+ (NSURL *)applicationLibraryDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
}

+ (NSURL *)temporaryDirectory
{
    NSURL *temporaryDirectory;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    do
    {
        CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
        CFStringRef uuidString = CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
        temporaryDirectory = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:(__bridge NSString *)uuidString];
        CFRelease(uuidString);
        CFRelease(uuid);
    }
    while ([fileManager fileExistsAtPath:[temporaryDirectory path]]);
    return temporaryDirectory;
}

@end
