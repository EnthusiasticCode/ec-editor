//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/NSURL.h>

@interface NSURL (Additions)

/// Returns the application's documents directory
+ (NSURL *)applicationDocumentsDirectory;

/// Returns the application's library directory
+ (NSURL *)applicationLibraryDirectory;

/// Returns a non-existing temporary directory
+ (NSURL *)temporaryDirectory;

/// Returns a non-existing file URL with .tmp extension
+ (NSURL *)temporaryFileURL;

/// Returns whether the receiver is a descendant of a subdirectory of the given directory
- (BOOL)isSubdirectoryDescendantOfDirectoryAtURL:(NSURL *)directoryURL;

/// Returns whether the receiver refers to a hidden file
- (BOOL)isHidden;
- (BOOL)isHiddenDescendant;

/// Returns whether the receiver refers to a package
- (BOOL)isPackage;
- (BOOL)isPackageDescendant;

/// Returns whether the fileURL refers to a directory. Uses resource value.
- (BOOL)isDirectory;

/// Create a new URL that has the given number before the URL extension in brackets.
/// /url/to/file.ext become /url/to/file (number).ext
- (NSURL *)URLByAddingDuplicateNumber:(NSUInteger)number;

- (NSString *)pathRelativeToURL:(NSURL *)url;

/// Substitute / with ▸
- (NSString *)prettyPath;

@end
