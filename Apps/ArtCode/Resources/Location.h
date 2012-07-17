//
//  Location.h
//  ArtCode
//
//  Created by Uri Baghin on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project, Tab;

@interface Location : NSManagedObject

@property (nonatomic) int16_t type;
@property (nonatomic, retain) NSString * dataString;
@property (nonatomic, retain) NSSet *tabs;
@property (nonatomic, retain) Project *project;
@end

@interface Location (CoreDataGeneratedAccessors)

- (void)addTabsObject:(Tab *)value;
- (void)removeTabsObject:(Tab *)value;
- (void)addTabs:(NSSet *)values;
- (void)removeTabs:(NSSet *)values;

@end
