//
//  Project.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Folder.h"

@interface Project : Folder
@property (nonatomic, retain) NSSet* projectFiles;
@property (nonatomic, retain) NSSet* projectFolders;
@property (nonatomic, retain) NSSet *tabs;
@property (nonatomic, retain) NSSet *targets;
- (NSArray *)orderedProjectFolders;
@end
