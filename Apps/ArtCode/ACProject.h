//
//  ACProject.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 14/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ACProjectMergeConflictPolicyKeepBoth,
    ACProjectMergeConflictPolicyKeepOriginal,
    ACProjectMergeConflictPolicyKeepNew
} ACProjectMergeConflictPolicy;


@interface ACProject : NSObject

/// Returns the URL in which projects are stored
+ (NSURL *)projectsDirectory;

/// Gets the project name from an URL or nil if no project was found.
/// Uppon return, in isProjectRoot is not NULL, it will contain a value indicating if the given URL is a project root.
+ (NSString *)projectNameFromURL:(NSURL *)url isProjectRoot:(BOOL *)isProjectRoot;

/// Returns a value indicating if the project with the given name exists.
+ (BOOL)projectWithNameExists:(NSString *)name;

/// Returns a name which does not conflict with a project name in the projects directory.
+ (NSString *)validNameForNewProjectName:(NSString *)name;

/// Returns a project URL from a project name. This method does not check for existance of the project.
+ (NSURL *)projectURLFromName:(NSString *)name;

/// Open or create a project with the given name in the projects directory.
+ (id)projectWithName:(NSString *)name;

/// Open or create a project that holds the given URL.
+ (id)projectWithURL:(NSURL *)url;

#pragma mark Initializing and exporting projects

/// Initialize a new project residing in the given URL.
- (id)initWithURL:(NSURL *)url;

/// Initialize a new project by decompressing the given file to the specified location.
- (id)initByDecompressingFileAtURL:(NSURL *)compressedFileUrl toURL:(NSURL *)url;

/// Saves the project to disk.
- (void)flush;

/// Compress the project and saves it to the given URL.
- (BOOL)compressProjectToURL:(NSURL *)exportUrl;

/// Gets the content of the given URL and merge it to the content of the project.
/// The conflict resolver block is used whenever a file in the project should be ovverriden to complete the merge. 
/// If no conflict resolution is provided, both files are kept; meaning that the source file will be renamed.
- (void)mergeFilesFromDirectoryWithURL:(NSURL *)mergeUrl conflictResolver:(ACProjectMergeConflictPolicy(^)(NSURL *mergeSourceUrl, NSURL *mergeDestinationUrl))conflictResolver;

#pragma mark Locating the project

/// The directory URL of the project
@property (nonatomic, strong, readonly) NSURL *URL;

/// The name of the project. Changing this property will result in the project URL to move.
@property (nonatomic, strong) NSString *name;

#pragma mark Managing project content

/// A color to be used to identify the project.
@property (nonatomic, strong) UIColor *labelColor;

// TODO bookmarks

@end
