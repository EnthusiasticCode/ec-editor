// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeLocation.m instead.

#import "_ArtCodeLocation.h"

const struct ArtCodeLocationAttributes ArtCodeLocationAttributes = {
	.dataString = @"dataString",
	.typeInt16 = @"typeInt16",
};

const struct ArtCodeLocationRelationships ArtCodeLocationRelationships = {
	.project = @"project",
	.tabs = @"tabs",
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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"typeInt16Value"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"typeInt16"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic dataString;






@dynamic typeInt16;



- (int16_t)typeInt16Value {
	NSNumber *result = [self typeInt16];
	return [result shortValue];
}

- (void)setTypeInt16Value:(int16_t)value_ {
	[self setTypeInt16:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveTypeInt16Value {
	NSNumber *result = [self primitiveTypeInt16];
	return [result shortValue];
}

- (void)setPrimitiveTypeInt16Value:(int16_t)value_ {
	[self setPrimitiveTypeInt16:[NSNumber numberWithShort:value_]];
}





@dynamic project;

	

@dynamic tabs;

	
- (NSMutableSet*)tabsSet {
	[self willAccessValueForKey:@"tabs"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"tabs"];
  
	[self didAccessValueForKey:@"tabs"];
	return result;
}
	






@end
