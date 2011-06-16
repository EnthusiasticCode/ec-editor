//
//  Application.h
//  edit
//
//  Created by Uri Baghin on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Project, File;

NSString *const ClientCurrentProjectChangedNotification;
NSString *const ClientCurrentFileChangedNotification;
NSString *const ClientOldProjectKey;
NSString *const ClientNewProjectKey;
NSString *const ClientOldFileKey;
NSString *const ClientNewFileKey;

@interface Client : NSObject
@property (nonatomic, strong) Project *currentProject;
@property (nonatomic, strong) File *currentFile;
+ (Client *)sharedClient;
@end
