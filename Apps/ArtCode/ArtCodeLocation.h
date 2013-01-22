//
//  ArtCodeLocation.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeLocation.h"
#import "ArtCodeTab.h"

typedef enum {
  ArtCodeLocationTypeUnknown = 0,
  ArtCodeLocationTypeProjectsList,
  ArtCodeLocationTypeDirectory,
  ArtCodeLocationTypeTextFile,
  ArtCodeLocationTypeBookmarksList,
  ArtCodeLocationTypeRemotesList,
  ArtCodeLocationTypeRemoteDirectory,
} ArtCodeLocationType;

/// Being a CoreData object, a location should be created using the methods in it's parent ArtCodeTab.
@interface ArtCodeLocation : _ArtCodeLocation

/// Indicates the type of the location. See ArtCodeLocationType enum for more informations.
@property (nonatomic) ArtCodeLocationType type;

#pragma mark URL specific

/// Returns a file:// URL from either an artcode or a file URL.
- (NSURL *)url;

/// Returns a useful name for the location. Usually the file name if present.
- (NSString *)name;

- (NSString *)fileExtension;

/// The path from the project containing the file name included.
- (NSString *)path;

- (NSString *)prettyPath;

/// If the data is a dictionary, this method returns it.
@property (nonatomic, copy) NSDictionary *dataDictionary;

@end

@interface ArtCodeTab (Location)

- (void)pushProjectsList;

- (void)pushFileURL:(NSURL *)url;

- (void)pushFileURL:(NSURL *)url dataDictionary:(NSDictionary *)dict;

- (void)pushBookmarksList;

- (void)pushRemotesList;

- (void)pushRemotePath:(NSString *)path withRemote:(ArtCodeRemote *)remote;

@end
