//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACStateNode, ACStateProject, ACStateTab, ACStateBookmark, ACStateHistoryItem;

extern NSString * const ACStateNodeTypeProject;
extern NSString * const ACStateNodeTypeFolder;
extern NSString * const ACStateNodeTypeGroup;
extern NSString * const ACStateNodeTypeSourceFile;

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

/// Adds a new project described by the ACURL
/// Inserting a project with the same name as an existing project is an error
/// Passing index = NSNotFound will add the project to the end of the project list
- (BOOL)insertProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index error:(NSError **)error;

/// Returns the node referenced by the ACURL or nil if the node does not exist
- (id<ACStateNode>)nodeForURL:(NSURL *)URL;

@end

@protocol ACStateNode <NSObject>

/// AC URL of the node
@property (nonatomic, strong, readonly) NSURL *URL;

/// Node name
@property (nonatomic, copy) NSString *name;

/// Node index in the containing node or list
@property (nonatomic) NSUInteger index;

/// Tag of the node
@property (nonatomic) NSUInteger tag;

/// Type of the node
@property (nonatomic, readonly) NSString *nodeType;

/// Whether the node is expanded or not
@property (nonatomic) BOOL expanded;

/// Child nodes
@property (nonatomic, strong, readonly) NSOrderedSet *children;

/// Deletes the node
- (void)delete;

/// Returns whether the node has been deleted
- (BOOL)isDeleted;

@end

/// AC Project controller
/// This object should not be instantiated
@protocol ACStateProject <ACStateNode>

/// The directory where the project's documents are stored
- (NSURL *)documentDirectory;

/// The directory where the project's contents are stored
- (NSURL *)contentDirectory;

/// Open the project
/// Must be called before using any of the following methods
/// The children property is empty before calling this
- (void)openWithCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Close the project
/// Must be called if the project has been opened
- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Returns the node referenced by the ACURL or nil if the node does not exist
- (id<ACStateNode>)nodeForURL:(NSURL *)URL;

@end

@protocol ACStateBookmark <NSObject>

@end

@protocol ACStateTab <NSObject>

@end

@protocol ACStateHistoryItem <NSObject>

@end
