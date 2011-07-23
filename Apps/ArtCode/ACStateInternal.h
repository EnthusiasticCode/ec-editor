//
//  ACStatePrivate.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"
#import "ACStateProject.h"

static NSString * const ACProjectBundleExtension = @"acproj";

static NSString * const ACProjectWillRenameNotification = @"ACProjectWillRenameNotification";
static NSString * const ACProjectDidRenameNotification = @"ACProjectDidRenameNotification";
static NSString * const ACProjectPropertiesWillChangeNotification = @"ACProjectPropertiesWillChangeNotification";
static NSString * const ACProjectPropertiesDidChangeNotification = @"ACProjectPropertiesDidChangeNotification";

// Internal use only, used by the ACState controller to broadcast commands to all proxies
static NSString * const ACProjectProxyRenameCommand = @"ACProjectProxyRenameCommand";
static NSString * const ACProjectProxyDeleteCommand = @"ACProjectProxyDeleteCommand";

@interface ACState (Internal)

/// The currently active project
@property (nonatomic, strong) ACStateProject *activeProject;

/// Renames a project
- (void)setName:(NSString *)newName forProjectWithName:(NSString *)oldName;

/// Returns the index of a project in the projects list
- (NSUInteger)indexOfProjectWithName:(NSString *)name;

/// Sets the index of a project in the projects list
/// The project is inserted at the set index, other projects are shuffled
- (void)setIndex:(NSUInteger)index forProjectWithName:(NSString *)name;

/// Returns the color of a project
- (UIColor *)colorForProjectWithName:(NSString *)name;

/// Sets the color of a project
- (void)setColor:(UIColor *)color forProjectWithName:(NSString *)name;

/// Activate a project
/// If nil, deactivates all projects
- (void)activateProject:(NSString *)projectName;

/// Delete a project
- (void)deleteProjectAtIndex:(NSUInteger)index;

/// Opens a project
- (void)openProjectWithName:(NSString *)name withCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Closes a project
- (void)closeProjectWithName:(NSString *)name withCompletionHandler:(void (^)(BOOL success))completionHandler;

@end

@interface ACStateProject (Internal)

+ (ACStateProject *)projectProxyForProjectWithName:(NSString *)name;

@end