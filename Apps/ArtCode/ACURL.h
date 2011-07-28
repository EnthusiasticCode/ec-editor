//
//  ACURL.h
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ACURL)

- (NSString *)ACProjectName;

+ (NSURL *)ACURLForProjectWithName:(NSString *)name;

/// Create a NSURL with the default ArtCode scheme.
+ (NSURL *)ACURLWithPath:(NSString *)path;

@end
