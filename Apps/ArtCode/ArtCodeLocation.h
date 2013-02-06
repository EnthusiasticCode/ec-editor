//
//  ArtCodeLocation.h
//  ArtCode
//
//  Created by Uri Baghin on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeLocation.h"
#import "ArtCodeTab.h"

// Indicates the type of the location. See ArtCodeLocationType enum for more informations.
extern const struct ArtCodeLocationAttributeKeys {
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *url;
} ArtCodeLocationAttributeKeys;

typedef enum : NSUInteger {
  ArtCodeLocationTypeUndefined = 0,
  ArtCodeLocationTypeProjectsList,
  ArtCodeLocationTypeDirectory,
  ArtCodeLocationTypeTextFile,
  ArtCodeLocationTypeBookmarksList,
  ArtCodeLocationTypeRemotesList,
	ArtCodeLocationTypeRemote,
} ArtCodeLocationType;

// Being a CoreData object, a location should be created using the methods in it's parent ArtCodeTab.
@interface ArtCodeLocation : _ArtCodeLocation

// Indicates the type of the location. See ArtCodeLocationType enum for more informations.
- (ArtCodeLocationType)type;

// Returns a useful name for the location. Usually the file name if present.
- (NSString *)name;

- (NSURL *)url;

// Returns the attribute of the location for the given key. See ArtCodeLocationAttributeKeys for keys.
- (id)objectForKeyedSubscript:(id)key;

- (NSDictionary *)dictionary;

@end

@interface ArtCodeTab (Location)

// Push a new location with the given attributes. See ArtCodeLocationAttributeKeys for keys.
- (void)pushLocationWithDictionary:(NSDictionary *)dictionary;

@end
