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
+ (ACState *)sharedState;

#pragma mark - Project Level

/// A list containing all existing projects
@property (nonatomic, strong, readonly) NSArray *projects;

/// Adds a new project with the given ACURL
/// Inserting a project with the same ACURL as an existing project is an error
/// Passing index = NSNotFound will add the project to the end of the project list
- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromZIP:(NSURL *)ZIPFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;

#pragma mark - Node Level

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

/// Returns the fileURL for the object, if applicable
@property (nonatomic, strong, readonly) NSURL *fileURL;

@end

@protocol ACStateProject <ACStateNode>

@end

@protocol ACStateBookmark <NSObject>

@end

@protocol ACStateTab <NSObject>

@end

@protocol ACStateHistoryItem <NSObject>

@end
