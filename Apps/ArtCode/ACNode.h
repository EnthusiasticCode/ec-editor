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
@property (nonatomic, strong) ACNode *parent;
@property (nonatomic, strong) NSOrderedSet *children;

- (void)moveChildrenAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeChildAtIndex:(NSUInteger)fromIndex withChildAtIndex:(NSUInteger)toIndex;

- (ACGroup *)insertChildGroupWithName:(NSString *)name atIndex:(NSUInteger)index;

- (NSURL *)ACURL;
- (NSString *)relativePath;

@end
