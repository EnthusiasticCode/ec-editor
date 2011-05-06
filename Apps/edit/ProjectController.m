//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <ECUIKit/ECItemViewElement.h>
#import "ProjectController.h"
#import "FileController.h"
#import "AppController.h"
#import "Project.h"
#import "Folder.h"
#import "Group.h"
#import "File.h"

@interface ProjectController ()
{
    BOOL _tableViewNeedsReload;
}
- (Folder *)areaAtIndexPath:(NSIndexPath *)indexPath;
- (Group *)groupAtIndexPath:(NSIndexPath *)indexPath;
- (File *)itemAtIndexPath:(NSIndexPath *)indexPath;
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
    [self saveContext];
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
    if (_tableViewNeedsReload)
        [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView deselectAllItemsAnimated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (Folder *)areaAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.project orderedProjectFolders] objectAtIndex:indexPath.area];
}

- (Group *)groupAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[self areaAtIndexPath:indexPath] orderedGroups] objectAtIndex:indexPath.group];
}

- (File *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[self groupAtIndexPath:indexPath] orderedItems] objectAtIndex:indexPath.item];
}

#pragma mark -
#pragma mark ECItemView

- (NSUInteger)numberOfAreasInItemView:(ECItemView *)itemView
{
    return [self.project countForOrderedKey:@"projectFolders"];
}

- (NSUInteger)itemView:(ECItemView *)itemView numberOfGroupsInAreaAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self areaAtIndexPath:indexPath].groups count];
}

- (NSUInteger)itemView:(ECItemView *)itemView numberOfItemsInGroupAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self groupAtIndexPath:indexPath].items count];
}

- (ECItemViewElement *)itemView:(ECItemView *)itemView viewForAreaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    ECItemViewElement *folder = [self.tableView dequeueReusableElementForType:kECItemViewAreaHeaderKey];
    if (!folder)
    {
        folder = [[[ECItemViewElement alloc] init] autorelease];
        UILabel *label = [[UILabel alloc] init];
        label.tag = 1;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.frame = folder.bounds;
        label.backgroundColor = [UIColor blueColor];
        [folder addSubview:label];
        [label release];
    }
    ((UILabel *)[folder viewWithTag:1]).text = [self areaAtIndexPath:indexPath].name;
    return folder;
}

- (ECItemViewElement *)itemView:(ECItemView *)itemView viewForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    ECItemViewElement *groupSeparator = [self.tableView dequeueReusableElementForType:kECItemViewGroupSeparatorKey];
    if (!groupSeparator)
    {
        groupSeparator = [[[ECItemViewElement alloc] init] autorelease];
        groupSeparator.backgroundColor = [UIColor blackColor];
    }
    return groupSeparator;
}

- (ECItemViewElement *)itemView:(ECItemView *)itemView viewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ECItemViewElement *file = [self.tableView dequeueReusableElementForType:kECItemViewItemKey];
    if (!file)
    {
        file = [[[ECItemViewElement alloc] init] autorelease];
        UILabel *label = [[UILabel alloc] init];
        label.tag = 1;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.frame = file.bounds;
        label.backgroundColor = [UIColor greenColor];
        [file addSubview:label];
        [label release];
    }
    ((UILabel *)[file viewWithTag:1]).text = [self itemAtIndexPath:indexPath].name;
    return file;
}

- (void)itemView:(ECItemView *)itemView moveItemsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *items = [NSMutableArray array];
    for (NSIndexPath *item in indexPaths)
        [items addObject:[[[self groupAtIndexPath:item] orderedItems] objectAtIndex:item.item]];
    [[[self groupAtIndexPath:indexPath] orderedItems] insertObjects:items atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(indexPath.item, [items count])]];
}

- (void)itemView:(ECItemView *)itemView insertGroupAtIndexPath:(NSIndexPath *)indexPath
{
    Group *group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:self.managedObjectContext];
    [[[self areaAtIndexPath:indexPath] orderedGroups] insertObject:group atIndex:indexPath.position];
}

- (void)itemView:(ECItemView *)itemView deleteGroupAtIndexPath:(NSIndexPath *)indexPath
{
    Group *group = [[[self areaAtIndexPath:indexPath] orderedGroups] objectAtIndex:indexPath.position];
    if ([[group items] count])
        return;
    [self.managedObjectContext deleteObject:group];
}

- (void)itemView:(ECItemView *)itemView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.editing)
        return;
    [self loadFile:[self itemAtIndexPath:indexPath].path];
}

#pragma mark -

- (void)edit:(id)sender
{
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)done:(id)sender
{
    [self.tableView setEditing:NO animated:YES];
    [self.tableView deselectAllItemsAnimated:YES];
    self.navigationItem.rightBarButtonItem = self.editButton;
}

- (void)loadProject:(NSString *)projectRoot
{
    NSString *storePath = [projectRoot stringByAppendingPathComponent:@".ecproj"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:projectRoot])
        [fileManager createDirectoryAtPath:projectRoot withIntermediateDirectories:YES attributes:nil error:NULL];
    [fileManager release];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSError *error;
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        //Replace this implementation with code to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    NSFetchRequest *projectFetchRequest = [[NSFetchRequest alloc] init];
    [projectFetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.managedObjectContext]];
    NSArray *projects = [self.managedObjectContext executeFetchRequest:projectFetchRequest error:NULL];
    [projectFetchRequest release];
    if ([projects count])
        self.project = [projects objectAtIndex:0];
    else
    {
        Project *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
        project.path = projectRoot;
        project.name = [projectRoot lastPathComponent];
        project.project = project;
        [project scanForNewFiles];
        self.project = project;
    }
    self.title = self.project.name;
    _tableViewNeedsReload = YES;
}

- (void)loadFile:(NSString *)file
{
    FileController *fileController = ((AppController *)self.navigationController).fileController;
    [fileController loadFile:file];
    [self.navigationController pushViewController:fileController animated:YES];
}

- (void)saveContext
{
    [self.managedObjectContext save:NULL];
}

@end
