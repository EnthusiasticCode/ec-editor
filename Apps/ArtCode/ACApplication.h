//
//  ACApplication.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACBookmark, ACTab;

@interface ACApplication : NSManagedObject

@property (nonatomic, strong) NSOrderedSet *bookmarks;
@property (nonatomic, strong) NSOrderedSet *tabs;

- (void)insertTabAtIndex:(NSUInteger)index;
- (void)removeTabAtIndex:(NSUInteger)index;

/// Reorder the tabs list
- (void)moveTabsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeTabsAtIndex:(NSUInteger)fromIndex withTabsAtIndex:(NSUInteger)toIndex;

@end

@interface ACApplication (CoreDataGeneratedAccessors)

- (void)insertObject:(ACBookmark *)value inBookmarksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBookmarksAtIndex:(NSUInteger)idx;
- (void)insertBookmarks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBookmarksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBookmarksAtIndex:(NSUInteger)idx withObject:(ACBookmark *)value;
- (void)replaceBookmarksAtIndexes:(NSIndexSet *)indexes withBookmarks:(NSArray *)values;
- (void)addBookmarksObject:(ACBookmark *)value;
- (void)removeBookmarksObject:(ACBookmark *)value;
- (void)addBookmarks:(NSOrderedSet *)values;
- (void)removeBookmarks:(NSOrderedSet *)values;
- (void)insertObject:(ACTab *)value inTabsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTabsAtIndex:(NSUInteger)idx;
- (void)insertTabs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTabsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTabsAtIndex:(NSUInteger)idx withObject:(ACTab *)value;
- (void)replaceTabsAtIndexes:(NSIndexSet *)indexes withTabs:(NSArray *)values;
- (void)addTabsObject:(ACTab *)value;
- (void)removeTabsObject:(ACTab *)value;
- (void)addTabs:(NSOrderedSet *)values;
- (void)removeTabs:(NSOrderedSet *)values;
@end
