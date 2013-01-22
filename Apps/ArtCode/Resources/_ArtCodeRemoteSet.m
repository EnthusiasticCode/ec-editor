// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemoteSet.m instead.

#import "_ArtCodeRemoteSet.h"

const struct ArtCodeRemoteSetAttributes ArtCodeRemoteSetAttributes = {
	.activeTabIndex = @"activeTabIndex",
	.name = @"name",
};

const struct ArtCodeRemoteSetRelationships ArtCodeRemoteSetRelationships = {
	.remotes = @"remotes",
};

const struct ArtCodeRemoteSetFetchedProperties ArtCodeRemoteSetFetchedProperties = {
};

@implementation ArtCodeRemoteSetID
@end

@implementation _ArtCodeRemoteSet

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"RemoteSet" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"RemoteSet";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"RemoteSet" inManagedObjectContext:moc_];
}

- (ArtCodeRemoteSetID*)objectID {
	return (ArtCodeRemoteSetID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"activeTabIndexValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"activeTabIndex"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic activeTabIndex;



- (int16_t)activeTabIndexValue {
	NSNumber *result = [self activeTabIndex];
	return [result shortValue];
}

- (void)setActiveTabIndexValue:(int16_t)value_ {
	[self setActiveTabIndex:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveActiveTabIndexValue {
	NSNumber *result = [self primitiveActiveTabIndex];
	return [result shortValue];
}

- (void)setPrimitiveActiveTabIndexValue:(int16_t)value_ {
	[self setPrimitiveActiveTabIndex:[NSNumber numberWithShort:value_]];
}





@dynamic name;






@dynamic remotes;

	
- (NSMutableOrderedSet*)remotesSet {
	[self willAccessValueForKey:@"remotes"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"remotes"];
  
	[self didAccessValueForKey:@"remotes"];
	return result;
}
	






@end
