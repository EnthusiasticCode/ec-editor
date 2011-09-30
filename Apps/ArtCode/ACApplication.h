//
//  ACApplication.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACURL.h"

@interface ACApplication : NSManagedObject

@property (nonatomic, strong) NSOrderedSet *tabs;
@property (nonatomic, strong) NSOrderedSet *projects;

- (void)insertTabAtIndex:(NSUInteger)index;
- (void)removeTabAtIndex:(NSUInteger)index;

/// Reorder the tabs list
- (void)moveTabsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeTabAtIndex:(NSUInteger)fromIndex withTabAtIndex:(NSUInteger)toIndex;

/// Reorder the projcets list
- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex;

/// Methods to generate ACURLs
- (NSURL *)ACURLForProjectWithName:(NSString *)name;
- (NSURL *)ACURLForObject:(id)object;

/// Methods to manipulate objects in the application
/// All parameters are ACURLs
/// Not all objects can be inserted, deleted, moved or copied
/// All methods are asynchronous and will load / unload project documents as needed
- (void)objectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(id object))completionHandler;
- (void)addObjectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(id object))completionHandler;
- (void)deleteObjectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)moveObjectWithURL:(NSURL *)fromURL toURL:(NSURL *)toURL withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)copyObjectWithURL:(NSURL *)fromURL toURL:(NSURL *)toURL withCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
