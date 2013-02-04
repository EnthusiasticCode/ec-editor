// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeLocation.m instead.

#import "_ArtCodeLocation.h"

const struct ArtCodeLocationAttributes ArtCodeLocationAttributes = {
	.data = @"data",
};

const struct ArtCodeLocationRelationships ArtCodeLocationRelationships = {
	.tab = @"tab",
};

const struct ArtCodeLocationFetchedProperties ArtCodeLocationFetchedProperties = {
};

@implementation ArtCodeLocationID
@end

@implementation _ArtCodeLocation

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Location";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Location" inManagedObjectContext:moc_];
}

- (ArtCodeLocationID*)objectID {
	return (ArtCodeLocationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic data;






@dynamic tab;

	






@end
