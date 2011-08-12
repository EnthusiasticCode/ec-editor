//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"

@interface ACProject : NSObject <ACStateProject>

/// Designated initializer, returns the ACProject referenced by the ACURL
- (id)initWithURL:(NSURL *)URL;

/// The directory where the project's documents are stored
- (NSURL *)documentDirectory;

/// The directory where the project's contents are stored
- (NSURL *)contentDirectory;

/// The root node of the project
@property (nonatomic, strong, readonly) id<ACStateNode> rootNode;

@end
