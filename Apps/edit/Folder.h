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

@interface Folder : Node
@property (nonatomic, retain) NSNumber * collapsed;
@property (nonatomic, retain) NSSet* nodes;
@property (nonatomic, retain) NSSet* groups;
@end
