//
//  ACProjectFileBookmark.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectItem.h"

@class ACProjectFile;

@interface ACProjectFileBookmark : ACProjectItem

/// The file where this bookmark is defined
@property (nonatomic, weak, readonly) ACProjectFile *file;

/// An NSNumber with the line or a NSString with the symbol pointed by the bookmark.
@property (nonatomic, strong, readonly) id bookmarkPoint;

@end