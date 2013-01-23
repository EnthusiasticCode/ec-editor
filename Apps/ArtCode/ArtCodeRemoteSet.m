//
//  ArtCodeRemoteSet.m
//  ArtCode
//
//  Created by Uri Baghin on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeRemoteSet.h"

#import "ArtCodeDatastore.h"
#import "ArtCodeRemote.h"

@implementation ArtCodeRemoteSet

+ (ArtCodeRemoteSet *)defaultSet {
  static NSString *defaultSetName = @"default";
	
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
  NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"name", defaultSetName];
  [fetchRequest setPredicate:searchPredicate];
  
  NSManagedObjectContext *context = ArtCodeDatastore.defaultDatastore.managedObjectContext;
  
  NSArray *results = [context executeFetchRequest:fetchRequest error:NULL];
  if (results.count > 0) {
    ASSERT(results.count == 1); // if more than 1 they should be merged
    return results[0];
  }
  
  // At this point there is no default tab set and it should be created
  ArtCodeRemoteSet *defaultRemoteSet = [self insertInManagedObjectContext:context];
  defaultRemoteSet.name = defaultSetName;
  
  return defaultRemoteSet;
}

- (ArtCodeRemote *)newRemote {
	ArtCodeRemote *remote = [ArtCodeRemote insertInManagedObjectContext:self.managedObjectContext];
	remote.remoteSet = self;
	return remote;
}

@end
