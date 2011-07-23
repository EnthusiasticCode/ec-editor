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

/// Returns a proxy that always represents the active project
/// The proxy's properties change both when the project's properties change, and when a different project is activated
+ (ACStateProject *)currentProject;

/// Project name
/// Same as the bundle's name, setting it will rename the bundle
@property (nonatomic, copy) NSString *name;

/// Project index in the projects list
@property (nonatomic) NSUInteger index;

/// Color of the project
@property (nonatomic, strong) UIColor *color;

/// Whether or not the project is active
/// Only one project can be active at any time, activating one will deactivate the previously active project
@property (nonatomic, getter = isActive) BOOL active;

@end
