//
//  ArtCodeTabSet.h
//  ArtCode
//
//  Created by Uri Baghin on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeTabSet.h"

@class ArtCodeTab;


@interface ArtCodeTabSet : _ArtCodeTabSet

+ (ArtCodeTabSet *)defaultSet;

// TODO this methods should not automatically modify the allTabs array
/// Generate a new tab without any URL in it's history
- (ArtCodeTab *)addNewBlankTab;
- (ArtCodeTab *)addNewTabByDuplicatingTab:(ArtCodeTab *)tab;

@end
