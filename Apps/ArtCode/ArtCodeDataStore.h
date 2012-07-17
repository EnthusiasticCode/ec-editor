//
//  ArtCodeDataStore.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArtCodeDataStore : NSObject

+ (ArtCodeDataStore *)sharedDataStore;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)setUp;
- (void)tearDown;

@end
