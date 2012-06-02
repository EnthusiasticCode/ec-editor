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

@implementation ACProjectFileSystemItem

@synthesize parentFolder = _parentFolder, name = _name;

#pragma mark - ACProjectItem Internal

- (id)initWithProject:(ACProject *)project propertyListDictionary:(NSDictionary *)plistDictionary {
  return [self initWithProject:project parent:nil fileWrapper:nil propertyListDictionary:plistDictionary];
}

- (NSDictionary *)propertyListDictionary {
  return [super propertyListDictionary];
}

- (void)setPropertyListDictionary:(NSDictionary *)propertyListDictionary {
  [super setPropertyListDictionary:propertyListDictionary];
}

#pragma mark - Item Properties

- (NSString *)pathInProject {
  if (self.parentFolder == nil) {
    return self.project.name;
  }
  
  return [[self.parentFolder pathInProject] stringByAppendingPathComponent:self.name];
}

#pragma mark - Item Contents

- (void)updateWithContentsOfURL:(NSURL *)url completionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSFileWrapper *fileWrapper = nil;
    [NSFileCoordinator.alloc.init coordinateReadingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newURL) {
      fileWrapper = [NSFileWrapper.alloc initWithURL:newURL options:NSFileWrapperReadingImmediate | NSFileWrapperReadingWithoutMapping error:NULL];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (fileWrapper) {
        self.fileWrapper = fileWrapper;
      }
      if (completionHandler) {
        completionHandler(fileWrapper ? YES : NO);
      }
    });
  });
}

- (void)publishContentsToURL:(NSURL *)url completionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  NSFileWrapper *fileWrapper = self.fileWrapper;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block BOOL success = NO;
    [NSFileCoordinator.alloc.init coordinateWritingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newURL) {
      [NSFileManager.alloc.init createDirectoryAtURL:newURL.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];
      success = [fileWrapper writeToURL:newURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:NULL];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (completionHandler) {
        completionHandler(success);
      }
    });
  });
}

#pragma mark - Internal Methods

- (NSFileWrapper *)fileWrapper {
  UNIMPLEMENTED();
}

- (void)setFileWrapper:(NSFileWrapper *)fileWrapper {
  UNIMPLEMENTED_VOID();
}

- (id)initWithProject:(ACProject *)project parent:(ACProjectFolder *)parent fileWrapper:(NSFileWrapper *)fileWrapper propertyListDictionary:(NSDictionary *)plistDictionary {
  // All filesystem items need to be initialized in the project's file access coordination queue
  ASSERT(project);

  // Initialize the item
  self = [super initWithProject:project propertyListDictionary:plistDictionary];
  if (!self) {
    return nil;
  }
  
  _name = fileWrapper.preferredFilename;
  
  _parentFolder = parent;
  return self;
}

@end
