//
//  TextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TextFile : UIDocument

#pragma mark Content

@property (nonatomic, copy) NSString *content;

@property (nonatomic) NSStringEncoding *explicitEncoding;

@property (nonatomic, copy) NSString *explicitSyntaxIdentifier;

@property (nonatomic, copy) NSIndexSet *bookmarks;

- (BOOL)hasBookmarkAtLine:(NSUInteger)line;

- (void)addBookmarkAtLine:(NSUInteger)line;

- (void)removeBookmarkAtLine:(NSUInteger)line;

#pragma mark Helper Methods

/// Returns the bookmarks saved in the given file.
/// Use this to read the bookmarks without instantiating and opening a TextFile.
+ (NSIndexSet *)bookmarksForFileURL:(NSURL *)fileURL;

@end
