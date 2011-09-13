//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 9/6/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACGroup.h"

@class ACBookmark, ACTab, ACNode;

@interface ACProject : ACGroup

@property (nonatomic, strong) NSSet *bookmarks;
@property (nonatomic, strong) NSSet *tabs;

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *fileURL;

@end

@interface ACProject (CoreDataGeneratedAccessors)

- (void)addBookmarksObject:(ACBookmark *)value;
- (void)removeBookmarksObject:(ACBookmark *)value;
- (void)addBookmarks:(NSSet *)values;
- (void)removeBookmarks:(NSSet *)values;

- (void)addTabsObject:(ACTab *)value;
- (void)removeTabsObject:(ACTab *)value;
- (void)addTabs:(NSSet *)values;
- (void)removeTabs:(NSSet *)values;

@end
