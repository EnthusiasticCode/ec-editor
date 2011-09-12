//
//  ACState.h
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACProjectDocument;

/// A singleton for managing the list of projects in AC
@interface ACProjectDocumentsList : NSObject

/// Returns the ACProjectDocumentsList singleton
+ (ACProjectDocumentsList *)sharedList;

/// A list containing all existing project documents
@property (nonatomic, strong, readonly) NSOrderedSet *projectDocuments;

/// Returns the project document with the given name
- (ACProjectDocument *)projectDocumentWithName:(NSString *)projectName;
/// Deletes the project document with the given name
- (void)deleteProjectWithName:(NSString *)projectName;
/// Renames the project document with the given name
- (void)renameProjectWithName:(NSString *)projectName toName:(NSString *)newProjectName;

/// Reorders the project list
- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex;

/// Adds a new project with the given name
/// Inserting a project with the same name as an existing project is an error
/// Passing index = NSNotFound will add the project to the end of the project list
- (void)addNewProjectWithName:(NSString *)projectName atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)addNewProjectWithName:(NSString *)projectName atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;
- (void)addNewProjectWithName:(NSString *)projectName atIndex:(NSUInteger)index fromZIP:(NSURL *)ZIPFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
