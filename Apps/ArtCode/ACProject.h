//
//  ACProject.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString * const ACProjectContentDirectory;

typedef enum
{
    ACProjectNodeTypeFolder,
    ACProjectNodeTypeGroup,
    ACProjectNodeTypeFile,
} ACProjectNodeType;

@interface ACProject : UIManagedDocument

/// The directory where the project's documents are stored
- (NSURL *)documentDirectory;

/// The directory where the project's contents are stored
- (NSURL *)contentDirectory;

- (NSOrderedSet *)children;

@end
