//
//  ACProjectFileSystemItem.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectItem+Internal.h"
#import "ACProject.h"

#import "ACProjectFolder.h"

#import "NSURL+Utilities.h"


@interface ACProject (FileSystemItems)

- (void)didRemoveFileSystemItem:(ACProjectFileSystemItem *)fileSystemItem;

@end

#pragma mark -

/// Folder internal method to remove a child item
@interface ACProjectFolder (Internal)

- (void)didRemoveChild:(ACProjectFileSystemItem *)child;

@end

#pragma mark -

@implementation ACProjectFileSystemItem

@synthesize parentFolder = _parentFolder, contentModificationDate = _contentModificationDate, fileURL = _fileURL;

#pragma mark - ACProjectItem

- (void)remove {
  [self removeWithCompletionHandler:nil];
}

#pragma mark - ACProjectItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary {
  return [self initWithProject:project propertyListDictionary:plistDictionary parent:nil name:nil];
}

- (NSDictionary *)propertyListDictionary {
  return [super propertyListDictionary];
}

- (void)setPropertyListDictionary:(NSDictionary *)propertyListDictionary {
  [super setPropertyListDictionary:propertyListDictionary];
}

#pragma mark - Item Properties

- (NSString *)name {
  return [_fileURL lastPathComponent];
}

- (NSString *)pathInProject {
  if (self.parentFolder == nil) {
    return self.project.name;
  }
  
  return [[self.parentFolder pathInProject] stringByAppendingPathComponent:self.name];
}

#pragma mark - Item Contents

#define PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER(method_call) \
ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);\
completionHandler = [completionHandler copy];\
[self.project performAsynchronousFileAccessUsingBlock:^{\
BOOL success = method_call;\
if (completionHandler) {\
[NSOperationQueue.mainQueue addOperationWithBlock:^{\
completionHandler(success);\
}];\
}\
}]


- (void)updateWithContentsOfURL:(NSURL *)url completionHandler:(void (^)(BOOL))completionHandler {
  PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER([self readFromURL:url error:NULL]);
}

- (void)publishContentsToURL:(NSURL *)url completionHandler:(void (^)(BOOL))completionHandler {
  PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER([self writeToURL:url error:NULL]);
}

- (void)removeWithCompletionHandler:(void (^)(BOOL))completionHandler {
  PERFORM_ON_FILE_ACCESS_COORDINATION_QUEUE_AND_FORWARD_ERROR_TO_COMPLETION_HANDLER([self removeSynchronouslyWithError:NULL]);
}

#pragma mark - Internal Methods

- (NSURL *)fileURL {
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  return _fileURL;
}

- (void)setFileURL:(NSURL *)fileURL {
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  _fileURL = fileURL;
}

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary parent:(ACProjectFolder *)parent name:(NSString *)name {
  // All filesystem items need to be initialized in the project's file access coordination queue
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  ASSERT(project);

  // Initialize the item
  self = [super initWithProject:project propertyListDictionary:plistDictionary];
  if (!self) {
    return nil;
  }
  
  _parentFolder = parent;
  if (parent) {
    _fileURL = [parent.fileURL URLByAppendingPathComponent:name];
  } else {
    _fileURL = project.contentsFolderURL;
  }
  
  return self;
}

- (BOOL)readFromURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  // Try to get the content modification date
  NSDate *contentModificationDate = nil;
  [url getResourceValue:&contentModificationDate forKey:NSURLContentModificationDateKey error:NULL];
  if (!contentModificationDate) {
    contentModificationDate = [[NSDate alloc] init];
  }
  _contentModificationDate = contentModificationDate;
  
  return YES;
}

- (BOOL)writeToURL:(NSURL *)url error:(out NSError *__autoreleasing *)error {
  return YES;
}

- (BOOL)removeSynchronouslyWithError:(NSError *__autoreleasing *)error
{
  ASSERT(NSOperationQueue.currentQueue != NSOperationQueue.mainQueue);
  NSFileManager *fileManager = NSFileManager.alloc.init;
  if ([fileManager fileExistsAtPath:self.fileURL.path] && ![fileManager removeItemAtURL:self.fileURL error:error]) {
    ASSERT(!error || *error);
    return NO;
  } else {
    [self.parentFolder didRemoveChild:self];
    [self.project didRemoveFileSystemItem:self];
    return YES;
  }
}

@end
