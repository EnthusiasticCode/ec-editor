//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileMapController.h"
#import "FileViewController.h"
#import "ProjectController.h"
#import "Project.h"
#import <ECUIKit/ECEditCodeView.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeDiagnostic.h>
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeCursor.h>

@implementation ProjectController

@synthesize delegate = delegate_;
@synthesize folder = folder_;
@synthesize fileMapController = fileMapController_;
@synthesize fileViewController = fileViewController_;
@synthesize project = project_;
@synthesize codeIndex = codeIndex_;

- (NSFileManager *)fileManager
{
    return self.fileMapController.fileManager;
}

- (void)dealloc
{
    self.project = nil;
    self.codeIndex = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)loadProject:(NSURL *)projectRoot
{
    self.project = [Project projectWithRootDirectory:projectRoot];
    self.codeIndex = [[[ECCodeIndex alloc] init] autorelease];
}

- (void)loadFile:(NSURL *)fileURL
{
    ECCodeUnit *codeUnit = [self.codeIndex unitForURL:fileURL];
    [self.fileViewController loadFile:fileURL withCodeUnit:codeUnit];
    [self.fileMapController.view removeFromSuperview];
    [self.view addSubview:self.fileViewController.view];
    self.fileViewController.view.frame = self.view.bounds;
}

- (void)browseFolder:(NSURL *)folder
{
    if (![self.project.rootDirectory isEqual:folder])
        [self loadProject:folder];
    [self.fileMapController browseFolder:folder];
    [self.fileViewController.view removeFromSuperview];
    [self.view addSubview:self.fileMapController.view];
    self.fileMapController.view.frame = self.view.bounds;
}

- (NSArray *)contentsOfFolder
{
    return [self.fileMapController contentsOfFolder];
}

- (void)fileBrowser:(id<FileBrowser>)fileBrowser didSelectFileAtPath:(NSURL *)path
{
    [self loadFile:path];
    [self.delegate fileBrowser:self didSelectFileAtPath:path];
}

@end
