//
//  ACProjectItem.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ACProject;

typedef enum {
  ACPUnknown = 0,
  ACPFolder,
  ACPFile,
  ACPFileBookmark,
  ACPRemote,
} ACProjectItemType;

@interface ACProjectItem : NSObject

/// Parent project
@property (nonatomic, weak, readonly) ACProject *project;

/// Unique within project
@property (nonatomic, strong, readonly) id UUID;
@property (nonatomic, strong, readonly) NSURL *artCodeURL;

/// Item type, see enum
@property (nonatomic, readonly) ACProjectItemType type;

/// Delete the item
- (void)remove;

@end
