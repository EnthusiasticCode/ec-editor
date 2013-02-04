//
//  ArtCodeTabSet.h
//  ArtCode
//
//  Created by Uri Baghin on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeTabSet.h"
#import "ArtCodeLocation.h"


@interface ArtCodeTabSet : _ArtCodeTabSet

+ (ArtCodeTabSet *)defaultSet;

// Adds a new tab at the end of the set. The new tab will have a single location in its history equal to the given tab current location.
- (ArtCodeTab *)addNewTabByDuplicatingTab:(ArtCodeTab *)tab;

- (ArtCodeTab *)addNewTabWithLocationType:(ArtCodeLocationType)type remote:(ArtCodeRemote *)remote data:(NSData *)data;

#pragma mark RAC Outlets

// Sends each object after it has been added. It never completes or errors.
@property (nonatomic, readonly) RACSignal *objectsAdded;

@end
