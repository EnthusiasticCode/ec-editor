//
//  ACModelHistoryItem.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACModelNode, ACModelTab;

@interface ACModelHistoryItem : NSManagedObject

@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) id selection;
@property (nonatomic, retain) ACModelNode *node;
@property (nonatomic, retain) ACModelTab *tab;

@end
