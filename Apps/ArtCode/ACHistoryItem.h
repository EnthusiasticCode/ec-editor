//
//  ACHistoryItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACTab;

@interface ACHistoryItem : NSManagedObject

@property (nonatomic, strong) NSURL * URL;
@property (nonatomic, strong) ACTab *tab;

@end
