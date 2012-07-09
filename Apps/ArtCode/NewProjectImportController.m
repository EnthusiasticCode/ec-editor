//
//  NewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewProjectImportController.h"

#import "ACProject.h"

#import "NSURL+Utilities.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import "DirectoryPresenter.h"
#import "BezelAlert.h"
#import "ArchiveUtilities.h"


@interface NewProjectImportController ()

@property (nonatomic, strong, readonly) NSArray *documentsArchiveURLs;

@end


@implementation NewProjectImportController

@synthesize documentsArchiveURLs = _documentsArchiveURLs;

- (NSArray *)documentsArchiveURLs {
  if (_documentsArchiveURLs == nil) {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSURL *url in [[NSFileManager defaultManager] enumeratorAtURL:[NSURL applicationDocumentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil]) {
      if ([url isArchiveURL]) {
        [result addObject:url];
      }
    }
    _documentsArchiveURLs = result;
  }
  return _documentsArchiveURLs;
}

#pragma mark - View Lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  self.tableView.userInteractionEnabled = YES;
  [self stopRightBarButtonItemActivityIndicator];
  
  if (self.documentsArchiveURLs.count != 0) {
    [(UILabel *)self.tableView.tableFooterView setText:L(@"Swipe on an item to delete it.")];
  } else {
    [(UILabel *)self.tableView.tableFooterView setText:L(@"Add files from iTunes to populate this list.")];
  }
  
  [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
  _documentsArchiveURLs = nil;
  [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.documentsArchiveURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  cell.textLabel.text = [[self.documentsArchiveURLs objectAtIndex:indexPath.row] lastPathComponent];
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [[NSFileManager new] removeItemAtURL:[self.documentsArchiveURLs objectAtIndex:indexPath.row] error:NULL];
    _documentsArchiveURLs = nil;
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Table view delegate

- (void)_createProjectFromZipAtURL:(NSURL *)zipURL {
  // Generate a unique name for the project
  NSString *zipFileName = [[zipURL lastPathComponent] stringByDeletingPathExtension];
  NSString *projectName = zipFileName;
  NSUInteger attempt = 0;
  BOOL attemptAgain = NO;
  do {
    attemptAgain = NO;
    for (ACProject *p in ACProject.projects.allValues) {
      if ([p.name isEqualToString:projectName]) {
        projectName = [zipFileName stringByAppendingFormat:@" (%d)", ++attempt];
        attemptAgain = YES;
        break;
      }
    }
  } while (attemptAgain);
  
  // Import the project
  [self startRightBarButtonItemActivityIndicator];
  self.tableView.userInteractionEnabled = NO;
  [ACProject createProjectWithName:projectName completionHandler:^(ACProject *createdProject) {
    if (createdProject) {
      // Import the zip file
      // Extract files if needed
      [ArchiveUtilities coordinatedExtractionOfArchiveAtURL:zipURL toURL:createdProject.presentedItemURL completionHandler:^(NSError *error) {
        [self stopRightBarButtonItemActivityIndicator];
        self.tableView.userInteractionEnabled = YES;
        
        [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Project imported") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
        // TODO error handling
      }];
    } else {
      ASSERT(NO); // TODO error handling
    }
  }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self _createProjectFromZipAtURL:[self.documentsArchiveURLs objectAtIndex:indexPath.row]];
}

@end
