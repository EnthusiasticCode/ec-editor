//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

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

@interface ACProject : NSObject <NSFilePresenter>

/// The local URL at which all projects are stored.
+ (NSURL *)projectsDirectory;

/// Returns a dictionary of url -> project entries
+ (NSDictionary *)projects;

/// Returns the project containing the given url
+ (ACProject *)projectContainingURL:(NSURL *)url;

+ (void)createProjectWithName:(NSString *)name completionHandler:(void(^)(ACProject *project))completionHandler;

#pragma mark Project metadata

/// Unique identifier of the project. It can be a string with an uuid or a core data identifier.
@property (nonatomic, strong, readonly) NSURL *artCodeURL;

/// Name of the project set at creation
@property (nonatomic, readonly) NSString *name;

/// A color that represents the project.
@property (nonatomic, strong) UIColor *labelColor;

/// A flag indicating if the project has been newly created and never opened.
@property (nonatomic, getter = isNewlyCreated) BOOL newlyCreated;

#pragma mark Project content

@property (nonatomic, copy, readonly) NSArray *bookmarks;
@property (nonatomic, copy, readonly) NSArray *remotes;

#pragma mark Project-wide operations

/// Duplicate the entire project.
/// The returned project is opened, it must be closed in the completion handler if not needed anymore.
- (void)duplicateWithCompletionHandler:(void(^)(ACProject *duplicate))completionHandler;

- (void)publishContentsToURL:(NSURL *)url completionHandler:(void(^)(NSError *error))completionHandler;

@end

@interface ACProject (RACExtensions)

/// Returns a subscribable that sends NSNotification on ACProjectDidInsertProjectNotificationName and ACProjectDidRemoveProjectNotificationName notifications.
+ (RACSubscribable *)rac_projects;

@end
