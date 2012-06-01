//
//  DocSetDownloadController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetDownloadController.h"
#import "DocSetDownloadManager.h"

@interface DocSetDownloadController ()

@end

@implementation DocSetDownloadController
@synthesize infoLabel;
@synthesize infoProgress;

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self)
    return nil;
  
  // Update available docset list
  [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:DocSetDownloadManagerAvailableDocSetsChangedNotification object:nil] merge:[[NSNotificationCenter defaultCenter] rac_addObserverForName:DocSetDownloadManagerUpdatedDocSetsNotification object:nil]] subscribeNext:^(NSNotification *note) {
    if (note.name == DocSetDownloadManagerAvailableDocSetsChangedNotification) {
      self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    [self.tableView reloadData];
  }];
    
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
  [self setInfoLabel:nil];
  [self setInfoProgress:nil];
  [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [[[DocSetDownloadManager sharedDownloadManager] availableDownloads] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  NSDictionary *downloadInfo = [[[DocSetDownloadManager sharedDownloadManager] availableDownloads] objectAtIndex:indexPath.row];
  cell.textLabel.text = [downloadInfo objectForKey:@"title"];
  cell.detailTextLabel.text = nil;
  
  //NSString *name = [_downloadInfo objectForKey:@"name"];
  //BOOL downloaded = [[[DocSetDownloadManager sharedDownloadManager] downloadedDocSetNames] containsObject:name];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)refreshDocSetList:(id)sender {
  [sender setEnabled:NO];
  [[DocSetDownloadManager sharedDownloadManager] updateAvailableDocSetsFromWeb];
}

@end
