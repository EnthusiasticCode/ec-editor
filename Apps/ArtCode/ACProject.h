//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"

@interface ACProject : NSObject <ACStateProject>

/// The root node of the project
@property (nonatomic, strong, readonly) id<ACStateNode> rootNode;

/// Returns the node referenced by the ACURL or nil if the node does not exist
- (id<ACStateNode>)nodeForURL:(NSURL *)URL;

/// Exports the project to a .acz file
- (void)exportToACZAtURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Exports the project to a .zip file
- (void)exportToZIPAtURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Returns a project with the given URL
+ (id)projectWithURL:(NSURL *)URL;

/// Creates a new blank project with the given template, or a blank project the template is nil
+ (id)projectWithURL:(NSURL *)URL fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL))completionHandler;

/// Imports a new project from a .acz file
+ (id)projectWithURL:(NSURL *)URL fromACZAtURL:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Imports a new project from a .zip file
+ (id)projectWithURL:(NSURL *)URL fromZIPAtURL:(NSURL *)ZIPFileURL withCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
