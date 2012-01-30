//
//  HistoryItem.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class ArtCodeTab, Application;

@interface HistoryItem : NSManagedObject

@property (nonatomic, strong) ArtCodeTab *tab;

@property (nonatomic, strong) NSURL *URL;

@property (nonatomic, strong, readonly) Application *application;

@end
