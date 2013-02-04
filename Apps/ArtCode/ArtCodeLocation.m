//
//  ArtCodeLocation.m
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeLocation.h"
#import "NSString+Utilities.h"
#import "NSURL+Utilities.h"
#import "NSURL+ArtCode.h"

@implementation ArtCodeLocation

- (ArtCodeLocationType)type {
	return [self[ArtCodeLocationAttributeKeys.type] unsignedIntegerValue];
}

- (NSString *)name {
	return self[ArtCodeLocationAttributeKeys.name];
}

- (NSURL *)url {
	return self[ArtCodeLocationAttributeKeys.url];
}

- (id)objectForKeyedSubscript:(id)key {
	return self.dictionary[key];
}

- (NSDictionary *)dictionary {
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
	if ([dictionary[ArtCodeLocationAttributeKeys.url] isKindOfClass:NSData.class]) {
		NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
		mutableDictionary[ArtCodeLocationAttributeKeys.url] = [NSURL URLByResolvingBookmarkData:dictionary[ArtCodeLocationAttributeKeys.url] options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:NULL error:NULL];
		dictionary = mutableDictionary.copy;
	}
	if (dictionary[ArtCodeLocationAttributeKeys.name] == nil) {
		NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
		mutableDictionary[ArtCodeLocationAttributeKeys.name] = [dictionary[ArtCodeLocationAttributeKeys.url] lastPathComponent];
		dictionary = mutableDictionary.copy;
	}
	return dictionary;
}

@end

#pragma mark -

@implementation ArtCodeTab (Location)

- (void)pushLocationWithDictionary:(NSDictionary *)dictionary {
  ArtCodeLocation *location = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
	if ([dictionary[ArtCodeLocationAttributeKeys.name] isEqual:[dictionary[ArtCodeLocationAttributeKeys.url] lastPathComponent]]) {
		NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
		[mutableDictionary removeObjectForKey:ArtCodeLocationAttributeKeys.name];
		dictionary = mutableDictionary.copy;
	}
	if ([dictionary[ArtCodeLocationAttributeKeys.url] isFileURL]) {
		NSData *bookmarkData = [dictionary[ArtCodeLocationAttributeKeys.url] bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark | NSURLBookmarkCreationPreferFileIDResolution includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
		NSMutableDictionary *mutableDictionary = dictionary.mutableCopy;
		mutableDictionary[ArtCodeLocationAttributeKeys.url] = bookmarkData;
		dictionary = mutableDictionary.copy;
	}
	location.data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
  [self pushLocation:location];
}

@end
