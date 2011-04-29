//
//  ECManagedObject.m
//  edit
//
//  Created by Uri Baghin on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECManagedObject.h"
#import <ECFoundation/NSMutableArray+Shuffling.h>

static NSString *ECManagedObjectIndex = @"index";

@protocol ECOrdering <NSObject>
@property (nonatomic, retain) NSNumber *index;
@end

@interface ECManagedObjectProxy : NSMutableArray
@property (nonatomic, assign) ECManagedObject *managedObject;
@property (nonatomic, copy) NSString *key;
- (id)initWithManagedObject:(ECManagedObject *)managedObject key:(NSString *)key;
+ (id)proxyForManagedObject:(ECManagedObject *)managedObject key:(NSString *)key;
@end

@implementation ECManagedObjectProxy

@synthesize managedObject = _managedObject;
@synthesize key = _key;

- (void)dealloc
{
    self.key = nil;
    [super dealloc];
}

- (id)initWithManagedObject:(ECManagedObject *)managedObject key:(NSString *)key
{
    self = [super init];
    if (!self)
        return nil;
    self.managedObject = managedObject;
    self.key = key;
    return self;
}

+ (id)proxyForManagedObject:(ECManagedObject *)managedObject key:(NSString *)key
{
    id proxy = [self alloc];
    proxy = [proxy initWithManagedObject:managedObject key:key];
    return [proxy autorelease];
}

- (NSUInteger)count
{
    return [_managedObject countForOrderedKey:self.key];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [_managedObject objectAtIndex:index forOrderedKey:self.key];
}

- (void)addObject:(id)object
{
    [_managedObject addObject:object forOrderedKey:self.key];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
    [_managedObject insertObject:object atIndex:index forOrderedKey:self.key];
}

- (void)removeLastObject
{
    [_managedObject removeLastObjectForOrderedKey:self.key];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_managedObject removeObjectAtIndex:index forOrderedKey:self.key];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
    [_managedObject replaceObjectAtIndex:index withObject:object forOrderedKey:self.key];
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    [_managedObject exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2 forOrderedKey:self.key];
}

- (void)moveObjectAtIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2
{
    [_managedObject moveObjectAtIndex:idx1 toIndex:idx2 forOrderedKey:self.key];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [_managedObject copyForOrderedKey:self.key];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [_managedObject mutableCopyForOrderedKey:self.key];
}

- (NSArray *)subarrayWithRange:(NSRange)range
{
    return [_managedObject subarrayWithRange:range forOrderedKey:self.key];
}

@end

@interface ECManagedObject ()
- (NSFetchRequest *)fetchRequestForOrderedKey:(NSString *)key;
- (NSFetchRequest *)fetchRequestForOrderedKey:(NSString *)key withAdditionalPredicate:(NSPredicate *)predicate;
@end

@implementation ECManagedObject

static void enumerateIndicesOfObjectsWithBlock(NSArray *objects, NSNumber *(^block)(NSNumber *oldIndex))
{
    for (id<ECOrdering> object in objects)
        object.index = block(object.index);
}

static void rotateIndicesOfObjectsLeft(NSArray *objects)
{
    NSUInteger numObjects = [objects count];
    if (numObjects < 2)
        return;
    NSUInteger firstIndex = [[[objects objectAtIndex:0] index] unsignedIntegerValue];
    NSUInteger lastIndex = firstIndex + numObjects - 1;
    enumerateIndicesOfObjectsWithBlock(objects, ^NSNumber *(NSNumber *oldIndex) {
        if ([oldIndex unsignedIntegerValue] == firstIndex)
            return [NSNumber numberWithUnsignedInteger:lastIndex];
        return [NSNumber numberWithUnsignedInteger:[oldIndex unsignedIntegerValue] - 1];
    });
}

