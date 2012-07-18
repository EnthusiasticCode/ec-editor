// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeProjectSet.m instead.

#import "_ArtCodeProjectSet.h"

const struct ArtCodeProjectSetAttributes ArtCodeProjectSetAttributes = {
	.name = @"name",
};

const struct ArtCodeProjectSetRelationships ArtCodeProjectSetRelationships = {
	.projects = @"projects",
};

const struct ArtCodeProjectSetFetchedProperties ArtCodeProjectSetFetchedProperties = {
};

@implementation ArtCodeProjectSetID
@end

@implementation _ArtCodeProjectSet

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"ProjectSet" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"ProjectSet";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"ProjectSet" inManagedObjectContext:moc_];
}

- (ArtCodeProjectSetID*)objectID {
	return (ArtCodeProjectSetID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic projects;

	
- (NSMutableOrderedSet*)projectsSet {
	[self willAccessValueForKey:@"projects"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"projects"];
  
	[self didAccessValueForKey:@"projects"];
	return result;
}
	






@end
