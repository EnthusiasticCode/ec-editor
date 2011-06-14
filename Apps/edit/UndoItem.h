//
//  UndoItem.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class File;

@interface UndoItem : NSManagedObject
@property (nonatomic, strong) id range;
@property (nonatomic, strong) NSString * string;
@property (nonatomic, strong) File *file;
@end
