//
//  ACStateNode.h
//  ArtCode
//
//  Created by Uri Baghin on 7/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACStateNode <NSObject>

/// AC URL of the node
@property (nonatomic, strong) NSURL *URL;

/// Node name
@property (nonatomic, copy) NSString *name;

/// Node index in the containing node or list
@property (nonatomic) NSUInteger index;

/// Tag of the node
@property (nonatomic) NSUInteger tag;

/// Child nodes
@property (nonatomic, strong, readonly) NSOrderedSet *children;

/// Deletes the node
- (void)delete;

/// Returns whether the node has been deleted
@property (nonatomic, readonly, getter = isDeleted) BOOL deleted;

@end
