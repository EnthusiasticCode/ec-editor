//
//  FileBrowser.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileBrowserDelegate.h"

@protocol FileBrowser <NSObject>
@property (nonatomic, assign) IBOutlet id<FileBrowserDelegate> delegate;
@property (nonatomic, retain, readonly) NSFileManager *fileManager;
@property (nonatomic, retain, readonly) NSURL *folder;
- (void)browseFolder:(NSURL *)folder;
- (NSArray *)contentsOfFolder;
@end
