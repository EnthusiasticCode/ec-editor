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
#import "ArtCodeURL.h"

#import "NSString+UUID.h"

static NSMutableSet *_projectItemUUIDs;

@implementation ACProjectItem

@synthesize project = _project, UUID = _UUID, artCodeURL = _artCodeURL;

#pragma mark - NSObject

+ (void)initialize {
  if (self != [ACProjectItem class]) {
    return;
  }
  _projectItemUUIDs = [[NSMutableSet alloc] init];
}

- (id)init {
  UNIMPLEMENTED(); // The designed initalizer is initWithProject:
}

#pragma mark - Public Methods

- (NSURL *)artCodeURL {
  if (!_artCodeURL)
    _artCodeURL = [ArtCodeURL artCodeURLWithProject:self.project item:self path:nil];
  return _artCodeURL;
}

- (ACProjectItemType)type {
  return ACPUnknown;
}

#pragma mark - Internal Methods

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary {
  ASSERT(project);
  self = [super init];
  if (!self) {
    return nil;
  }
  _UUID = [plistDictionary objectForKey:@"uuid"];
  if (!_UUID) {
    _UUID = [[NSString alloc] initWithGeneratedUUIDNotContainedInSet:_projectItemUUIDs];
  }
  [_projectItemUUIDs addObject:_UUID];
  _project = project;
  return self;
}

- (NSDictionary *)propertyListDictionary {
  return [NSDictionary dictionaryWithObjectsAndKeys:_UUID, @"uuid", nil];
}

- (void)prepareForRemoval {
  
}

@end
