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

/// Adds a new tab at the end of the set. The new tab will have a single location in its history equal to the given tab current location.
- (ArtCodeTab *)addNewTabByDuplicatingTab:(ArtCodeTab *)tab;

@end
