//
//  File.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Node.h"

@class Bookmark, HistoryItem, UndoItem;

@interface File : Node {
@private
}
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSSet* bookmarks;
@property (nonatomic, retain) NSSet* undoItems;
@property (nonatomic, retain) NSSet* historyItems;

@end
