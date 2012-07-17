//
//  Remote.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface Remote : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * urlString;
@property (nonatomic, retain) Project *project;

@end
