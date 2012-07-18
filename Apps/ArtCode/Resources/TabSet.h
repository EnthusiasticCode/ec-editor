//
//  TabSet.h
//  ArtCode
//
//  Created by Uri Baghin on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Tab;

@interface TabSet : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic) int16_t activeTabIndex;
@property (nonatomic, retain) NSOrderedSet *tabs;
@end

@interface TabSet (CoreDataGeneratedAccessors)

- (void)insertObject:(Tab *)value inTabsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTabsAtIndex:(NSUInteger)idx;
- (void)insertTabs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTabsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTabsAtIndex:(NSUInteger)idx withObject:(Tab *)value;
- (void)replaceTabsAtIndexes:(NSIndexSet *)indexes withTabs:(NSArray *)values;
- (void)addTabsObject:(Tab *)value;
- (void)removeTabsObject:(Tab *)value;
- (void)addTabs:(NSOrderedSet *)values;
- (void)removeTabs:(NSOrderedSet *)values;
@end
