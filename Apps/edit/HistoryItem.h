//
//  HistoryItem.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class File, Tab;

@interface HistoryItem : NSManagedObject
@property (nonatomic, strong) id position;
@property (nonatomic, strong) id selection;
@property (nonatomic, strong) File *file;
@property (nonatomic, strong) Tab *tab;
@end
