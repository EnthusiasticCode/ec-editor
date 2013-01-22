// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeTab.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeTabAttributes {
	__unsafe_unretained NSString *currentPosition;
} ArtCodeTabAttributes;

extern const struct ArtCodeTabRelationships {
	__unsafe_unretained NSString *history;
	__unsafe_unretained NSString *tabSet;
} ArtCodeTabRelationships;

extern const struct ArtCodeTabFetchedProperties {
} ArtCodeTabFetchedProperties;

@class ArtCodeLocation;
@class ArtCodeTabSet;



@interface ArtCodeTabID : NSManagedObjectID {}
@end

@interface _ArtCodeTab : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeTabID*)objectID;





@property (nonatomic, strong) NSNumber* currentPosition;



@property int16_t currentPositionValue;
- (int16_t)currentPositionValue;
- (void)setCurrentPositionValue:(int16_t)value_;

//- (BOOL)validateCurrentPosition:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet *history;

- (NSMutableOrderedSet*)historySet;




@property (nonatomic, strong) ArtCodeTabSet *tabSet;

//- (BOOL)validateTabSet:(id*)value_ error:(NSError**)error_;





@end

@interface _ArtCodeTab (CoreDataGeneratedAccessors)

- (void)addHistory:(NSOrderedSet*)value_;
- (void)removeHistory:(NSOrderedSet*)value_;
- (void)addHistoryObject:(ArtCodeLocation*)value_;
- (void)removeHistoryObject:(ArtCodeLocation*)value_;

@end

@interface _ArtCodeTab (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveCurrentPosition;
- (void)setPrimitiveCurrentPosition:(NSNumber*)value;

- (int16_t)primitiveCurrentPositionValue;
- (void)setPrimitiveCurrentPositionValue:(int16_t)value_;





- (NSMutableOrderedSet*)primitiveHistory;
- (void)setPrimitiveHistory:(NSMutableOrderedSet*)value;



- (ArtCodeTabSet*)primitiveTabSet;
- (void)setPrimitiveTabSet:(ArtCodeTabSet*)value;


@end
