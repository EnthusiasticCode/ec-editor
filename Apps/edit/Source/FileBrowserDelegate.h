//
//  ProjectBrowserDelegate.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FileBrowser;

@protocol FileBrowserDelegate <NSObject>
- (void)fileBrowser:(id<FileBrowser>)fileBrowser didSelectFileAtPath:(NSURL *)path;
@end
