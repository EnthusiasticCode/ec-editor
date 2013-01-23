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

@end
