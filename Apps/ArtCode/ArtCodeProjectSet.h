//
//  ArtCodeProjectSet.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeProjectSet.h"
@class ArtCodeProject;


@interface ArtCodeProjectSet : _ArtCodeProjectSet

+ (ArtCodeProjectSet *)defaultSet;

/// The location of the project set on the filesystem
@property (nonatomic, strong, readonly) NSURL *fileURL;

- (void)addNewProjectWithName:(NSString *)name labelColor:(UIColor *)labelColor completionHandler:(void(^)(ArtCodeProject *project))completionHandler;

- (void)removeProject:(ArtCodeProject *)project completionHandler:(void(^)(NSError *error))completionHandler;

#pragma mark RAC Outlets

// Sends each object after it has been added. It never completes or errors.
@property (nonatomic, readonly) RACSubscribable *objectsAdded;

// Sends each object after it has been removed. It never completes or errors.
@property (nonatomic, readonly) RACSubscribable *objectsRemoved;

#pragma mark Utilities

/// Returns a path relative to the project set for the given file URL.
- (NSString *)relativePathForFileURL:(NSURL *)fileURL;

@end
