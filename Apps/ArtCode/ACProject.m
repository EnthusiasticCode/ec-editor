//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"

#import "NSURL+Utilities.h"
#import "UIColor+HexColor.h"
#import "NSString+Utilities.h"

#import "ArtCodeLocation.h"


NSString * const ACProjectWillAddProjectNotificationName = @"ACProjectWillAddProjectNotificationName";
NSString * const ACProjectDidAddProjectNotificationName = @"ACProjectDidAddProjectNotificationName";
NSString * const ACProjectWillRemoveProjectNotificationName = @"ACProjectWillRemoveProjectNotificationName";
NSString * const ACProjectDidRemoveProjectNotificationName = @"ACProjectDidRemoveProjectNotificationName";
NSString * const ACProjectNotificationProjectKey = @"ACProjectNotificationProjectKey";

NSString * const ACProjectWillAddItem = @"ACProjectWillAddItem";
NSString * const ACProjectDidAddItem = @"ACProjectDidAddItem";
NSString * const ACProjectWillRemoveItem = @"ACProjectWillRemoveItem";
NSString * const ACProjectDidRemoveItem = @"ACProjectDidRemoveItem";
NSString * const ACProjectNotificationItemKey = @"ACProjectNotificationItemKey";

static NSMutableDictionary *_projects = nil;

static NSString * const _projectsKey = @"ACProjectProjects";
static NSString * const _projectsFolderName = @"LocalProjects";

// Metadata
static NSString * const _plistNameKey = @"name";
static NSString * const _plistLabelColorKey = @"labelColor";
static NSString * const _plistIsNewlyCreatedKey = @"newlyCreated";

// Content
static NSString * const _plistContentsKey = @"contents";
static NSString * const _plistBookmarksKey = @"bookmarks";
static NSString * const _plistRemotesKey = @"remotes";


@interface ACProject ()

- (id)_initWithFileURL:(NSURL *)fileURL;

@end

#pragma mark

@implementation ACProject {
  NSURL *_presentedItemURL;
  NSOperationQueue *_presentedItemOperationQueue;
  NSMutableDictionary *_bookmarks;
  NSMutableDictionary *_remotes;
}

@synthesize labelColor = _labelColor, newlyCreated = _newlyCreated;

#pragma mark - NSObject

+ (void)initialize {
  if (self != [ACProject class])
    return;
  
  _projects = [[NSMutableDictionary alloc] init];
  NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  
  [fileCoordinator coordinateReadingItemAtURL:[self projectsDirectory] options:0 writingItemAtURL:[self projectsDirectory] options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
    // Ensure that projects directory exists
    [[[NSFileManager alloc] init] createDirectoryAtURL:newWritingURL withIntermediateDirectories:YES attributes:nil error:NULL];
    
    for (NSURL *projectURL in [fileManager contentsOfDirectoryAtURL:newReadingURL includingPropertiesForKeys:nil options:0 error:NULL]) {
      ACProject *project = [[self alloc] _initWithFileURL:projectURL];
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

#pragma mark

@implementation ACProject (RACExtensions)

+ (RACSubscribable *)rac_projects {
  static RACSubscribable *_rac_projects = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    _rac_projects = [RACSubscribable merge:[NSArray arrayWithObjects:[notificationCenter rac_addObserverForName:ACProjectDidAddProjectNotificationName object:self], [notificationCenter rac_addObserverForName:ACProjectDidRemoveProjectNotificationName object:self], nil]];
  });
  return _rac_projects;
}

@end