static void rotateIndicesOfObjectsRight(NSArray *objects)
{
    NSUInteger numObjects = [objects count];
    if (numObjects < 2)
        return;
    NSUInteger firstIndex = [[[objects objectAtIndex:0] index] unsignedIntegerValue];
    NSUInteger lastIndex = firstIndex + numObjects - 1;
    enumerateIndicesOfObjectsWithBlock(objects, ^NSNumber *(NSNumber *oldIndex) {
        if ([oldIndex unsignedIntegerValue] == lastIndex)
            return [NSNumber numberWithUnsignedInteger:firstIndex];
        return [NSNumber numberWithUnsignedInteger:[oldIndex unsignedIntegerValue] + 1];
    });
}
/*
static void shiftIndicesOfObjectsLeft(NSArray *objects)
{
    if ([objects count] < 2)
        return;
    enumerateIndicesOfObjectsWithBlock(objects, ^NSNumber *(NSNumber *oldIndex) {
        return [NSNumber numberWithInteger:[oldIndex integerValue] - 1];
    });
}
*/
static void shiftIndicesOfObjectsRight(NSArray *objects)
{
    if ([objects count] < 1)
        return;
    enumerateIndicesOfObjectsWithBlock(objects, ^NSNumber *(NSNumber *oldIndex) {
        return [NSNumber numberWithInteger:[oldIndex integerValue] + 1];
    });
}

- (NSFetchRequest *)fetchRequestForOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSRelationshipDescription *relationship = [[[self entity] relationshipsByName] objectForKey:key];
    [fetchRequest setEntity:[relationship destinationEntity]];
    NSString *inverseName = [[relationship inverseRelationship] name];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", inverseName, self];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:ECManagedObjectIndex ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    return [fetchRequest autorelease];
}

- (NSFetchRequest *)fetchRequestForOrderedKey:(NSString *)key withAdditionalPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key];
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[fetchRequest predicate], predicate, nil]];
    [fetchRequest setPredicate:predicate];
    return fetchRequest;
}

- (NSArray *)valueForOrderedKey:(NSString *)key
{
    return [ECManagedObjectProxy proxyForManagedObject:self key:key];
}

- (NSMutableArray *)mutableArrayValueForOrderedKey:(NSString *)key
{
    return [ECManagedObjectProxy proxyForManagedObject:self key:key];
}

- (NSArray *)copyForOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key];
    return [[[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL] retain];
}

- (NSMutableArray *)mutableCopyForOrderedKey:(NSString *)key
{
    return [[[self copyForOrderedKey:key] autorelease] mutableCopy];
}

- (NSUInteger)countForOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key];
    return [[self managedObjectContext] countForFetchRequest:fetchRequest error:NULL];
}

- (id)objectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %u", ECManagedObjectIndex, index];
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key withAdditionalPredicate:predicate];
    return [[[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL] objectAtIndex:0];
}

- (void)addObject:(id)object forOrderedKey:(NSString *)key
{
    [self addObjects:[NSSet setWithObject:object] forOrderedKey:key];
}

