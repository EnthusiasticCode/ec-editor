//
//  CDTab.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ECManagedObject.h"

@class CDHistoryItem;

@interface CDTab : ECManagedObject {
@private
}
@property (nonatomic, strong) NSNumber * index;
@property (nonatomic, strong) NSSet* historyItems;

@end
