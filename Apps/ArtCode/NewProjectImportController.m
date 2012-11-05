//
//  NewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewProjectImportController.h"

#import "ArtCodeProject.h"
#import "ArtCodeProjectSet.h"

#import "NSURL+Utilities.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import "FileSystemItem.h"
#import "BezelAlert.h"
#import "ArchiveUtilities.h"
#import "UIColor+AppStyle.h"


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
    [[[NSFileManager alloc] init] removeItemAtURL:[self.documentsArchiveURLs objectAtIndex:indexPath.row] error:NULL];
    _documentsArchiveURLs = nil;
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self createProjectFromZipAtURL:[self.documentsArchiveURLs objectAtIndex:indexPath.row] completionHandler:^(ArtCodeProject *project) {
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Project imported") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
  }];
}

#pragma mark - Import method

- (void)createProjectFromZipAtURL:(NSURL *)zipURL completionHandler:(void (^)(ArtCodeProject *))block {
  // Generate a unique name for the project
  NSString *zipFileName = [[zipURL lastPathComponent] stringByDeletingPathExtension];
  NSString *projectName = zipFileName;
  NSUInteger attempt = 0;
  BOOL attemptAgain = NO;
  do {
    attemptAgain = NO;
    for (ArtCodeProject *p in [ArtCodeProjectSet defaultSet].projects) {
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
  [[ArtCodeProjectSet defaultSet] addNewProjectWithName:projectName labelColor:[UIColor styleForegroundColor] completionHandler:^(ArtCodeProject *createdProject) {
    if (createdProject) {
      // Import the zip file
      // Extract files if needed
      [ArchiveUtilities extractArchiveAtURL:zipURL completionHandler:^(NSURL *temporaryDirectoryURL) {
        // Get the extracted directories
        [[[[[RACSubscribable combineLatest:@[[[[[FileSystemDirectory directoryWithURL:temporaryDirectoryURL] select:^id<RACSubscribable>(FileSystemDirectory *temporaryDirectory) {
          return [temporaryDirectory children];
        }] switch] select:^id<RACSubscribable>(NSArray *children) {
          // If there is only 1 extracted directory, return it's children, otherwise return all extracted items
          FileSystemItem *onlyChild = [children lastObject];
          if (children.count == 1 && onlyChild.type.first == NSURLFileResourceTypeDirectory) {
            return [[children lastObject] children];
          } else {
            return [RACSubscribable return:children];
          }
        }], [FileSystemDirectory directoryWithURL:createdProject.fileURL]] reduce:^id(RACTuple *xs) {
          NSArray *children = xs.first;
          FileSystemDirectory *projectDirectory = xs.second;
          return [[children rac_toSubscribable] select:^id<RACSubscribable>(FileSystemItem *child) {
            return [child moveTo:projectDirectory];
          }];
        }] switch] merge] finally:^{
          [self stopRightBarButtonItemActivityIndicator];
          self.tableView.userInteractionEnabled = YES;
          [[NSFileManager defaultManager] removeItemAtURL:temporaryDirectoryURL error:NULL];
        }] subscribeError:^(NSError *error) {
          // TODO: error handling
          ASSERT(NO);
          if (block) {
            block(nil);
          }
        } completed:^{
          if (block) {
            block(createdProject);
          }
        }];
      }];
    } else {
      ASSERT(NO); // TODO: error handling
    }
  }];
}

@end
