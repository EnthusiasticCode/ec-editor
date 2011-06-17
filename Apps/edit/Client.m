//
//  Application.m
//  edit
//
//  Created by Uri Baghin on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Client.h"
#import "Project.h"

NSString *const ClientCurrentProjectChangedNotification = @"ClientCurrentProjectChangedNotification";
NSString *const ClientCurrentFileChangedNotification = @"ClientCurrentFileChangedNotification";
NSString *const ClientOldProjectKey = @"ClientOldProjectKey";
NSString *const ClientNewProjectKey = @"ClientNewProjectKey";
NSString *const ClientOldFileKey = @"ClientOldFileKey";
NSString *const ClientNewFileKey = @"ClientNewFileKey";

@implementation Client

@synthesize currentProject = _currentProject;
@synthesize currentFile = _currentFile;

- (void)setCurrentProject:(Project *)currentProject
{
    if (currentProject == _currentProject)
        return;
    Project *oldProject = _currentProject;
    _currentProject = currentProject;
    [[NSNotificationCenter defaultCenter] postNotificationName:ClientCurrentProjectChangedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldProject, ClientOldProjectKey, currentProject, ClientNewProjectKey, nil]];
}

- (void)setCurrentFile:(File *)currentFile
{
    if (currentFile == _currentFile)
        return;
    File *oldFile = _currentFile;
    _currentFile = currentFile;
    [[NSNotificationCenter defaultCenter] postNotificationName:ClientCurrentFileChangedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldFile, ClientOldFileKey, currentFile, ClientNewFileKey, nil]];
}

+ (Client *)sharedClient
{
    static Client *sharedClient = nil;
    if (!sharedClient)
        sharedClient = [[self alloc] init];
    return sharedClient;
}

@end
