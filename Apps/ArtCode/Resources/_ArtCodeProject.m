// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeProject.m instead.

#import "_ArtCodeProject.h"

const struct ArtCodeProjectAttributes ArtCodeProjectAttributes = {
	.labelColorString = @"labelColorString",
	.name = @"name",
	.newlyCreated = @"newlyCreated",
};

const struct ArtCodeProjectRelationships ArtCodeProjectRelationships = {
	.projectSet = @"projectSet",
	.remotes = @"remotes",
	.visitedLocations = @"visitedLocations",
};

const struct ArtCodeProjectFetchedProperties ArtCodeProjectFetchedProperties = {
};

@implementation ArtCodeProjectID
@end

@implementation _ArtCodeProject

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Project";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Project" inManagedObjectContext:moc_];
}

- (ArtCodeProjectID*)objectID {
	return (ArtCodeProjectID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"newlyCreatedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"newlyCreated"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic labelColorString;






@dynamic name;






@dynamic newlyCreated;



- (BOOL)newlyCreatedValue {
	NSNumber *result = [self newlyCreated];
	return [result boolValue];
}

- (void)setNewlyCreatedValue:(BOOL)value_ {
	[self setNewlyCreated:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveNewlyCreatedValue {
	NSNumber *result = [self primitiveNewlyCreated];
	return [result boolValue];
}

- (void)setPrimitiveNewlyCreatedValue:(BOOL)value_ {
	[self setPrimitiveNewlyCreated:[NSNumber numberWithBool:value_]];
}





@dynamic projectSet;

	

@dynamic remotes;

	
- (NSMutableOrderedSet*)remotesSet {
	[self willAccessValueForKey:@"remotes"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"remotes"];
  
	[self didAccessValueForKey:@"remotes"];
	return result;
}
	

@dynamic visitedLocations;

	
- (NSMutableSet*)visitedLocationsSet {
	[self willAccessValueForKey:@"visitedLocations"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"visitedLocations"];
  
	[self didAccessValueForKey:@"visitedLocations"];
	return result;
}
	






@end
