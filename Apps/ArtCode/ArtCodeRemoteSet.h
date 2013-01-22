//
//  ArtCodeRemoteSet.h
//  ArtCode
//
//  Created by Uri Baghin on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeRemoteSet.h"

@class ArtCodeRemote;

@interface ArtCodeRemoteSet : _ArtCodeRemoteSet

+ (ArtCodeRemoteSet *)defaultSet;

- (ArtCodeRemote *)newRemote;

#pragma mark RAC Outlets

// Sends each object after it has been added. It never completes or errors.
@property (nonatomic, readonly) RACSignal *objectsAdded;

@end
