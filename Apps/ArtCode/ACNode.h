//
//  ACNode.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACState.h"

@class ACGroup;

@interface ACNode : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic) int16_t tag;
@property (nonatomic, retain) ACGroup *parent;

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, getter = isConcrete, readonly) BOOL concrete;

- (NSString *)nodeType;

@end
