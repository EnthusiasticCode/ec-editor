//
//  ACBookmark.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACProject;

@interface ACBookmark : NSManagedObject

@property (nonatomic, retain) NSString * note;
@property (nonatomic) int32_t offset;
@property (nonatomic, retain) ACProject *project;

@end
