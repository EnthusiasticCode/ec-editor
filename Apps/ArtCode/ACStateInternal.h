//
//  ACStateInternal.h
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"

/// Internal methods to be called by project objects
@interface ACState (Internal)

/// Returns the index of a project in the projects list
- (NSUInteger)indexOfProjectWithURL:(NSURL *)URL;

/// Sets the index of a project in the projects list
/// The project is inserted at the set index, other projects are shuffled
- (void)setIndex:(NSUInteger)index forProjectWithURL:(NSURL *)URL;

/// Removes a project from the project list
/// This does not delete the project
- (BOOL)removeProjectWithURL:(NSURL *)URL error:(NSError **)error;

@end
