//
//  ACStateNodeInternal.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateNode.h"

@interface ACStateNode (Internal)

/// initializes a node proxy for the specified ACURL
- (id)initWithURL:(NSURL *)URL;

/// initializes a node proxy for the specified object
- (id)initWithObject:(id)object;

@end
