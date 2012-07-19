//
//  ArtCodeProjectSet.m
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProjectSet.h"
#import "ArtCodeDatastore.h"


static NSString * const _localProjectsFolderName = @"LocalProjects";
static NSString * const _defaultProjectSetName = @"default";

@interface ArtCodeProjectSet () <NSFilePresenter>

+ (NSOperationQueue *)_sharedQueue;

@end


@implementation ArtCodeProjectSet

@synthesize fileURL = _fileURL;

#pragma mark - KVO overrides

+ (NSSet *)keyPathsForValuesAffectingPresentedItemURL {
  return [NSSet setWithObject:@"fileURL"];
}

#pragma mark - Public Methods

+ (ArtCodeProjectSet *)defaultSet {
  static ArtCodeProjectSet *defaultSet = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"name", _defaultProjectSetName];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    [fetchRequest setPredicate:predicate];
    NSManagedObjectContext *defaultContext = [[ArtCodeDatastore defaultDatastore] managedObjectContext];
    NSArray *results = [defaultContext executeFetchRequest:fetchRequest error:NULL];
    if ([results count]) {
      defaultSet = [results objectAtIndex:0];
    } else {
      defaultSet = [self insertInManagedObjectContext:defaultContext];
      defaultSet.name = _defaultProjectSetName;
    }
  });
  return defaultSet;
}

- (void)setUp {
  
}

- (void)tearDown {
  
}

#pragma mark - NSFilePresenter

- (NSURL *)presentedItemURL {
  return self.fileURL;
}

- (NSOperationQueue *)presentedItemOperationQueue {
  return [ArtCodeProjectSet _sharedQueue];
}

#pragma mark - Private Methods

+ (NSOperationQueue *)_sharedQueue {
  static NSOperationQueue *_sharedQueue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedQueue = [[NSOperationQueue alloc] init];
    [_sharedQueue setMaxConcurrentOperationCount:1];
  });
  return _sharedQueue;
}

@end
