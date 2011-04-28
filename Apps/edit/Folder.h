//
//  Folder.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Node.h"
@class Project;

@interface Folder : Node
@property (nonatomic, retain) NSNumber *collapsed;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSSet *files;
@property (nonatomic, retain) NSSet *subfolders;
@property (nonatomic, retain) Folder *parent;
- (NSMutableArray *)orderedGroups;
- (void)scanForNewFiles;
@end
