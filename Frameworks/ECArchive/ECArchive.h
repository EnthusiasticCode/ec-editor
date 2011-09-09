//
//  ECArchive.h
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECArchive : NSObject

/// Initializes the archive with a file URL referencing an existing archive file
- (id)initWithFileURL:(NSURL *)URL;

/// Extracts the archive to the specified directory
- (void)extractToDirectory:(NSURL *)URL withCompletionHandler:(void(^)(BOOL success))completionHandler;

@end
