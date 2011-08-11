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
+ (ACState *)localState;

/// Scans the state projects directory for new projects
- (void)scanForProjects;

#pragma mark - Project Level

/// A list containing all existing projects
@property (nonatomic, strong, readonly) NSArray *projects;

/// Adds a new project
/// Inserting a project with the same name as an existing project is an error
/// Passing index = NSNotFound will add the project to the end of the project list
- (BOOL)insertProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index error:(NSError **)error;

@end
