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
@property (nonatomic, strong) id selection;
@property (nonatomic, strong) id position;
@property (nonatomic, strong) NSNumber * index;
@property (nonatomic, strong) CDTab * tab;
@property (nonatomic, strong) CDFile * file;

@end
