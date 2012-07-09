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

@property (nonatomic, strong) NSString *content;

@property (nonatomic) NSStringEncoding *explicitEncoding;

@property (nonatomic, strong) NSString *explicitSyntaxIdentifier;

@property (nonatomic, strong) NSArray *bookmarks;

- (NSURL *)bookmarkForPoint:(id)point;

- (void)addBookmarkWithPoint:(id)point;

- (void)removeBookmark:(NSURL *)bookmark;

@end
