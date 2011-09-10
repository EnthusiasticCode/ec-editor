//
//  ACProjectDocument.h
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACProject;

@interface ACProjectDocument : UIManagedDocument

/// The document's Project object
@property (nonatomic, strong, readonly) ACProject *project;

@end
