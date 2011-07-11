//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - ACState Constants
NSString * const ACProjectBundleExtension;

#pragma mark - ACState Notifications
NSString * const ACProjectWillRenameNotification;
NSString * const ACProjectDidRenameNotification;
NSString * const ACProjectPropertiesWillChangeNotification;
NSString * const ACProjectPropertiesDidChangeNotification;

/// Global AC application state controller class
@interface ACState : NSObject

#pragma mark - Application Level
/// Returns the ACState application wide singleton
+ (ACState *)sharedState;

#pragma mark - Project Level
/// Returns a list containing all existing projects
@property (nonatomic, copy, readonly) NSOrderedSet *projects;
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

@end

/// AC Project controller
/// Is returned by ACState methods, cannot be created
@interface ACStateProject : NSObject

/// Project name
/// Same as the bundle's name, setting it will rename the bundle
@property (nonatomic, copy) NSString *name;
/// Project index in the projects list
@property (nonatomic) NSUInteger index;
/// Color of the project
@property (nonatomic, strong) UIColor *color;

@end
