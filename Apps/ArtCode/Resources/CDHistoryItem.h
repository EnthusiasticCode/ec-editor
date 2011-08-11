//
//  CDHistoryItem.h
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CDTab;

@interface CDHistoryItem : NSManagedObject

@property (nonatomic) float position;
@property (nonatomic, retain) id selection;
@property (nonatomic, retain) NSString * URL;
@property (nonatomic, retain) CDTab *tab;

@end
