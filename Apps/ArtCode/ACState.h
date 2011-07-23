//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACStateProject;

/// Global AC application state controller class
@interface ACState : NSObject

#pragma mark - Application Level

/// Returns the ACState application wide singleton
+ (ACState *)sharedState;

/// Loads or creates a saved state
/// Needs to be called to populate the projects list
- (void)loadState;

/// Saves the current state
- (void)saveState;

#pragma mark - Project Level

/// A list containing all existing projects
@property (nonatomic, strong, readonly) NSOrderedSet *allProjects;

/// The currently active project
@property (nonatomic, strong, readonly) ACStateProject *activeProject;

/// Adds a new project
/// Inserting a project with the same name as an existing project is an error
- (void)insertProjectWithName:(NSString *)name color:(UIColor *)color atIndex:(NSUInteger)index;

/// Deletes a project
/// If the project is active it deactives it before deleting it.
- (void)deleteProjectWithName:(NSString *)name;

@end
