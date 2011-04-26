//
//  Node.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"
@class Project;

@interface Node : ECManagedObject
@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *tag;
@property (nonatomic, retain) NSSet *nameWords;
@property (nonatomic, retain) Project *project;
@end
