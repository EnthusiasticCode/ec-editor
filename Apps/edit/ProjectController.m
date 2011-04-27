//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ProjectController.h"
#import "FileController.h"
#import "AppController.h"
#import "Project.h"
#import "Folder.h"
#import "Group.h"
#import "File.h"

@interface ProjectController ()
- (Folder *)areaAtIndex:(NSUInteger)area;
- (Group *)groupAtIndex:(NSUInteger)group inArea:(NSUInteger)area;
- (File *)itemAtIndex:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area;
@end

@implementation ProjectController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize project = _project;
@synthesize editButton = _editButton;
@synthesize doneButton = _doneButton;
@synthesize tableView = _tableView;

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
        return _managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
        return _managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Project" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return _managedObjectModel;
}

- (void)dealloc
{
    self.tableView = nil;
    self.editButton = nil;
    self.doneButton = nil;
    self.project = nil;
    self.managedObjectContext = nil;
    self.persistentStoreCoordinator = nil;
    self.managedObjectModel = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButton;
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (Folder *)areaAtIndex:(NSUInteger)area
{
    return [[self.project sortedSubfolders] objectAtIndex:area];
}

- (Group *)groupAtIndex:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[[self areaAtIndex:area] sortedGroups] objectAtIndex:group];
}

- (File *)itemAtIndex:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[[self groupAtIndex:group inArea:area] sortedItems] objectAtIndex:item];
}

- (NSUInteger)numberOfAreasInTableView:(ECItemView *)itemView
{
    return [self.project.subfolders count];
}

- (NSString *)itemView:(ECItemView *)itemView titleForHeaderInArea:(NSUInteger)area
{
    return [self areaAtIndex:area].name;
}

- (ECItemViewCell *)itemView:(ECItemView *)itemView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger counter = 0;
    ++counter;
    ECItemViewCell *file = [self.tableView dequeueReusableCell];
    if (!file)
    {
        file = [[[ECItemViewCell alloc] init] autorelease];
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.tag = 1;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.frame = UIEdgeInsetsInsetRect(file.bounds, UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0));
        label.backgroundColor = [UIColor greenColor];
        [file addSubview:label];
    }
    ((UILabel *)[file viewWithTag:1]).text = [self itemAtIndex:indexPath.item inGroup:indexPath.group inArea:indexPath.area].name;
    return file;
}

- (NSUInteger)itemView:(ECItemView *)itemView numberOfGroupsInArea:(NSUInteger)area
{
    return [[self areaAtIndex:area].groups count];
}

- (NSUInteger)itemView:(ECItemView *)itemView numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[self groupAtIndex:group inArea:area].items count];
}

- (void)itemView:(ECItemView *)itemView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if (!indexPath)
        return;
    [self loadFile:[self itemAtIndex:indexPath.item inGroup:indexPath.group inArea:indexPath.area].path];
}

- (BOOL)itemView:(ECItemView *)itemView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)itemView:(ECItemView *)itemView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
//    NSString *file = [[[[self.files allValues] objectAtIndex:sourceIndexPath.area] objectAtIndex:sourceIndexPath.item] retain];
//    [[[self.files allValues] objectAtIndex:sourceIndexPath.area] removeObjectAtIndex:sourceIndexPath.item];
//    [[[self.files allValues] objectAtIndex:destinationIndexPath.area] insertObject:file atIndex:destinationIndexPath.item];
//    [file release];
}

- (void)edit:(id)sender
{
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)done:(id)sender
{
    [self.tableView setEditing:NO animated:YES];
    self.navigationItem.rightBarButtonItem = self.editButton;
}

- (void)loadProject:(NSString *)projectRoot
{
    NSString *storePath = [projectRoot stringByAppendingPathComponent:@".ecproj"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    if (![fileManager fileExistsAtPath:projectRoot])
        [fileManager createDirectoryAtPath:projectRoot withIntermediateDirectories:YES attributes:nil error:NULL];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSError *error;
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        //Replace this implementation with code to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSFetchRequest *projectFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [projectFetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.managedObjectContext]];
    NSArray *projects = [self.managedObjectContext executeFetchRequest:projectFetchRequest error:NULL];
    if ([projects count])
        self.project = [projects objectAtIndex:0];
    else
    {
        self.project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
        self.project.path = projectRoot;
        self.project.name = [projectRoot lastPathComponent];
        [self.project scanForNewFiles];
    }
    self.title = self.project.name;
}

- (void)loadFile:(NSString *)file
{
    FileController *fileController = ((AppController *)self.navigationController).fileController;
    [fileController loadFile:file];
    [self.navigationController pushViewController:fileController animated:YES];
}

@end
