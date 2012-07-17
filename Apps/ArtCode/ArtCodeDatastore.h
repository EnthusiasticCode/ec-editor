//
//  ArtCodeDatastore.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArtCodeDatastore : NSObject

+ (ArtCodeDatastore *)defaultDatastore;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)setUp;
- (void)tearDown;

@end
