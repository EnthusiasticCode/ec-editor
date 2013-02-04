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

// Sets up and tears down the datastore autosave machinery.
// setUp and tearDown calls must be balanced.
- (void)setUp;
- (void)tearDown;

@end
