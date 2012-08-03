//
//  ArtCodeProject.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeProject.h"
@class ArtCodeProjectBookmark;


@interface ArtCodeProject : _ArtCodeProject

/// The location of the project on the filesystem
@property (nonatomic, strong, readonly) NSURL *fileURL;

/// A color that represents the project.
@property (nonatomic, strong) UIColor *labelColor;

/// Get an array of all NSURLs of files and folders in the project.
- (void)enumerateFilesWithBlock:(void(^)(NSURL *fileURL))block;

/// Gets an array of ArtCodeProjectBookmark objects for all bookmarks found on all files in the project.
- (void)enumerateBookmarksWithBlock:(void(^)(ArtCodeProjectBookmark *bookmark))block;

#pragma mark Project-wide operations

/// Duplicate the entire project.
- (void)duplicateWithCompletionHandler:(void(^)(ArtCodeProject *duplicate))completionHandler;

@end

@interface ArtCodeProjectBookmark : NSObject

@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSUInteger lineNumber;
@property (nonatomic, strong, readonly) NSString *name;

@end
