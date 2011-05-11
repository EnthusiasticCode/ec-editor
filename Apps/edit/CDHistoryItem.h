//
//  CDHistoryItem.h
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ECManagedObject.h"

@class CDFile, CDTab;

@interface CDHistoryItem : ECManagedObject {
@private
}
@property (nonatomic, retain) id selection;
@property (nonatomic, retain) id position;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) CDTab * tab;
@property (nonatomic, retain) CDFile * file;

@end
