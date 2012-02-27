//
//  Project.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 14/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProjectBookmark, ProjectRemote, UIColor;

@interface ArtCodeProject : NSObject

+ (void)saveProjectsToDisk;

/// Returns a value indicating if the project with the given name exists.
+ (BOOL)projectWithNameExists:(NSString *)name;

/// Returns a name which does not conflict with a project name in the projects directory.
+ (NSString *)validNameForNewProjectName:(NSString *)name;

/// Returns a project URL from a project name. This method does not check for existance of the project.
+ (NSURL *)projectURLFromName:(NSString *)name;

/// Open a project with the given name in the projects directory.
+ (id)projectWithName:(NSString *)name;

/// Open a project that holds the given URL.
+ (id)projectWithURL:(NSURL *)url;

/// Creates a project with the given name in the projects directory if possible.
+ (id)createProjectWithName:(NSString *)name;

/// Creates a new project by decompressing the provided archive file.
+ (id)createProjectWithName:(NSString *)name fromArchiveURL:(NSURL *)achiveURL;

#pragma mark Initializing and exporting projects

/// Initialize a new project residing in the given URL.
- (id)initWithURL:(NSURL *)url;

/// Saves the project to disk.
- (void)flush;

/// Compress the project and saves it to the given URL.
- (BOOL)compressProjectToURL:(NSURL *)exportUrl;

#pragma mark Locating the project

/// The directory URL of the project
@property (nonatomic, strong, readonly) NSURL *URL;

/// The name of the project. Changing this property will result in the project URL to move.
@property (nonatomic, strong) NSString *name;

#pragma mark Managing project content

/// A color to be used to identify the project.
@property (nonatomic, strong) UIColor *labelColor;

/// Access the bookmarks.
@property (nonatomic, copy, readonly) NSArray *bookmarks;

- (void)addBookmarkWithFileURL:(NSURL *)fileURL line:(NSUInteger)line note:(NSString *)note;
- (void)removeBookmark:(ProjectBookmark *)bookmark;
- (NSArray *)bookmarksForFile:(NSURL *)fileURL atLine:(NSUInteger)lineNumber;

/// Access the remotes stored for the project.
@property (nonatomic, copy, readonly) NSArray *remotes;

- (void)addRemote:(ProjectRemote *)remote;
- (void)removeRemote:(ProjectRemote *)remote;

@end


/// Represent a bookmark in a file of the project. 
@interface ProjectBookmark : NSObject

@property (nonatomic, weak, readonly) ArtCodeProject *project;

/// The actual path saved as the bookmark relative to the project URL and containing 
/// fragment informations.
@property (nonatomic, strong, readonly) NSString *bookmarkPath;

/// URL relative to the project root of the file that contain the bookmark.
/// The URL also encode the range of the bookmark.
@property (nonatomic, strong, readonly) NSURL *URL;

/// Notes connected with the bookmark.
@property (nonatomic, strong) NSString *note;

/// Returns the line in the file URL 
- (NSUInteger)line;

@end


@interface ProjectRemote : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *scheme;
@property (nonatomic, strong) NSString *host;
@property (nonatomic) NSInteger port;
@property (nonatomic, strong) NSString *user;
/// The password will be stored in the keychain for the service: sheme://host:port and the gien user
@property (nonatomic, strong) NSString *password;

- (NSURL *)URL;

@end
