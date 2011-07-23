//
//  ACModelFile.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ACModelNode.h"

@class ACModelBookmark;

@interface ACModelFile : ACModelNode

@property (nonatomic, retain) NSSet *bookmarks;
@end

@interface ACModelFile (CoreDataGeneratedAccessors)

- (void)addBookmarksObject:(ACModelBookmark *)value;
- (void)removeBookmarksObject:(ACModelBookmark *)value;
- (void)addBookmarks:(NSSet *)values;
- (void)removeBookmarks:(NSSet *)values;

@end
