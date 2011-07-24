//
//  ACStateProject.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// AC Project controller
/// This object should not be instantiated
@interface ACStateProject : NSObject

/// Project name
/// Same as the bundle's name, setting it will rename the bundle
@property (nonatomic, copy) NSString *name;

/// Project index in the projects list
@property (nonatomic) NSUInteger index;

/// Color of the project
@property (nonatomic, strong) UIColor *color;

/// AC URL of the project
@property (nonatomic, strong) NSURL *URL;

/// Open the project
/// Must be called before using any of the following methods
- (void)openWithCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Close the project
/// Must be called if the project has been opened
- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