- (void)removeObject:(id)object forOrderedKey:(NSString *)key
{
    [self removeObjects:[NSSet setWithObject:object] forOrderedKey:key];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index forOrderedKey:(NSString *)key
{
    if ([[self valueForKey:key] containsObject:object])
        return [self moveObjectAtIndex:[((id<ECOrdering>)object).index unsignedIntegerValue] toIndex:index forOrderedKey:key];
    if (index >= [self countForOrderedKey:key])
        [self addObject:object forOrderedKey:key];
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key withAdditionalPredicate:[NSPredicate predicateWithFormat:@"%K >= %u", ECManagedObjectIndex, index]];
    NSArray *objectsToShift = [[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL];
    shiftIndicesOfObjectsRight(objectsToShift);
    ((id<ECOrdering>)object).index = [NSNumber numberWithUnsignedInteger:index];
    NSSet *addedObjects = [NSSet setWithObject:object];
    [self willChangeValueForKey:key withSetMutation:NSKeyValueUnionSetMutation usingObjects:addedObjects];
    [[self primitiveValueForKey:key] addObject:object];
    [self didChangeValueForKey:key withSetMutation:NSKeyValueUnionSetMutation usingObjects:addedObjects];
}

- (void)removeLastObjectForOrderedKey:(NSString *)key
{
    id lastObject = [self objectAtIndex:[self countForOrderedKey:key] - 1 forOrderedKey:key];
    NSSet *removedObjects = [NSSet setWithObject:lastObject];
    [self willChangeValueForKey:key withSetMutation:NSKeyValueMinusSetMutation usingObjects:removedObjects];
    [[self primitiveValueForKey:key] removeObject:lastObject];
    [self didChangeValueForKey:key withSetMutation:NSKeyValueMinusSetMutation usingObjects:removedObjects];
}

- (void)removeObjectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key
{
    [self removeObject:[self objectAtIndex:index forOrderedKey:key] forOrderedKey:key];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object forOrderedKey:(NSString *)key
{
    id oldObject = [[self objectAtIndex:index forOrderedKey:key] retain];
    NSSet *addedObjects = [NSSet setWithObject:object];
    NSSet *removedObjects = [NSSet setWithObject:oldObject];
    [self willChangeValueForKey:key withSetMutation:NSKeyValueUnionSetMutation usingObjects:addedObjects];
    [self willChangeValueForKey:key withSetMutation:NSKeyValueMinusSetMutation usingObjects:removedObjects];
    [[self primitiveValueForKey:key] addObject:object];
    [[self primitiveValueForKey:key] removeObject:oldObject];
    [self didChangeValueForKey:key withSetMutation:NSKeyValueMinusSetMutation usingObjects:removedObjects];
    [self didChangeValueForKey:key withSetMutation:NSKeyValueUnionSetMutation usingObjects:addedObjects];
    ((id<ECOrdering>)object).index = ((id<ECOrdering>)oldObject).index;
    [oldObject release];
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2 forOrderedKey:(NSString *)key
{
    id<ECOrdering> idx1Object = [self objectAtIndex:idx1 forOrderedKey:key];
    id<ECOrdering> idx2Object = [self objectAtIndex:idx2 forOrderedKey:key];
    NSNumber *oldIdx1 = [idx1Object.index copy];
    idx1Object.index = idx2Object.index;
    idx2Object.index = oldIdx1;
    [oldIdx1 release];
}

- (void)moveObjectAtIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2 forOrderedKey:(NSString *)key
{
    if (idx1 == idx2)
        return;
    NSRange range;
    if (idx1 < idx2)
    {
        range.location = idx1;
        range.length = idx2 - idx1;
        rotateIndicesOfObjectsLeft([self subarrayWithRange:range forOrderedKey:key]);
    }
    else
    {
        range.location = idx2;
        range.length = idx1 - idx2;
        rotateIndicesOfObjectsRight([self subarrayWithRange:range forOrderedKey:key]);
    }
}

- (void)addObjects:(NSSet *)objects forOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key withAdditionalPredicate:[NSPredicate predicateWithFormat:@"%K > -1", ECManagedObjectIndex]];
    NSUInteger nextIndex = [[self managedObjectContext] countForFetchRequest:fetchRequest error:NULL];
    for (id<ECOrdering> object in objects)
    {
        object.index = [NSNumber numberWithInt:nextIndex];
        ++nextIndex;
    }
    NSMutableSet *intersection = [objects mutableCopy];
    [intersection intersectSet:[self valueForKey:key]];
    if ([intersection count])
        [self removeObjects:intersection forOrderedKey:key];
    [intersection release];
    [self willChangeValueForKey:key withSetMutation:NSKeyValueUnionSetMutation usingObjects:objects];
    [[self primitiveValueForKey:key] unionSet:objects];
    [self didChangeValueForKey:key withSetMutation:NSKeyValueUnionSetMutation usingObjects:objects];
}

- (void)removeObjects:(NSSet *)objects forOrderedKey:(NSString *)key
{
    NSMutableSet *intersection = [objects mutableCopy];
    [intersection intersectSet:[self valueForKey:key]];
    if (![intersection count])
        return [intersection release];
    [intersection release];
    [self willChangeValueForKey:key withSetMutation:NSKeyValueMinusSetMutation usingObjects:objects];
    [[self primitiveValueForKey:key] minusSet:objects];
    [self didChangeValueForKey:key withSetMutation:NSKeyValueMinusSetMutation usingObjects:objects];
    NSArray *objectsToRearrange = [self copyForOrderedKey:key];
    NSUInteger index = 0;
    for (id<ECOrdering> object in objectsToRearrange)
    {
        if ([object.index unsignedIntegerValue] != index)
            object.index = [NSNumber numberWithUnsignedInteger:index];
        ++index;
    }
    [objectsToRearrange release];
}

- (NSArray *)subarrayWithRange:(NSRange)range forOrderedKey:(NSString *)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K BETWEEN {%u, %u}", ECManagedObjectIndex, range.location, range.location + range.length];
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key withAdditionalPredicate:predicate];
    return [[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL];
}

@end
