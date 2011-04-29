//
//  UndoItem.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"
@class File;

@interface UndoItem : ECManagedObject
@property (nonatomic, retain) id range;
@property (nonatomic, retain) NSString *string;
@property (nonatomic, retain) NSNumber *index;
@property (nonatomic, retain) File *file;
@end
