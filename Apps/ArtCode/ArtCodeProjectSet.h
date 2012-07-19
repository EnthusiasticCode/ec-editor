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
@property (atomic, strong, readonly) NSURL *fileURL;

/// Sets up and tears down the filesystem change observing machinery
/// setUp and tearDown calls must be balanced
- (void)setUp;
- (void)tearDown;

- (void)addNewProjectWithName:(NSString *)name completionHandler:(void(^)(ArtCodeProject *project))completionHandler;

- (void)removeProject:(ArtCodeProject *)project completionHandler:(void(^)(NSError *error))completionHandler;

@end
