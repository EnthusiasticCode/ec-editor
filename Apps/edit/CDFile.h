//
//  CDFile.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDNode.h"

@class CDBookmark, CDHistoryItem, CDUndoItem;

@interface CDFile : CDNode {
@private
}
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSSet* undoItems;
@property (nonatomic, retain) NSSet* bookmarks;
@property (nonatomic, retain) NSSet* historyItems;

@end
