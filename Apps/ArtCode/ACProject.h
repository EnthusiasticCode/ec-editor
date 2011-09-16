//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACGroup.h"


@interface ACProject : ACGroup

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *fileURL;

@end
