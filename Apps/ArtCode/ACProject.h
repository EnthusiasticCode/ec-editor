//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@class ACProjectItem, ACProjectFolder, ACProjectFile, ACProjectRemote;

/// Notifications for the projects list
extern NSString * const ACProjectWillAddProjectNotificationName;
extern NSString * const ACProjectDidAddProjectNotificationName;
extern NSString * const ACProjectWillRemoveProjectNotificationName;
extern NSString * const ACProjectDidRemoveProjectNotificationName;
extern NSString * const ACProjectNotificationProjectKey;

/// Other notifications
extern NSString * const ACProjectWillAddItem;
extern NSString * const ACProjectDidAddItem;
extern NSString * const ACProjectWillRemoveItem;
extern NSString * const ACProjectDidRemoveItem;
extern NSString * const ACProjectNotificationItemKey;

@interface ACProject : UIDocument

#pragma mark Projects list

/// Returns a dictionary mapping uuid to projects.
+ (NSDictionary *)projects;

/// Creates a new project by optionally decompressing the archive at the given URL, saves it and returns it.
/// The returned project is openes, it must be closed in the completion handler
+ (void)createProjectWithName:(NSString *)name labelColor:(UIColor *)labelColor completionHandler:(void(^)(ACProject *createdProject))completionHandler;

/// Returns the project with the given UUID, or nil if the project does not exist.
+ (ACProject *)projectWithUUID:(id)uuid;

/// Completely remove the project with the given uuid.
+ (void)removeProjectWithUUID:(id)uuid;

/// Set a metadata for the given project and key. The value of info must be encodable in a plist.
+ (void)setMeta:(id)info forProject:(ACProject *)project key:(NSString *)key;

/// Removes a stored metadata for the given project and key.
+ (void)removeMetaForProject:(ACProject *)project key:(NSString *)key;

/// Get a metadata for the given project and key.
+ (id)metaForProject:(ACProject *)project key:(NSString *)key;

#pragma mark Project metadata
/// Project metadata does not require projects to be accessed or set

/// Unique identifier of the project. It can be a string with an uuid or a core data identifier.
@property (nonatomic, strong, readonly) id UUID;
@property (nonatomic, strong, readonly) NSURL *artCodeURL;

/// Name of the project set at creation
@property (nonatomic, copy) NSString *name;

/// A color that represents the project.
@property (nonatomic, strong) UIColor *labelColor;

/// A flag indicating if the project has been newly created and never opened.
@property (nonatomic, readonly, getter = isNewlyCreated) BOOL newlyCreated;

#pragma mark Project content
/// Project content requires the projects to be open to be accessed or set

@property (nonatomic, strong, readonly) ACProjectFolder *contentsFolder;
@property (nonatomic, copy, readonly) NSArray *files;
@property (nonatomic, copy, readonly) NSArray *bookmarks;
@property (nonatomic, copy, readonly) NSArray *remotes;

/// Retrieve an item (file, folder, bookmark or remote) that has the given uuid.
- (ACProjectItem *)itemWithUUID:(id)uuid;

/// Adds a remote to the project with a full remote url <scheme>://user@host:port
- (ACProjectRemote *)addRemoteWithName:(NSString *)name URL:(NSURL *)remoteURL;

/// Removes a remote from the project
- (void)removeRemote:(ACProjectRemote *)remote;

#pragma mark Project-wide operations

/// Duplicate the entire project.
/// The returned project is opened, it must be closed in the completion handler if not needed anymore.
- (void)duplicateWithCompletionHandler:(void(^)(ACProject *duplicate))completionHandler;

@end

@interface ACProject (RACExtensions)

/// Returns a subscribable that sends NSNotification on ACProjectDidInsertProjectNotificationName and ACProjectDidRemoveProjectNotificationName notifications.
+ (RACSubscribable *)rac_projects;

@end
