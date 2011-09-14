//
//  ACHistoryItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACTab;

@interface ACHistoryItem : NSManagedObject

@property (nonatomic) float position;
@property (nonatomic, strong) id selection;
@property (nonatomic, strong) NSString * URL;
@property (nonatomic, strong) ACTab *tab;

@end
