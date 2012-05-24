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
extern NSString * const ACProjectWillInsertProjectNotificationName;
extern NSString * const ACProjectDidInsertProjectNotificationName;
extern NSString * const ACProjectWillRemoveProjectNotificationName;
extern NSString * const ACProjectDidRemoveProjectNotificationName;
extern NSString * const ACProjectNotificationIndexKey;

@interface ACProject : UIDocument

#pragma mark Projects list

/// Returns an array of all projects.
/// It is not safe to call [UIDocument openWithCompletionHandler:] on projects returned via this method.
/// To get an instance of ACProject that can be safelly open use [ACProject projectWithUUID:].
+ (NSArray *)projects;

/// Creates a new project by optionally decompressing the archive at the given URL, saves it and returns it.
/// The returned project is openes, it must be closed in the completion handler
+ (void)createProjectWithName:(NSString *)name labelColor:(UIColor *)labelColor completionHandler:(void(^)(ACProject *createdProject, NSError *error))completionHandler;

/// Returns the project with the given UUID, or nil if the project does not exist.
+ (ACProject *)projectWithUUID:(id)uuid;

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
@property (nonatomic, strong, readonly) NSArray *files;
@property (nonatomic, strong, readonly) NSArray *bookmarks;
@property (nonatomic, strong, readonly) NSArray *remotes;

/// Retrieve an item (file, folder, bookmark or remote) that has the given uuid.
- (ACProjectItem *)itemWithUUID:(id)uuid;

/// Adds a remote to the project with a full remote url <scheme>://user@host:port
- (ACProjectRemote *)addRemoteWithName:(NSString *)name URL:(NSURL *)remoteURL;

#pragma mark Project-wide operations

/// Duplicate the entire project.
/// The returned project is openes, it must be closed in the completion handler.
- (void)duplicateWithCompletionHandler:(void(^)(ACProject *duplicate, NSError *error))completionHandler;

/// Completelly remove the project and its files.
- (void)remove;

@end

@interface ACProject (RACExtensions)

@property (atomic, readonly) RACScheduler *codeIndexingScheduler;

/// Returns a subscribable that sends NSNotification on ACProjectDidInsertProjectNotificationName and ACProjectDidRemoveProjectNotificationName notifications.
+ (RACSubscribable *)rac_projects;

@end
