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

#pragma mark - Project metadata

- (NSString *)name {
  return self.presentedItemURL.lastPathComponent;
}

#pragma mark - Project-wide operations

#pragma mark - Private Methods

#if DEBUG

#endif

@end
