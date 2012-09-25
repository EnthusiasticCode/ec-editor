// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemote.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeRemoteAttributes {
	__unsafe_unretained NSString *host;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *path;
	__unsafe_unretained NSString *port;
	__unsafe_unretained NSString *schema;
	__unsafe_unretained NSString *user;
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




@property (nonatomic, strong) NSString* host;


//- (BOOL)validateHost:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* path;


//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* port;


@property int16_t portValue;
- (int16_t)portValue;
- (void)setPortValue:(int16_t)value_;

//- (BOOL)validatePort:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* schema;


//- (BOOL)validateSchema:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* user;


//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;





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


- (NSString*)primitiveHost;
- (void)setPrimitiveHost:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePath;
- (void)setPrimitivePath:(NSString*)value;




- (NSNumber*)primitivePort;
- (void)setPrimitivePort:(NSNumber*)value;

- (int16_t)primitivePortValue;
- (void)setPrimitivePortValue:(int16_t)value_;




- (NSString*)primitiveSchema;
- (void)setPrimitiveSchema:(NSString*)value;




- (NSString*)primitiveUser;
- (void)setPrimitiveUser:(NSString*)value;





- (ArtCodeProject*)primitiveProject;
- (void)setPrimitiveProject:(ArtCodeProject*)value;



- (NSMutableSet*)primitiveVisitedLocations;
- (void)setPrimitiveVisitedLocations:(NSMutableSet*)value;


@end
