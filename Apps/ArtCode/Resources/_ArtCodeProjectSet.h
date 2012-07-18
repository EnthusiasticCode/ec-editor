// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeProjectSet.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeProjectSetAttributes {
	__unsafe_unretained NSString *name;
} ArtCodeProjectSetAttributes;

extern const struct ArtCodeProjectSetRelationships {
	__unsafe_unretained NSString *projects;
} ArtCodeProjectSetRelationships;

extern const struct ArtCodeProjectSetFetchedProperties {
} ArtCodeProjectSetFetchedProperties;

@class ArtCodeProject;



@interface ArtCodeProjectSetID : NSManagedObjectID {}
@end

@interface _ArtCodeProjectSet : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeProjectSetID*)objectID;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet* projects;

- (NSMutableOrderedSet*)projectsSet;





@end

@interface _ArtCodeProjectSet (CoreDataGeneratedAccessors)

- (void)addProjects:(NSOrderedSet*)value_;
- (void)removeProjects:(NSOrderedSet*)value_;
- (void)addProjectsObject:(ArtCodeProject*)value_;
- (void)removeProjectsObject:(ArtCodeProject*)value_;

@end

@interface _ArtCodeProjectSet (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableOrderedSet*)primitiveProjects;
- (void)setPrimitiveProjects:(NSMutableOrderedSet*)value;


@end
