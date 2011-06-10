//
//  CDHistoryItem.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDFile, CDTab;

@interface CDHistoryItem : NSManagedObject {
@private
}
@property (nonatomic, retain) id position;
@property (nonatomic, retain) id selection;
@property (nonatomic, retain) CDFile *file;
@property (nonatomic, retain) CDTab *tab;

@end
