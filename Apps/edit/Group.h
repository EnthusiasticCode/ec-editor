//
//  Group.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"
@class Folder, File;

@interface Group : ECManagedObject
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSSet* items;
@property (nonatomic, retain) Folder * area;
- (void)addItemsObject:(File *)value;
- (void)removeItemsObject:(File *)value;
- (void)addItems:(NSSet *)value;
- (void)removeItems:(NSSet *)value;
- (NSArray *)orderedItems;
- (void)moveItemAtIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2;
@end
