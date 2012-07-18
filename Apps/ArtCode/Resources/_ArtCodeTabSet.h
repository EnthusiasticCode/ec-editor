// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ArtCodeTabSet.h instead.

#import <CoreData/CoreData.h>


extern const struct ArtCodeTabSetAttributes {
	__unsafe_unretained NSString *activeTabIndex;
	__unsafe_unretained NSString *name;
} ArtCodeTabSetAttributes;

extern const struct ArtCodeTabSetRelationships {
	__unsafe_unretained NSString *tabs;
} ArtCodeTabSetRelationships;

extern const struct ArtCodeTabSetFetchedProperties {
} ArtCodeTabSetFetchedProperties;

@class ArtCodeTab;




@interface ArtCodeTabSetID : NSManagedObjectID {}
@end

@interface _ArtCodeTabSet : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ArtCodeTabSetID*)objectID;




@property (nonatomic, strong) NSNumber* activeTabIndex;


@property int16_t activeTabIndexValue;
- (int16_t)activeTabIndexValue;
- (void)setActiveTabIndexValue:(int16_t)value_;

//- (BOOL)validateActiveTabIndex:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet* tabs;

- (NSMutableOrderedSet*)tabsSet;





@end

@interface _ArtCodeTabSet (CoreDataGeneratedAccessors)

- (void)addTabs:(NSOrderedSet*)value_;
- (void)removeTabs:(NSOrderedSet*)value_;
- (void)addTabsObject:(ArtCodeTab*)value_;
- (void)removeTabsObject:(ArtCodeTab*)value_;

@end

@interface _ArtCodeTabSet (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveActiveTabIndex;
- (void)setPrimitiveActiveTabIndex:(NSNumber*)value;

- (int16_t)primitiveActiveTabIndexValue;
- (void)setPrimitiveActiveTabIndexValue:(int16_t)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableOrderedSet*)primitiveTabs;
- (void)setPrimitiveTabs:(NSMutableOrderedSet*)value;


@end
