// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeLocation.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeLocationAttributes {
	__unsafe_unretained NSString *dataString;
	__unsafe_unretained NSString *typeInt16;
} ArtCodeLocationAttributes;

extern const struct ArtCodeLocationRelationships {
	__unsafe_unretained NSString *project;
	__unsafe_unretained NSString *tab;
} ArtCodeLocationRelationships;

extern const struct ArtCodeLocationFetchedProperties {
} ArtCodeLocationFetchedProperties;

@class ArtCodeProject;
@class ArtCodeTab;




@interface ArtCodeLocationID : NSManagedObjectID {}
@end

@interface _ArtCodeLocation : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeLocationID*)objectID;




@property (nonatomic, strong) NSString* dataString;


//- (BOOL)validateDataString:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* typeInt16;


@property int16_t typeInt16Value;
- (int16_t)typeInt16Value;
- (void)setTypeInt16Value:(int16_t)value_;

//- (BOOL)validateTypeInt16:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) ArtCodeProject* project;

//- (BOOL)validateProject:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) ArtCodeTab* tab;

//- (BOOL)validateTab:(id*)value_ error:(NSError**)error_;





@end

@interface _ArtCodeLocation (CoreDataGeneratedAccessors)

@end

@interface _ArtCodeLocation (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveDataString;
- (void)setPrimitiveDataString:(NSString*)value;




- (NSNumber*)primitiveTypeInt16;
- (void)setPrimitiveTypeInt16:(NSNumber*)value;

- (int16_t)primitiveTypeInt16Value;
- (void)setPrimitiveTypeInt16Value:(int16_t)value_;





- (ArtCodeProject*)primitiveProject;
- (void)setPrimitiveProject:(ArtCodeProject*)value;



- (ArtCodeTab*)primitiveTab;
- (void)setPrimitiveTab:(ArtCodeTab*)value;


@end
