// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeProject.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeProjectAttributes {
	__unsafe_unretained NSString *labelColorString;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *newlyCreated;
} ArtCodeProjectAttributes;

extern const struct ArtCodeProjectRelationships {
	__unsafe_unretained NSString *projectSet;
	__unsafe_unretained NSString *remotes;
	__unsafe_unretained NSString *visitedLocations;
} ArtCodeProjectRelationships;

extern const struct ArtCodeProjectFetchedProperties {
} ArtCodeProjectFetchedProperties;

@class ArtCodeProjectSet;
@class ArtCodeRemote;
@class ArtCodeLocation;





@interface ArtCodeProjectID : NSManagedObjectID {}
@end

@interface _ArtCodeProject : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeProjectID*)objectID;




@property (nonatomic, strong) NSString* labelColorString;


//- (BOOL)validateLabelColorString:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* newlyCreated;


@property BOOL newlyCreatedValue;
- (BOOL)newlyCreatedValue;
- (void)setNewlyCreatedValue:(BOOL)value_;

//- (BOOL)validateNewlyCreated:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) ArtCodeProjectSet* projectSet;

//- (BOOL)validateProjectSet:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSOrderedSet* remotes;

- (NSMutableOrderedSet*)remotesSet;




@property (nonatomic, strong) NSSet* visitedLocations;

- (NSMutableSet*)visitedLocationsSet;





@end

@interface _ArtCodeProject (CoreDataGeneratedAccessors)

- (void)addRemotes:(NSOrderedSet*)value_;
- (void)removeRemotes:(NSOrderedSet*)value_;
- (void)addRemotesObject:(ArtCodeRemote*)value_;
- (void)removeRemotesObject:(ArtCodeRemote*)value_;

- (void)addVisitedLocations:(NSSet*)value_;
- (void)removeVisitedLocations:(NSSet*)value_;
- (void)addVisitedLocationsObject:(ArtCodeLocation*)value_;
- (void)removeVisitedLocationsObject:(ArtCodeLocation*)value_;

@end

@interface _ArtCodeProject (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveLabelColorString;
- (void)setPrimitiveLabelColorString:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveNewlyCreated;
- (void)setPrimitiveNewlyCreated:(NSNumber*)value;

- (BOOL)primitiveNewlyCreatedValue;
- (void)setPrimitiveNewlyCreatedValue:(BOOL)value_;





- (ArtCodeProjectSet*)primitiveProjectSet;
- (void)setPrimitiveProjectSet:(ArtCodeProjectSet*)value;



- (NSMutableOrderedSet*)primitiveRemotes;
- (void)setPrimitiveRemotes:(NSMutableOrderedSet*)value;



- (NSMutableSet*)primitiveVisitedLocations;
- (void)setPrimitiveVisitedLocations:(NSMutableSet*)value;


@end
