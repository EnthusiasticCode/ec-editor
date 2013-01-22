// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeRemoteSet.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeRemoteSetAttributes {
	__unsafe_unretained NSString *activeTabIndex;
	__unsafe_unretained NSString *name;
} ArtCodeRemoteSetAttributes;

extern const struct ArtCodeRemoteSetRelationships {
	__unsafe_unretained NSString *remotes;
} ArtCodeRemoteSetRelationships;

extern const struct ArtCodeRemoteSetFetchedProperties {
} ArtCodeRemoteSetFetchedProperties;

@class ArtCodeRemote;




@interface ArtCodeRemoteSetID : NSManagedObjectID {}
@end

@interface _ArtCodeRemoteSet : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeRemoteSetID*)objectID;





@property (nonatomic, strong) NSNumber* activeTabIndex;



@property int16_t activeTabIndexValue;
- (int16_t)activeTabIndexValue;
- (void)setActiveTabIndexValue:(int16_t)value_;

//- (BOOL)validateActiveTabIndex:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet *remotes;

- (NSMutableOrderedSet*)remotesSet;





@end

@interface _ArtCodeRemoteSet (CoreDataGeneratedAccessors)

- (void)addRemotes:(NSOrderedSet*)value_;
- (void)removeRemotes:(NSOrderedSet*)value_;
- (void)addRemotesObject:(ArtCodeRemote*)value_;
- (void)removeRemotesObject:(ArtCodeRemote*)value_;

@end

@interface _ArtCodeRemoteSet (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveActiveTabIndex;
- (void)setPrimitiveActiveTabIndex:(NSNumber*)value;

- (int16_t)primitiveActiveTabIndexValue;
- (void)setPrimitiveActiveTabIndexValue:(int16_t)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableOrderedSet*)primitiveRemotes;
- (void)setPrimitiveRemotes:(NSMutableOrderedSet*)value;


@end
