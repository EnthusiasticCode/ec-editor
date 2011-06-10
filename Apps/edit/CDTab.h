//
//  CDTab.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDHistoryItem;

@interface CDTab : NSManagedObject {
@private
}
@property (nonatomic) int32_t index;
@property (nonatomic, retain) NSSet *historyItems;
@end

@interface CDTab (CoreDataGeneratedAccessors)
- (void)addHistoryItemsObject:(CDHistoryItem *)value;
- (void)removeHistoryItemsObject:(CDHistoryItem *)value;
- (void)addHistoryItems:(NSSet *)value;
- (void)removeHistoryItems:(NSSet *)value;

@end
