//
//  NSURL+ECAdditions.m
//  edit
//
//  Created by Uri Baghin on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSURL+ECAdditions.h"


@implementation NSURL (ECAdditions)

- (BOOL)isFileURLAndExists
{
    static BOOL firstRun = YES;
    static BOOL exists;
    if (!firstRun)
        return exists;
    if (![self isFileURL])
        exists = NO;
    CFDictionaryRef properties;
    CFArrayRef desiredProperties = (CFArrayRef)[NSArray arrayWithObject:(NSString *)kCFURLFileExists];
    CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)self, NULL, &properties, desiredProperties, NULL);
    exists = CFBooleanGetValue(CFDictionaryGetValue(properties, kCFURLFileExists));
    CFRelease(properties);
    firstRun = NO;
    return exists;
}

@end
