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
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSSet* undoItems;
@property (nonatomic, strong) NSSet* bookmarks;
@property (nonatomic, strong) NSSet* historyItems;

@end
