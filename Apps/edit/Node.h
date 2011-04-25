//
//  Node.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class Folder, Project;

@interface Node : NSManagedObject
@property (nonatomic, retain) NSNumber *customPosition;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *nameWords;
@property (nonatomic, retain) Folder *folder;
@property (nonatomic, retain) Project *project;
@end
