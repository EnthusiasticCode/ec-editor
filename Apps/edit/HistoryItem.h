//
//  HistoryItem.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"
@class File, Tab;

@interface HistoryItem : ECManagedObject
@property (nonatomic, retain) id selection;
@property (nonatomic, retain) id position;
@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) Tab *tab;
@property (nonatomic, retain) File *file;
@end
