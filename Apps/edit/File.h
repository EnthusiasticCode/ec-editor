//
//  File.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Node.h"
@class Group;

@interface File : Node
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) NSSet *bookmarks;
@property (nonatomic, retain) NSSet *undoItems;
@property (nonatomic, retain) NSSet *historyItems;
@property (nonatomic, retain) NSSet *targets;
@end
