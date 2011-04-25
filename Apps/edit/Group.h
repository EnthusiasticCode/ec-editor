//
//  Group.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Folder;

@interface Group : NSManagedObject
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSSet* items;
@property (nonatomic, retain) Folder * area;
@end
