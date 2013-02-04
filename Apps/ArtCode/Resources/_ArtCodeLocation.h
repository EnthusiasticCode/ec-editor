// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeLocation.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeLocationAttributes {
	__unsafe_unretained NSString *data;
} ArtCodeLocationAttributes;

extern const struct ArtCodeLocationRelationships {
	__unsafe_unretained NSString *tab;
} ArtCodeLocationRelationships;

extern const struct ArtCodeLocationFetchedProperties {
} ArtCodeLocationFetchedProperties;

@class ArtCodeTab;



@interface ArtCodeLocationID : NSManagedObjectID {}
@end

@interface _ArtCodeLocation : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeLocationID*)objectID;





@property (nonatomic, strong) NSData* data;



//- (BOOL)validateData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) ArtCodeTab *tab;

//- (BOOL)validateTab:(id*)value_ error:(NSError**)error_;





@end

@interface _ArtCodeLocation (CoreDataGeneratedAccessors)

@end

@interface _ArtCodeLocation (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveData;
- (void)setPrimitiveData:(NSData*)value;





- (ArtCodeTab*)primitiveTab;
- (void)setPrimitiveTab:(ArtCodeTab*)value;


@end
