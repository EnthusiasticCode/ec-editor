//
//  Bookmark.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class File;

@interface Bookmark : NSManagedObject
@property (nonatomic, strong) NSString * note;
@property (nonatomic, strong) id range;
@property (nonatomic, strong) File *file;
@end
