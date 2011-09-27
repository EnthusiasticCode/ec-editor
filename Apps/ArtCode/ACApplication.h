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
@property (nonatomic, strong) NSOrderedSet *projects;

- (void)insertTabAtIndex:(NSUInteger)index;
- (void)removeTabAtIndex:(NSUInteger)index;

/// Reorder the tabs list
- (void)moveTabsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeTabsAtIndex:(NSUInteger)fromIndex withTabsAtIndex:(NSUInteger)toIndex;

/// Reorder the projcets list
- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex;

/// Returns the object referenced by the URL or nil if the object could not be found does not exist
- (id)objectWithURL:(NSURL *)URL;

/// Deletes the object referenced by the URL
- (void)deleteObjectWithURL:(NSURL *)URL;

@end
