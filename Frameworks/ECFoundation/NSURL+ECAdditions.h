//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@interface NSURL (ECAdditions)

/// Returns the application's documents directory
+ (NSURL *)applicationDocumentsDirectory;

/// Returns the application's library directory
+ (NSURL *)applicationLibraryDirectory;

/// Return a temporary directory
+ (NSURL *)temporaryDirectory;

@end
