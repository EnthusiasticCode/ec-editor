//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACNode, ACProject;

typedef enum
{
    ACObjectTypeUnknown,
    ACObjectTypeProject,
    ACObjectTypeGroup,
    ACObjectTypeFile,
} ACObjectType;

/// Global AC application state controller class
@interface ACState : NSObject

#pragma mark - Application Level

/// Returns the ACState application wide singleton
+ (ACState *)sharedState;

#pragma mark - Project Level

/// URLs of existing projects
@property (nonatomic, strong, readonly) NSOrderedSet *projectURLs;

/// Loads the project containing the given URL
- (void)loadProjectDocumentIfNeededForURL:(NSURL *)URL completionHandler:(void(^)(BOOL success))completionHandler;

/// Reorder the projects list
- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex;

/// Adds a new project with the given ACURL
/// Inserting a project with the same ACURL as an existing project is an error
/// Passing index = NSNotFound will add the project to the end of the project list
- (void)addNewProjectWithURL:(NSURL *)projectURL atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName;
- (void)addNewProjectWithURL:(NSURL *)projectURL atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL;
- (void)addNewProjectWithURL:(NSURL *)projectURL atIndex:(NSUInteger)index fromZIP:(NSURL *)ZIPFileURL;

#pragma mark - Object Level

/// Returns the object referenced by the ACURL or nil if the node does not exist
- (id)objectWithURL:(NSURL *)URL;

/// Deletes the object referenced by the ACURL
- (void)deleteObjectWithURL:(NSURL *)URL;

/// Moves / copies objects
- (void)moveObjectAtURL:(NSURL *)fromURL toURL:(NSURL *)toURL;
- (void)moveObjectsAtURLs:(NSArray *)fromURLs toURLs:(NSArray *)toURLs;
- (void)copyObjectAtURL:(NSURL *)fromURL toURL:(NSURL *)toURL;
- (void)copyObjectsAtURLs:(NSArray *)fromURLs toURLs:(NSArray *)toURLs;

@end
