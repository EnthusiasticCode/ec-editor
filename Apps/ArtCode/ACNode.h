//
//  ACNode.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACGroup;

@interface ACNode : NSManagedObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic) int16_t tag;
@property (nonatomic) BOOL expanded;
@property (nonatomic, strong) ACGroup *parent;

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, getter = isConcrete, readonly) BOOL concrete;

- (NSString *)nodeType;

@end
