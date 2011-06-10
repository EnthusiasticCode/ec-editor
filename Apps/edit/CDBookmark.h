//
//  CDBookmark.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDFile;

@interface CDBookmark : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) id range;
@property (nonatomic, retain) CDFile *file;

@end
