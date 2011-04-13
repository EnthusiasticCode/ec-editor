//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectController.h"
#import "FileController.h"
#import "AppController.h"
#import "Project.h"
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECFoundation/NSFileManager(ECAdditions).h>

@interface ProjectController ()
{
    @private
    UIPanGestureRecognizer *tableViewPanRecognizer_;
    
}
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *folder;
@property (nonatomic) BOOL isEditing;
- (NSArray *)contentsOfFolder;
- (NSArray *)filesInSubfolder:(NSString *)subfolder;
- (NSInteger)numberOfFolders;
- (NSInteger)numberOfGroupsInFolder:(NSInteger)folder;
- (NSInteger)numberOfFilesInGroup:(NSInteger)group inFolder:(NSInteger)folder;
- (NSString *)nameOfFile:(NSInteger)file inGroup:(NSInteger)group inFolder:(NSInteger)folder;
- (NSArray *)indexPathsForNewGroupPlaceholders;
- (void)handlePan:(UIGestureRecognizer *)panRecognizer;
- (void)handleTap:(UIGestureRecognizer *)tapRecognizer;
@end

@implementation ProjectController

@synthesize extensionsToShow = extensionsToShow_;
@synthesize project = project_;
@synthesize codeIndex = codeIndex_;
@synthesize editButton = editButton_;
@synthesize doneButton = doneButton_;
@synthesize tableView = tableView_;
@synthesize fileManager = fileManager_;
@synthesize folder = folder_;
@synthesize isEditing = isEditing_;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    self.folder = nil;
    self.fileManager = nil;
    self.tableView = nil;
    self.editButton = nil;
    self.doneButton = nil;
    self.extensionsToShow = nil;
    self.project = nil;
    self.codeIndex = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButton;
    self.tableView.allowsSelection = NO;
    self.tableView.allowsSelectionDuringEditing = NO;
    for (UIGestureRecognizer *recognizer in [self.tableView gestureRecognizers])
    {
        if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]])
            tableViewPanRecognizer_ = (UIPanGestureRecognizer *)recognizer;
    }
    UIPanGestureRecognizer *panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
    panGestureRecognizer.enabled = YES;
    panGestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:panGestureRecognizer];
    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark -
#pragma mark Private methods

- (NSArray *)contentsOfFolder
{
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    return [self.fileManager subpathsOfDirectoryAtPath:self.folder withExtensions:nil options:options skipFiles:YES skipDirectories:NO error:(NSError **)NULL];
}

- (NSArray *)filesInSubfolder:(NSString *)subfolder
{
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    return [self.fileManager contentsOfDirectoryAtPath:[self.folder stringByAppendingPathComponent:subfolder] withExtensions:self.extensionsToShow options:options skipFiles:NO skipDirectories:YES error:(NSError **)NULL];
}

- (NSInteger)numberOfFolders
{
    return [[self contentsOfFolder] count];
}

- (NSInteger)numberOfGroupsInFolder:(NSInteger)folder
{
    if (self.isEditing)
        return 3;
    return 1;
}

- (NSInteger)numberOfFilesInGroup:(NSInteger)group inFolder:(NSInteger)folder
{
    return [[self filesInSubfolder:[self tableView:nil titleForHeaderInSection:group]] count];
}

- (NSArray *)indexPathsForNewGroupPlaceholders
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i = 0; i < [self numberOfFolders]; ++i)
    {
//        NSInteger numGroups = [self numberOfGroupsInFolder:i];
//        if (numGroups)
//            for (NSInteger j = 0; j < numGroups; ++j)
//                [indexPaths addObject:[NSIndexPath indexPathForRow:j * 2 inSection:i]];
//        else
//            [indexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:i]];
        [indexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:i]];
        [indexPaths addObject:[NSIndexPath indexPathForRow:2 inSection:i]];
    }
    return indexPaths;
}

- (NSString *)nameOfFile:(NSInteger)file inGroup:(NSInteger)group inFolder:(NSInteger)folder
{
    NSString *subfolder = [self tableView:nil titleForHeaderInSection:folder];
    NSString *fileSubPath = [[self filesInSubfolder:subfolder] objectAtIndex:file];
    return [self.folder stringByAppendingPathComponent:[subfolder stringByAppendingPathComponent:fileSubPath]];
}
#pragma mark -
#pragma mark UIGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.isEditing)
        return YES;
    return NO;
}

- (void)handlePan:(UIGestureRecognizer *)panRecognizer
{
    NSLog(@"handlePan");
}

- (void)handleTap:(UIGestureRecognizer *)tapRecognizer
{
    NSLog(@"handleTap");
}

#pragma mark -
#pragma mark Public methods

- (void)edit:(id)sender
{
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:[self indexPathsForNewGroupPlaceholders] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView setEditing:YES animated:YES];
    self.isEditing = YES;
    [self.tableView endUpdates];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)done:(id)sender
{
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[self indexPathsForNewGroupPlaceholders] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView setEditing:NO animated:YES];
    self.isEditing = NO;
    [self.tableView endUpdates];
    self.navigationItem.rightBarButtonItem = self.editButton;
}

- (void)loadProject:(NSString *)projectRoot
{
    self.folder = projectRoot;
    self.project = [Project projectWithRootDirectory:projectRoot];
    self.title = self.project.name;
    self.codeIndex = [[[ECCodeIndex alloc] init] autorelease];
    self.extensionsToShow = [[self.codeIndex extensionToLanguageMap] allKeys];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self numberOfFolders];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfGroupsInFolder:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self contentsOfFolder] objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing && !(indexPath.row % 2))
        return 30.0;
    NSArray *files = [self filesInSubfolder:[self tableView:nil titleForHeaderInSection:indexPath.section]];
    return 50.0 + [files count] * 20.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *group = [tableView dequeueReusableCellWithIdentifier:@"Group"];
    ECItemView *itemView;
    if (!group)
    {
        group = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Group"] autorelease];
        itemView = [[[ECItemView alloc] init] autorelease];
        itemView.tag = 1;
        [group.contentView addSubview:itemView];
        itemView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        itemView.frame = group.contentView.bounds;
    }
    itemView = (ECItemView *)[group.contentView viewWithTag:1];
    NSArray *files = [self filesInSubfolder:[self tableView:nil titleForHeaderInSection:indexPath.section]];
    NSMutableArray *labels = [NSMutableArray arrayWithCapacity:[files count]];
    for (NSString *file in files)
    {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.text = file;
        [labels addObject:label];
    }
    itemView.items = labels;
//    label.text = [files componentsJoinedByString:@"\n"];
//    if (self.isEditing && !(indexPath.row % 2))
//        label.text = @"";
//    label.numberOfLines = [files count];
    return group;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark -
#pragma mark UITableViewDelegate

@end
