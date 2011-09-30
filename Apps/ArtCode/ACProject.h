//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACGroup.h"

@class ACProjectDocument;

@interface ACProject : ACGroup

@property (nonatomic, retain) NSOrderedSet *bookmarks;

@property (nonatomic, weak) ACProjectDocument *document;

@end

