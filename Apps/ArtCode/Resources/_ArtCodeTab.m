// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeTab.m instead.

#import "_ArtCodeTab.h"

const struct ArtCodeTabAttributes ArtCodeTabAttributes = {
	.currentPosition = @"currentPosition",
};

const struct ArtCodeTabRelationships ArtCodeTabRelationships = {
	.history = @"history",
	.tabSet = @"tabSet",
};

const struct ArtCodeTabFetchedProperties ArtCodeTabFetchedProperties = {
};

@implementation ArtCodeTabID
@end

@implementation _ArtCodeTab

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Tab" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Tab";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Tab" inManagedObjectContext:moc_];
}

- (ArtCodeTabID*)objectID {
	return (ArtCodeTabID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"currentPositionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"currentPosition"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic currentPosition;



- (int16_t)currentPositionValue {
	NSNumber *result = [self currentPosition];
	return [result shortValue];
}

- (void)setCurrentPositionValue:(int16_t)value_ {
	[self setCurrentPosition:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveCurrentPositionValue {
	NSNumber *result = [self primitiveCurrentPosition];
	return [result shortValue];
}

- (void)setPrimitiveCurrentPositionValue:(int16_t)value_ {
	[self setPrimitiveCurrentPosition:[NSNumber numberWithShort:value_]];
}





@dynamic history;

	
- (NSMutableOrderedSet*)historySet {
	[self willAccessValueForKey:@"history"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"history"];
  
	[self didAccessValueForKey:@"history"];
	return result;
}
	

@dynamic tabSet;

	






@end
