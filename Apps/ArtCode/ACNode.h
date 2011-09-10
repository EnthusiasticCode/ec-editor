//
//  ACNode.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACProjectDocumentsList.h"

@class ACGroup, ACNode;

@interface ACNode : NSManagedObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic) int16_t tag;
@property (nonatomic, strong) ACGroup *parent;

@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, getter = isConcrete, readonly) BOOL concrete;

- (NSString *)nodeType;

@end
