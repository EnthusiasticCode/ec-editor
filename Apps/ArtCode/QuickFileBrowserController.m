//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "NSTimer+BlockTimer.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"

#import "ACProject.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"

#import "SmartFilteredDirectoryPresenter.h"

static void *_directoryObservingContext;

@interface QuickFileBrowserController ()

@property (nonatomic, strong) SmartFilteredDirectoryPresenter *directoryPresenter;

- (void)_showBrowserInTabAction:(id)sender;
- (void)_showProjectsInTabAction:(id)sender;

@end


@implementation QuickFileBrowserController {
    NSString *_projectURLAbsoluteString;
}

#pragma mark - Properties

@synthesize directoryPresenter = _directoryPresenter;

- (DirectoryPresenter *)directoryPresenter
{
    if (!_directoryPresenter)
    {
        NSURL *projectURL = self.artCodeTab.currentProject.fileURL;
        _directoryPresenter = [[SmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:projectURL options:NSDirectoryEnumerationSkipsHiddenFiles];
        [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_directoryObservingContext];
        _projectURLAbsoluteString = [projectURL absoluteString];
    }
    return _directoryPresenter;
}

- (void)setDirectoryPresenter:(SmartFilteredDirectoryPresenter *)directoryPresenter
{
    if (directoryPresenter == _directoryPresenter)
        return;
    [_directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&_directoryObservingContext];
    _directoryPresenter = directoryPresenter;
    [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_directoryObservingContext];
}

- (NSArray *)filteredItems
{
    return self.directoryPresenter.fileURLs;
}

- (void)invalidateFilteredItems
{
    self.directoryPresenter.filterString = self.searchBar.text;
    if ([self.searchBar.text length] == 0)
        self.infoLabel.text = @"Type a file name to open.";
    else if ([self.filteredItems count] == 0)
        self.infoLabel.text = @"Nothing found";
    else
        self.infoLabel.text = @"";
}

#pragma mark - Controller lifecycle

- (id)init
{
    self = [super initWithTitle:@"Open quickly" searchBarStaticOnTop:YES];
    if (!self)
        return nil;
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:nil tag:0];
    self.navigationItem.title = @"Open quickly";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStyleDone target:self action:@selector(_showBrowserInTabAction:)];
    UIBarButtonItem *backToProjectsItem = [[UIBarButtonItem alloc] initWithTitle:@"Projects" style:UIBarButtonItemStylePlain target:self action:@selector(_showProjectsInTabAction:)];
    [backToProjectsItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    self.navigationItem.leftBarButtonItem = backToProjectsItem;
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (void)dealloc
{
    self.directoryPresenter = nil; // this is so we stop observing
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.directoryPresenter = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_directoryObservingContext)
    {
        // Do not try to be smart here and update the display of the table view, UITableView is too slow when updates affect a large number of rows
        [self.tableView reloadData];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.searchBar.placeholder = @"Search for file";
    self.infoLabel.text = @"Type a file name to open.";
}

- (void)viewDidUnload
{
    self.directoryPresenter = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
    
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:indexPath.row];
    BOOL isDirecotry = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirecotry];
    if (isDirecotry)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileURL pathExtension]];
    
    cell.textLabel.text = [fileURL lastPathComponent];
    cell.textLabelHighlightedCharacters = [self.directoryPresenter hitMaskForFileURL:fileURL];
    cell.detailTextLabel.text = [fileURL prettyPathRelativeToProjectDirectory];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
    [self.artCodeTab pushURL:[self.directoryPresenter.fileURLs objectAtIndex:indexPath.row]];
}

#pragma mark - Private methods

- (void)_showBrowserInTabAction:(id)sender
{
    [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
    [self.artCodeTab pushURL:[self.artCodeTab.currentProject fileURL]];
}

- (void)_showProjectsInTabAction:(id)sender
{
    [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
    [self.artCodeTab pushURL:[ArtCodeURL projectsDirectory]];
}

@end
