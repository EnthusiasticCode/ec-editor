//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACNode, ACProject;

/// Global AC application state controller class
@interface ACState : NSObject

#pragma mark - Application Level

/// Returns the ACState application wide singleton
+ (ACState *)sharedState;

#pragma mark - Project Level

/// A list containing all existing projects
@property (nonatomic, strong, readonly) NSOrderedSet *projects;

- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex;

/// Adds a new project with the given ACURL
/// Inserting a project with the same ACURL as an existing project is an error
/// Passing index = NSNotFound will add the project to the end of the project list
- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromZIP:(NSURL *)ZIPFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;

#pragma mark - Node Level

/// Returns the node referenced by the ACURL or nil if the node does not exist
- (ACNode *)nodeWithURL:(NSURL *)URL;

/// Deletes the node referenced by the ACURL
- (void)deleteNodeWithURL:(NSURL *)URL;

/// Move or copy nodes to a group
- (void)moveNodeWithURL:(NSURL *)URL toGroupWithURL:(NSURL *)groupURL;
- (void)moveNodesWithURLs:(NSArray *)URLs toGroupWithURL:(NSURL *)groupURL;
- (void)copyNodeWithURL:(NSURL *)URL toGroupWithURL:(NSURL *)groupURL;
- (void)copyNodesWithURLs:(NSArray *)URLs toGroupWithURL:(NSURL *)groupURL;

@end
