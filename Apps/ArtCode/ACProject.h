//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACProjectFolder, ACProjectFile;

@interface ACProject : UIDocument

#pragma mark Project Content

/// Unique identifier of the project. It can be a string with an uuid or a core data identifier.
@property (nonatomic, strong, readonly) id UUID;

/// A color that rapresent the project.
@property (nonatomic, strong) UIColor *labelColor;

@property (nonatomic, strong, readonly) ACProjectFolder *contentsFolder;
@property (nonatomic, strong, readonly) NSArray *bookmarks;
@property (nonatomic, strong, readonly) NSArray *remotes;

/// Adds a remote to the project with a full remote url <scheme>://user@host:port
- (void)addRemoteWithName:(NSString *)name URL:(NSURL *)remoteURL;

#pragma mark Project whide operations

- (void)exportToArchiveWithURL:(NSURL *)archiveURL completionHandler:(void(^)(BOOL success))completionHandler;

#pragma mark Creating new projects

/// The local URL at which all projects are stored
+ (NSURL *)projectsURL;

/// Creates a new project and, if set, decompress the archive at the given URL.
+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void(^)(ACProject *createdProject))completionHandler;

@end
