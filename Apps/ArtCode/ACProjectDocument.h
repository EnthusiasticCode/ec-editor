//
//  ACProjectDocument.h
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACState.h"

@class ACProject;

@interface ACProjectDocument : UIManagedDocument

/// The document's Project object
@property (nonatomic, strong, readonly) ACProject *project;

/// The ACURL of the document's Project object
/// Must be set before the first access to the Project object
@property (nonatomic, strong) NSURL *projectURL;

/// Returns the object referenced by the ACURL or nil if the node does not exist
- (void)objectWithURL:(NSURL *)URL completionHandler:(void (^)(id object, ACObjectType type))completionHandler;

/// Deletes the object referenced by the ACURL
- (void)deleteObjectWithURL:(NSURL *)URL completionHandler:(void (^)(BOOL success))completionHandler;

@end
