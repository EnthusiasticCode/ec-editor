//
//  ArtCodeProjectSet.h
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProjectSet.h"
@class ArtCodeProject;


@interface ArtCodeProjectSet : ProjectSet

+ (ArtCodeProjectSet *)defaultSet;

/// Returns the project containing the given url
- (ArtCodeProject *)projectWithName:(NSString *)name;

- (void)createProjectWithName:(NSString *)name completionHandler:(void(^)(ArtCodeProject *project))completionHandler;


@end
