//
//  Application.h
//  edit
//
//  Created by Uri Baghin on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Project, File;

const NSString *ClientCurrentProjectChangedNotification;
const NSString *ClientCurrentFileChangedNotification;
const NSString *ClientOldProjectKey;
const NSString *ClientNewProjectKey;
const NSString *ClientOldFileKey;
const NSString *ClientNewFileKey;

@interface Client : NSObject
@property (nonatomic, strong) Project *currentProject;
@property (nonatomic, strong) File *currentFile;
+ (Client *)sharedClient;
@end
