// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemote.m instead.

#import "_ArtCodeRemote.h"

const struct ArtCodeRemoteAttributes ArtCodeRemoteAttributes = {
	.name = @"name",
	.urlString = @"urlString",
};

const struct ArtCodeRemoteRelationships ArtCodeRemoteRelationships = {
	.project = @"project",
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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic urlString;






@dynamic project;

	

@dynamic visitedLocations;

	
- (NSMutableSet*)visitedLocationsSet {
	[self willAccessValueForKey:@"visitedLocations"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"visitedLocations"];
  
	[self didAccessValueForKey:@"visitedLocations"];
	return result;
}
	






@end
