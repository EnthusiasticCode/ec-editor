//
//  ACProjectFile_Internal.h
//  ArtCode
//
//  Created by Uri Baghin on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProjectFile.h"
@class ACProjectFileBookmark;

@interface ACProjectFile (Internal)

- (void)didRemoveBookmark:(ACProjectFileBookmark *)bookmark;

@end
