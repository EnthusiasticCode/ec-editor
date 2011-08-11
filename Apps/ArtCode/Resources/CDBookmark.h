//
//  CDBookmark.h
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDBookmark : NSManagedObject

@property (nonatomic, retain) NSString * note;
@property (nonatomic) int32_t offset;

@end
