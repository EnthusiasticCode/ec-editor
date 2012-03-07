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

@property (nonatomic, weak, readonly) ACProject *project; // Parent project
@property (nonatomic, strong, readonly) id UUID; // Unique within project
@property (nonatomic, readonly) ACProjectItemType *type; // Item type, see enum
- (NSURL *)URL; // absolute URL of the item if applicable, nil otherwise
- (void)remove; // Delete the item

@end
