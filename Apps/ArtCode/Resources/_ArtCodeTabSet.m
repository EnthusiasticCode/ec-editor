// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeTabSet.m instead.

#import "_ArtCodeTabSet.h"

const struct ArtCodeTabSetAttributes ArtCodeTabSetAttributes = {
	.activeTabIndex = @"activeTabIndex",
	.name = @"name",
};

const struct ArtCodeTabSetRelationships ArtCodeTabSetRelationships = {
	.tabs = @"tabs",
};

const struct ArtCodeTabSetFetchedProperties ArtCodeTabSetFetchedProperties = {
};

@implementation ArtCodeTabSetID
@end

@implementation _ArtCodeTabSet

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"TabSet" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"TabSet";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"TabSet" inManagedObjectContext:moc_];
}

- (ArtCodeTabSetID*)objectID {
	return (ArtCodeTabSetID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"activeTabIndexValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"activeTabIndex"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
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






@dynamic tabs;

	
- (NSMutableOrderedSet*)tabsSet {
	[self willAccessValueForKey:@"tabs"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"tabs"];
  
	[self didAccessValueForKey:@"tabs"];
	return result;
}
	






@end
