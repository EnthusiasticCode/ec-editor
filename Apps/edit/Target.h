//
//  Target.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"
@class Project;

@interface Target : ECManagedObject
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* sourceFiles;
@property (nonatomic, retain) Project * project;
@end
