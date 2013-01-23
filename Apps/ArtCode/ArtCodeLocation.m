//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeLocation.h"
#import "ArtCodeRemote.h"
#import "NSString+Utilities.h"
#import "NSURL+Utilities.h"
#import "NSURL+ArtCode.h"

static NSString * const ArtCodeLocationDataBookmarkDataKey = @"BookmarkData";
static NSString * const ArtCodeLocationDataRemotePathKey = @"RemotePath";

#pragma mark -

@interface ArtCodeTab (ArtCodeLocation_Internal)

/// Pushes the location built with the given parameters
- (void)pushLocationWithType:(ArtCodeLocationType)type remote:(ArtCodeRemote *)remote dataDictionary:(NSDictionary *)dataDictionary;

@end

#pragma mark -

@implementation ArtCodeLocation

- (ArtCodeLocationType)type {
  return self.typeInt16Value;
}

- (void)setType:(ArtCodeLocationType)type {
  self.typeInt16Value = type;
}

+ (NSSet *)keyPathsForValuesAffectingType {
  return [NSSet setWithObjects:@"typeInt16Value", nil];
}

#pragma mark Data Properties

- (NSURL *)url {
  switch (self.type) {
    case ArtCodeLocationTypeDirectory:
    case ArtCodeLocationTypeTextFile:
    {
      // If a file, dataDictionary contains a bookmark data URL
      BOOL isStale = NO;
      NSURL *url = [NSURL URLByResolvingBookmarkData:self.dataDictionary[ArtCodeLocationDataBookmarkDataKey] options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&isStale error:NULL];
      // TODO: do something if it's stale
      return url;
    }
      
    case ArtCodeLocationTypeRemoteDirectory:
    {
      // If a remote directory location, dataDictionary contains a path
      return [self.remote.url URLByAppendingPathComponent:self.dataDictionary[ArtCodeLocationDataRemotePathKey]];
    }
      
    default:
      return nil;
  }
}

- (NSString *)name {
  return self.url.lastPathComponent;
}

- (NSString *)fileExtension {
  return self.url.pathExtension;
}

- (NSString *)path {
  NSString *path = self.url.path;
  switch (self.type) {
    case ArtCodeLocationTypeDirectory:
    case ArtCodeLocationTypeTextFile:
		{
      path = [self.url pathRelativeToURL:NSURL.projectsListDirectory];
    }
      
    default:
      break;
  }
  return path;
}

- (NSString *)prettyPath {
  return self.path.prettyPath;
}

- (NSDictionary *)dataDictionary {
	if (!self.data) return nil;
	NSDictionary *dict = nil;
	@try {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.data];
		dict = [unarchiver decodeObject];
		[unarchiver finishDecoding];
	}
	@catch (NSException *exception) {
    dict = nil;
	}
	return dict;
}

- (void)setDataDictionary:(NSDictionary *)dataDictionary {
	NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:dataDictionary];
	[archiver finishEncoding];
	self.data = data;
}

@end

#pragma mark -

@implementation ArtCodeTab (Location)

- (void)pushProjectsList {
  [self pushLocationWithType:ArtCodeLocationTypeProjectsList remote:nil dataDictionary:nil];
}

- (void)pushFileURL:(NSURL *)url {
  [self pushFileURL:url dataDictionary:nil];
}

- (void)pushFileURL:(NSURL *)url dataDictionary:(NSDictionary *)dict {
	ASSERT(url);
	NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark | NSURLBookmarkCreationPreferFileIDResolution includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
	NSMutableDictionary *newDict = dict ? [dict mutableCopy] : [NSMutableDictionary dictionary];
	newDict[ArtCodeLocationDataBookmarkDataKey] = bookmarkData;
  if (url.isDirectory) {
		[self pushLocationWithType:ArtCodeLocationTypeDirectory remote:nil dataDictionary:newDict];
  } else {
    [self pushLocationWithType:ArtCodeLocationTypeTextFile remote:nil dataDictionary:newDict];
  }
}

- (void)pushBookmarksList {
  [self pushLocationWithType:ArtCodeLocationTypeBookmarksList remote:nil dataDictionary:nil];
}

- (void)pushRemotesList {
  [self pushLocationWithType:ArtCodeLocationTypeRemotesList remote:nil dataDictionary:nil];
}

- (void)pushRemotePath:(NSString *)path withRemote:(ArtCodeRemote *)remote {
  ASSERT(path && remote);
  [self pushLocationWithType:ArtCodeLocationTypeRemoteDirectory remote:remote dataDictionary:@{ ArtCodeLocationDataRemotePathKey : [path copy] }];
}

@end

#pragma mark -

@implementation ArtCodeTab (ArtCodeLocation_Internal)

- (void)pushLocationWithType:(ArtCodeLocationType)type remote:(ArtCodeRemote *)remote dataDictionary:(NSDictionary *)dataDictionary {
  ArtCodeLocation *location = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
  if (type) {
    location.type = type;
  }
  if (remote) {
    location.remote = remote;
  }
  if (dataDictionary) {
    location.dataDictionary = dataDictionary;
  }
  [self pushLocation:location];
}

@end
