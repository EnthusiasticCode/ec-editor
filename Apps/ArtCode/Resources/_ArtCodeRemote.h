// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemote.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeRemoteAttributes {
	__unsafe_unretained NSString *host;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *path;
	__unsafe_unretained NSString *port;
	__unsafe_unretained NSString *scheme;
	__unsafe_unretained NSString *user;
} ArtCodeRemoteAttributes;

extern const struct ArtCodeRemoteRelationships {
	__unsafe_unretained NSString *remoteSet;
	__unsafe_unretained NSString *visitedLocations;
} ArtCodeRemoteRelationships;

extern const struct ArtCodeRemoteFetchedProperties {
} ArtCodeRemoteFetchedProperties;

@class ArtCodeRemoteSet;
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





@property (nonatomic, strong) NSString* scheme;



//- (BOOL)validateScheme:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* user;



//- (BOOL)validateUser:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) ArtCodeRemoteSet *remoteSet;

//- (BOOL)validateRemoteSet:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *visitedLocations;

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




- (NSString*)primitiveScheme;
- (void)setPrimitiveScheme:(NSString*)value;




- (NSString*)primitiveUser;
- (void)setPrimitiveUser:(NSString*)value;





- (ArtCodeRemoteSet*)primitiveRemoteSet;
- (void)setPrimitiveRemoteSet:(ArtCodeRemoteSet*)value;



- (NSMutableSet*)primitiveVisitedLocations;
- (void)setPrimitiveVisitedLocations:(NSMutableSet*)value;


@end
