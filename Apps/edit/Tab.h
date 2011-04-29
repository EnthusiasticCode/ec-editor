//
//  Tab.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"

@class Project;

@interface Tab : ECManagedObject
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Project * project;
@property (nonatomic, retain) NSSet* historyItems;
@end
