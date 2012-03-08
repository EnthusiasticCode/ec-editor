//
//  ACProjectItem.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ACProject;

typedef enum
{
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

/// Item type, see enum
@property (nonatomic, readonly) ACProjectItemType type;

/// absolute URL of the item if applicable, nil otherwise
- (NSURL *)URL;

/// Delete the item
- (void)remove;

@end
