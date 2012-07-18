//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProject.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"
#import "NSString+Utilities.h"

#import "ArtCodeLocation.h"


@interface ArtCodeProject ()

- (id)_initWithFileURL:(NSURL *)fileURL;

@end

#pragma mark

@implementation ArtCodeProject {
  NSURL *_presentedItemURL;
  NSOperationQueue *_presentedItemOperationQueue;
}

@synthesize labelColor = _labelColor, newlyCreated = _newlyCreated;

#pragma mark - NSObject

+ (void)initialize {
  if (self != [ArtCodeProject class])
    return;
  
  _projects = [[NSMutableDictionary alloc] init];
  NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  
  [fileCoordinator coordinateReadingItemAtURL:[self projectsDirectory] options:0 writingItemAtURL:[self projectsDirectory] options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
    // Ensure that projects directory exists
    [[[NSFileManager alloc] init] createDirectoryAtURL:newWritingURL withIntermediateDirectories:YES attributes:nil error:NULL];
    
    for (NSURL *projectURL in [fileManager contentsOfDirectoryAtURL:newReadingURL includingPropertiesForKeys:nil options:0 error:NULL]) {
      ArtCodeProject *project = [[self alloc] _initWithFileURL:projectURL];
      if (project) {
        [_projects setObject:project forKey:projectURL];
      }
    }
  }];
}

#pragma mark - NSFilePresenter

- (NSURL *)presentedItemURL {
  @synchronized (self) {
    return _presentedItemURL;
  }
}

- (NSOperationQueue *)presentedItemOperationQueue {
  return _presentedItemOperationQueue;
}

#pragma mark - Public Methods

+ (NSURL *)projectsDirectory {
  static NSURL *_projectsDirectory = nil;
  if (!_projectsDirectory) {
    _projectsDirectory = [NSURL.applicationLibraryDirectory URLByAppendingPathComponent:_projectsFolderName isDirectory:YES];
  }
  return _projectsDirectory;
}

+ (NSDictionary *)projects {
  return _projects.copy;
}

#pragma mark - Project metadata

- (ArtCodeLocation *)artCodeLocation {
  return [ArtCodeLocation locationWithType:ArtCodeLocationTypeProject projectName:self.name url:nil];
}

- (NSString *)name {
  return self.presentedItemURL.lastPathComponent;
}

#pragma mark - Project content

- (NSArray *)bookmarks {
  return [_bookmarks allValues];
}

- (NSArray *)remotes {
  return [_remotes allValues];
}

#pragma mark - Project-wide operations

#pragma mark - Private Methods

- (id)_initWithFileURL:(NSURL *)fileURL {
  self = [super init];
  if (!self) {
    return nil;
  }
  
  _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
  _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
  
  _bookmarks = NSMutableDictionary.alloc.init;
  _remotes = NSMutableDictionary.alloc.init;
  
  return self;
}

#if DEBUG

+ (void)_removeAllProjects {
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  for (NSURL *project in [fileManager contentsOfDirectoryAtURL:[self projectsDirectory] includingPropertiesForKeys:nil options:0 error:NULL]) {
    [fileManager removeItemAtURL:project error:NULL];
  }
  _projects = [[NSMutableDictionary alloc] init];
}

#endif

@end
