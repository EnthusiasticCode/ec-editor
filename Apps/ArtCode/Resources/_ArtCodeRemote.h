// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemote.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeRemoteAttributes {
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *urlString;
} ArtCodeRemoteAttributes;

extern const struct ArtCodeRemoteRelationships {
	__unsafe_unretained NSString *project;
	__unsafe_unretained NSString *visitedLocations;
} ArtCodeRemoteRelationships;

extern const struct ArtCodeRemoteFetchedProperties {
} ArtCodeRemoteFetchedProperties;

@class ArtCodeProject;
@class ArtCodeLocation;




@interface ArtCodeRemoteID : NSManagedObjectID {}
@end

@interface _ArtCodeRemote : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeRemoteID*)objectID;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* urlString;


//- (BOOL)validateUrlString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) ArtCodeProject* project;

//- (BOOL)validateProject:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet* visitedLocations;

- (NSMutableSet*)visitedLocationsSet;





@end

@interface _ArtCodeRemote (CoreDataGeneratedAccessors)

- (void)addVisitedLocations:(NSSet*)value_;
- (void)removeVisitedLocations:(NSSet*)value_;
- (void)addVisitedLocationsObject:(ArtCodeLocation*)value_;
- (void)removeVisitedLocationsObject:(ArtCodeLocation*)value_;

@end

@interface _ArtCodeRemote (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveUrlString;
- (void)setPrimitiveUrlString:(NSString*)value;





- (ArtCodeProject*)primitiveProject;
- (void)setPrimitiveProject:(ArtCodeProject*)value;



- (NSMutableSet*)primitiveVisitedLocations;
- (void)setPrimitiveVisitedLocations:(NSMutableSet*)value;


@end
