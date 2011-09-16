//
//  ACBookmark.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACApplication;

@interface ACBookmark : NSManagedObject

@property (nonatomic, strong) NSString * note;
@property (nonatomic, strong) NSURL * URL;
@property (nonatomic, strong) ACApplication *application;

@end
