//
//  ArtCodeURL.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACProject;

typedef enum {
  ArtCodeURLTypeProjectsList,
  ArtCodeURLTypeProject,
  ArtCodeURLTypeDirectory,
  ArtCodeURLTypeFile,
  ArtCodeURLTypeTextFile,
  ArtCodeURLTypeBookmarksList,
  ArtCodeURLTypeBookmark,
  ArtCodeURLTypeRemotesList,
  ArtCodeURLTypeRemote,
  ArtCodeURLTypeDocset,
} ArtCodeURLType;

@interface ArtCodeURL : NSObject

/// Create a new ArtCodeURL encoding the project, type and path.
+ (ArtCodeURL *)artCodeURLWithProject:(ACProject *)project type:(ArtCodeURLType)type path:(NSString *)path;

+ (ArtCodeURL *)artCodeRemoteURLWithProject:(ACProject *)project name:(NSString *)name url:(NSURL *)url;

- (NSString *)stringRepresentation;

- (id)initWithStringRepresentation:(NSString *)string;

/// Get a mask indicating properties of the URL. See ArtCodeURLType enum for more informations.
- (ArtCodeURLType)artCodeType;

#pragma mark Top level URLs

/// Returns YES if the URL has an ArtCode scheme
- (BOOL)isArtCodeURL;

/// Indicates if the URL points to the global projects list
/// ie: the URL is in the format artcode://projects
- (BOOL)isArtCodeProjectsList;

/// Indicates if the URL points to a projects' bookmark list
/// ie: the URL is in the format artcode://<project uuid>/bookmarks
- (BOOL)isArtCodeProjectBookmarksList;

/// Indicates if the URL points to a projects' bookmark list
/// ie: the URL is in the format artcode://<project uuid>/remotes
- (BOOL)isArtCodeProjectRemotesList;

#pragma mark URL specific

/// Indicate if the URL is a directory.
- (BOOL)isArtCodeDirectory;
- (BOOL)isArtCodeProject;
- (BOOL)isArtCodeFile;
- (BOOL)isArtCodeTextFile;
- (BOOL)isArtCodeRemote;
- (BOOL)isArtCodeFileBookmark;
- (BOOL)isArtCodeDocset;

/// Returns a file:// URL from either an artcode or a file URL.
- (NSURL *)artCodeURLToActualURL;

/// Returns the name of the ArtCodeRemote URL
- (NSString *)artCodeRemoteName;

- (id)artCodeBookmarkPoint;

- (NSString *)name;

- (NSString *)fileExtension;

- (NSString *)projectName;

- (NSString *)path;

- (NSString *)prettyPath;

@end

