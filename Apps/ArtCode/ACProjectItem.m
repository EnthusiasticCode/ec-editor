//
//  ACProjectItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectItem.h"
#import "ACProjectItem+Internal.h"

@implementation ACProjectItem

@synthesize project = _project, UUID = _UUID;

- (id)init
{
    ECASSERT(NO); // The designed initalizer is initWithProject:
}

- (id)initWithProject:(ACProject *)project
{
    self = [super init];
    if (!self)
        return nil;
    _project = project;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    _UUID = (__bridge NSString *)uuidString;
    CFRelease(uuidString);
    CFRelease(uuid);
    return self;
}

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super init];
    if (!self)
        return nil;
    _project = project;
    _UUID = [plistDictionary objectForKey:@"uuid"];
    return self;
}

@end
