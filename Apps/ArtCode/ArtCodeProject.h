//
//  ArtCodeProject.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeProject.h"


@interface ArtCodeProject : _ArtCodeProject <NSFilePresenter>

#pragma mark Project metadata

/// A color that represents the project.
@property (nonatomic, strong) UIColor *labelColor;

#pragma mark Project content

/// Get an array of all NSURLs of files and folders in the project.
- (NSArray *)allFiles;

/// Gets an array of ArtCodeLocations representing all bookmarks from the files in the project.
- (NSArray *)allBookmarks;

#pragma mark Project-wide operations

/// Duplicate the entire project.
/// The returned project is opened, it must be closed in the completion handler if not needed anymore.
- (void)duplicateWithCompletionHandler:(void(^)(ArtCodeProject *duplicate))completionHandler;

- (void)publishContentsToURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler;

- (void)updateWithContentsOfURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler;

@end
