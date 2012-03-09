//
//  ACProjectItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectItem.h"
#import "ACProject.h"
#import "ACProjectItem+Internal.h"

@implementation ACProjectItem

@synthesize project = _project, UUID = _UUID;

#pragma mark - Initialization

- (id)init
{
    ECASSERT(NO); // The designed initalizer is initWithProject:
}

#pragma mark - Plist Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary
{
    self = [super init];
    if (!self)
        return nil;
    ECASSERT(project);
    _project = project;
    _UUID = [plistDictionary objectForKey:@"uuid"];
    if (!_UUID)
    {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        _UUID = (__bridge NSString *)uuidString;
        CFRelease(uuidString);
        CFRelease(uuid);
    }
    return self;
}

- (NSDictionary *)propertyListDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:_UUID, @"uuid", nil];
}

#pragma mark - Public Methods

- (NSURL *)URL
{
    return nil;
}

- (ACProjectItemType)type
{
    return ACPUnknown;
}

- (void)remove
{
    [self.project updateChangeCount:UIDocumentChangeDone];
}

@end
