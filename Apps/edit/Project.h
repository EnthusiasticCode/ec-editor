//
//  Project.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Node.h"

@interface Project : Node
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic, retain) NSString *defaultType;
@property (nonatomic, retain) Node *nodes;
@property (nonatomic, retain) NSSet *tabs;
@property (nonatomic, retain) NSSet *targets;
@end
