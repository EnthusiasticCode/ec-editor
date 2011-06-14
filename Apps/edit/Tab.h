//
//  Tab.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HistoryItem;

@interface Tab : NSManagedObject
@property (nonatomic) int32_t index;
@property (nonatomic, strong) NSSet *historyItems;
@end

@interface Tab (CoreDataGeneratedAccessors)
- (void)addHistoryItemsObject:(HistoryItem *)value;
- (void)removeHistoryItemsObject:(HistoryItem *)value;
- (void)addHistoryItems:(NSSet *)value;
- (void)removeHistoryItems:(NSSet *)value;

@end
