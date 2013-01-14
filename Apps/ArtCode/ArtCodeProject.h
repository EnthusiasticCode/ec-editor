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

#pragma mark Project-wide operations

/// Duplicate the entire project.
- (void)duplicateWithCompletionHandler:(void(^)(ArtCodeProject *duplicate))completionHandler;

@end

@interface ArtCodeProjectBookmark : NSObject

@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSUInteger lineNumber;
@property (nonatomic, strong, readonly) NSString *name;

@end
