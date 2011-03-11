//
//  NSURL+ECFoundation.m
//  edit
//
//  Created by Uri Baghin on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSURL+ECFoundation.h"


@implementation NSURL (ECFoundation)

- (BOOL)isFileURLAndExists
{
    if (![self isFileURL])
        return NO;
    CFDictionaryRef properties;
    CFArrayRef desiredProperties = (CFArrayRef)[NSArray arrayWithObject:(NSString *)kCFURLFileExists];
    CFURLCreateDataAndPropertiesFromResource(NULL, (CFURLRef)self, NULL, &properties, desiredProperties, NULL);
    BOOL exists = CFBooleanGetValue(CFDictionaryGetValue(properties, kCFURLFileExists));
    CFRelease(properties);
    return exists;
}

@end
