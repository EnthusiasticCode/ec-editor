//
//  Project.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location, ProjectSet, Remote;

@interface Project : NSManagedObject

@property (nonatomic, retain) NSString * labelColorString;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) BOOL newlyCreated;
@property (nonatomic, retain) NSOrderedSet *remotes;
@property (nonatomic, retain) NSSet *visitedLocations;
@property (nonatomic, retain) ProjectSet *projectSet;
@end

@interface Project (CoreDataGeneratedAccessors)

- (void)insertObject:(Remote *)value inRemotesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRemotesAtIndex:(NSUInteger)idx;
- (void)insertRemotes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRemotesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRemotesAtIndex:(NSUInteger)idx withObject:(Remote *)value;
- (void)replaceRemotesAtIndexes:(NSIndexSet *)indexes withRemotes:(NSArray *)values;
- (void)addRemotesObject:(Remote *)value;
- (void)removeRemotesObject:(Remote *)value;
- (void)addRemotes:(NSOrderedSet *)values;
- (void)removeRemotes:(NSOrderedSet *)values;
- (void)addVisitedLocationsObject:(Location *)value;
- (void)removeVisitedLocationsObject:(Location *)value;
- (void)addVisitedLocations:(NSSet *)values;
- (void)removeVisitedLocations:(NSSet *)values;

@end
