//
//  Tab.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Tab : NSManagedObject
@property (nonatomic, retain) NSNumber * customPosition;
@property (nonatomic, retain) Project * project;
@property (nonatomic, retain) NSSet* historyItems;
@end
