//
//  ACURLWrapper.h
//  ArtCode
//
//  Created by Uri Baghin on 10/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACApplication;

@interface ACURLWrapper : NSManagedObject

@property (nonatomic, strong) NSURL * URL;

@property (nonatomic, strong, readonly) ACApplication *application;

@end
