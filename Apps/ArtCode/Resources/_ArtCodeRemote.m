// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemote.m instead.

#import "_ArtCodeRemote.h"

const struct ArtCodeRemoteAttributes ArtCodeRemoteAttributes = {
	.host = @"host",
	.name = @"name",
	.path = @"path",
	.port = @"port",
	.scheme = @"scheme",
	.user = @"user",
};

const struct ArtCodeRemoteRelationships ArtCodeRemoteRelationships = {
	.remoteSet = @"remoteSet",
	.visitedLocations = @"visitedLocations",
};

const struct ArtCodeRemoteFetchedProperties ArtCodeRemoteFetchedProperties = {
};

@implementation ArtCodeRemoteID
@end

@implementation _ArtCodeRemote

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Remote" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Remote";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Remote" inManagedObjectContext:moc_];
}

- (ArtCodeRemoteID*)objectID {
	return (ArtCodeRemoteID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"portValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"port"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic host;






@dynamic name;






@dynamic path;






@dynamic port;



- (int16_t)portValue {
	NSNumber *result = [self port];
	return [result shortValue];
}

- (void)setPortValue:(int16_t)value_ {
	[self setPort:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitivePortValue {
	NSNumber *result = [self primitivePort];
	return [result shortValue];
}

- (void)setPrimitivePortValue:(int16_t)value_ {
	[self setPrimitivePort:[NSNumber numberWithShort:value_]];
}





@dynamic scheme;






@dynamic user;






@dynamic remoteSet;

	

@dynamic visitedLocations;

	
- (NSMutableSet*)visitedLocationsSet {
	[self willAccessValueForKey:@"visitedLocations"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"visitedLocations"];
  
	[self didAccessValueForKey:@"visitedLocations"];
	return result;
}
	






@end
