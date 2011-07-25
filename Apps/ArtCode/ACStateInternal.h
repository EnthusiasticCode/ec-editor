//
//  ACStatePrivate.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"

@interface ACState (Internal)

/// returns a suitable ACState proxy for the object
+ (id)ACStateProxyForObject:(id)object;

/// returns a suitable ACState proxy for the ACURL
+ (id)ACStateProxyForURL:(NSURL *)URL;

/// Returns the index of a project in the projects list
- (NSUInteger)indexOfProjectWithURL:(NSURL *)URL;

/// Sets the index of a project in the projects list
/// The project is inserted at the set index, other projects are shuffled
- (void)setIndex:(NSUInteger)index forProjectWithURL:(NSURL *)URL;

@end
