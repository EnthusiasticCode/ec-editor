//
//  ACApplication.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACBookmark, ACTab;

typedef enum
{
    ACObjectTypeApplication,
    ACObjectTypeProject,
    ACObjectTypeFolder,
    ACObjectTypeGroup,
    ACObjectTypeFile,
} ACObjectType;

@interface ACApplication : NSManagedObject

@property (nonatomic, strong) NSOrderedSet *bookmarks;
@property (nonatomic, strong) NSOrderedSet *tabs;
@property (nonatomic, strong) NSOrderedSet *projects;

- (void)insertTabAtIndex:(NSUInteger)index;
- (void)removeTabAtIndex:(NSUInteger)index;

/// Reorder the tabs list
- (void)moveTabsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeTabsAtIndex:(NSUInteger)fromIndex withTabsAtIndex:(NSUInteger)toIndex;

/// Reorder the projcets list
- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex;

/// Methods to generate ACURLs
- (NSURL *)ACURLForProjectWithName:(NSString *)name;
- (NSURL *)ACURLForObject:(id)object;

/// Methods to manipulate objects in the application
/// All parameters are ACURLs
/// Not all objects can be deleted, moved or copied
- (id)objectWithURL:(NSURL *)URL;
- (void)deleteObjectWithURL:(NSURL *)URL;
- (void)moveObjectWithURL:(NSURL *)fromURL toURL:(NSURL *)toURL;
- (void)copyObjectWithURL:(NSURL *)fromURL toURL:(NSURL *)toURL;

/// Type information
- (ACObjectType)typeOfObject:(id)object;
- (ACObjectType)typeOfObjectWithURL:(NSURL *)URL;

@end
