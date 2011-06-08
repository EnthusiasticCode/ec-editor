//
//  CDUndoItem.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ECManagedObject.h"

@class CDFile;

@interface CDUndoItem : ECManagedObject {
@private
}
@property (nonatomic, strong) id range;
@property (nonatomic, strong) NSString * string;
@property (nonatomic, strong) NSNumber * index;
@property (nonatomic, strong) CDFile * file;

@end
