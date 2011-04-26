//
//  Bookmark.h
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ECManagedObject.h"
@class File;

@interface Bookmark : ECManagedObject
@property (nonatomic, retain) id range;
@property (nonatomic, retain) NSString *note;
@property (nonatomic, retain) File *file;
@end
