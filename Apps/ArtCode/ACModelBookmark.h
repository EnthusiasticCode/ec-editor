//
//  ACModelBookmark.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACModelFile;

@interface ACModelBookmark : NSManagedObject

@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSNumber * offset;
@property (nonatomic, retain) ACModelFile *file;

@end
