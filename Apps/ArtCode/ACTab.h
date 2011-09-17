//
//  ACTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACApplication, ACHistoryItem;

@interface ACTab : NSManagedObject

@property (nonatomic) int16_t currentHistoryPosition;
@property (nonatomic, strong) ACApplication *application;
@property (nonatomic, strong) NSOrderedSet *historyItems;

/// The current URL the tab history is pointing at. This property is read only.
/// To change the current URL use one of the move methods or pushURL.
@property (nonatomic, strong, readonly) NSURL *currentURL;

/// Pushes an URL to the tab's history.
/// Changes the current url to the newly pushed url, and deletes any history items following the previously current one
- (void)pushURL:(NSURL *)url;

/// A value indicating if calling moveBackInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveBackInHistory;

/// A value indicating if calling moveForwardInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveForwardInHistory;

/// Convinience method that moves the tab's history back by one step.
- (void)moveBackInHistory;

/// Convinience method that moves the tab's history forward by one step.
- (void)moveForwardInHistory;

@end

@interface ACTab (CoreDataGeneratedAccessors)

- (void)insertObject:(ACHistoryItem *)value inHistoryItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHistoryItemsAtIndex:(NSUInteger)idx;
- (void)insertHistoryItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHistoryItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHistoryItemsAtIndex:(NSUInteger)idx withObject:(ACHistoryItem *)value;
- (void)replaceHistoryItemsAtIndexes:(NSIndexSet *)indexes withHistoryItems:(NSArray *)values;
- (void)addHistoryItemsObject:(ACHistoryItem *)value;
- (void)removeHistoryItemsObject:(ACHistoryItem *)value;
- (void)addHistoryItems:(NSOrderedSet *)values;
- (void)removeHistoryItems:(NSOrderedSet *)values;
@end
