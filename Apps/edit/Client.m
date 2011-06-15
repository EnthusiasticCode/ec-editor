//
//  Application.m
//  edit
//
//  Created by Uri Baghin on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Client.h"
#import "Project.h"

const NSString *ClientCurrentProjectChangedNotification = @"ClientCurrentProjectChangedNotification";
const NSString *ClientCurrentFileChangedNotification = @"ClientCurrentFileChangedNotification";
const NSString *ClientOldProjectKey = @"ClientOldProjectKey";
const NSString *ClientNewProjectKey = @"ClientNewProjectKey";
const NSString *ClientOldFileKey = @"ClientOldFileKey";
const NSString *ClientNewFileKey = @"ClientNewFileKey";

@implementation Client

@synthesize currentProject = _currentProject;
@synthesize currentFile = _currentFile;

- (void)setCurrentProject:(Project *)currentProject
{
    if (currentProject == _currentProject)
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)ClientCurrentProjectChangedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_currentProject, ClientOldProjectKey, currentProject, ClientNewProjectKey, nil]];
    _currentProject = currentProject;
}

- (void)setCurrentFile:(File *)currentFile
{
    if (currentFile == _currentFile)
        return;
    [[NSNotificationCenter defaultCenter] postNotificationName:(NSString *)ClientCurrentFileChangedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_currentFile, ClientOldFileKey, currentFile, ClientNewFileKey, nil]];
    _currentFile = currentFile;
}

+ (Client *)sharedClient
{
    static Client *sharedClient = nil;
    if (!sharedClient)
        sharedClient = [[self alloc] init];
    return sharedClient;
}

@end