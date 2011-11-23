//
//  ACApplication.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ACTab;

@interface ACApplication : NSManagedObject

@property (nonatomic, strong) NSOrderedSet *tabs;

- (ACTab *)insertTabAtIndex:(NSUInteger)index withInitialURL:(NSURL *)url;
- (void)removeTabAtIndex:(NSUInteger)index;

/// Reorder the tabs list
- (void)moveTabsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeTabAtIndex:(NSUInteger)fromIndex withTabAtIndex:(NSUInteger)toIndex;

- (NSURL *)projectsDirectory;

- (NSString *)pathRelativeToProjectsDirectory:(NSURL *)fileURL;

@end
