//
//  ECManagedObject.m
//  edit
//
//  Created by Uri Baghin on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECManagedObject.h"

static NSString *ECManagedObjectIndex = @"index";

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

- (void)addObject:(id)anObject
{
    [_managedObject addObject:anObject forOrderedKey:self.key];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [_managedObject insertObject:anObject atIndex:index forOrderedKey:self.key];
}

- (void)removeLastObject
{
    [_managedObject removeLastObjectForOrderedKey:self.key];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_managedObject removeObjectAtIndex:index forOrderedKey:self.key];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [_managedObject replaceObjectAtIndex:index withObject:anObject forOrderedKey:self.key];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [_managedObject copyForOrderedKey:self.key];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [_managedObject mutableCopyForOrderedKey:self.key];
}

@end

@interface ECManagedObject ()
@property (nonatomic, retain) NSMutableDictionary *fetchRequestsForOrderedKeys;
- (NSFetchRequest *)fetchRequestForOrderedKey:(NSString *)key;
@end

@implementation ECManagedObject

@synthesize fetchRequestsForOrderedKeys = _fetchrequestsForOrderedKeys;

- (NSMutableDictionary *)fetchRequestsForOrderedKeys
{
    if (!_fetchrequestsForOrderedKeys)
        _fetchrequestsForOrderedKeys = [[NSMutableDictionary alloc] init];
    return _fetchrequestsForOrderedKeys;
}

- (void)dealloc
{
    self.fetchRequestsForOrderedKeys = nil;
    [super dealloc];
}

- (NSFetchRequest *)fetchRequestForOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self.fetchRequestsForOrderedKeys objectForKey:key];
    if (fetchRequest)
        return fetchRequest;
    fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSRelationshipDescription *relationship = [[[self entity] relationshipsByName] objectForKey:key];
    [fetchRequest setEntity:[relationship destinationEntity]];
    NSString *inverseName = [[relationship inverseRelationship] name];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", inverseName, self];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:ECManagedObjectIndex ascending:YES] autorelease];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [self.fetchRequestsForOrderedKeys setObject:fetchRequest forKey:key];
    return fetchRequest;
}

- (NSArray *)valueForOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key];
    return [[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL];
}

- (NSMutableArray *)mutableArrayValueForOrderedKey:(NSString *)key
{
    return [ECManagedObjectProxy proxyForManagedObject:self key:key];
}

- (NSArray *)copyForOrderedKey:(NSString *)key
{
    return [[self valueForOrderedKey:key] copy];
}

- (NSMutableArray *)mutableCopyForOrderedKey:(NSString *)key
{
    return [[self valueForOrderedKey:key] mutableCopy];
}

- (NSUInteger)countForOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key];
    return [[self managedObjectContext] countForFetchRequest:fetchRequest error:NULL];
}

- (id)objectAtIndex:(NSUInteger)index forOrderedKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [self fetchRequestForOrderedKey:key];
    NSPredicate *predicate = [fetchRequest predicate];
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, [NSPredicate predicateWithFormat:@"%K == %u", ECManagedObjectIndex, index], nil]];
    return [[[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL] objectAtIndex:0];
}

@end
