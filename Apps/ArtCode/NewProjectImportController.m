//
//  NewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewProjectImportController.h"


#import "NSURL+Utilities.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import <ReactiveCocoaIO/ReactiveCocoaIO.h>
#import "BezelAlert.h"
#import "ArchiveUtilities.h"
#import "UIColor+AppStyle.h"
#import "UIImage+AppStyle.h"
#import "NSURL+ArtCode.h"


@interface NewProjectImportController ()

@property (nonatomic, strong, readonly) NSArray *documentsArchiveURLs;

@end


@implementation NewProjectImportController

@synthesize documentsArchiveURLs = _documentsArchiveURLs;

- (NSArray *)documentsArchiveURLs {
  if (_documentsArchiveURLs == nil) {
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *url in [NSFileManager.defaultManager enumeratorAtURL:[NSURL applicationDocumentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil]) {
      if ([url isArchiveURL]) {
        [result addObject:url];
      }
    }
    _documentsArchiveURLs = result;
  }
  return _documentsArchiveURLs;
}

#pragma mark - View Lifecycle

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

  cell.textLabel.text = [(self.documentsArchiveURLs)[indexPath.row] lastPathComponent];
  cell.imageView.image = [UIImage styleProjectImageWithSize:CGSizeMake(32, 32) labelColor:nil];
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [NSFileManager.defaultManager removeItemAtURL:(self.documentsArchiveURLs)[indexPath.row] error:NULL];
    _documentsArchiveURLs = nil;
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self createProjectFromZipAtURL:(self.documentsArchiveURLs)[indexPath.row] completionHandler:^(RCIODirectory *projectDirectory) {
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [BezelAlert.defaultBezelAlert addAlertMessageWithText:L(@"Project imported") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
  }];
}

#pragma mark - Import method

- (void)createProjectFromZipAtURL:(NSURL *)zipURL completionHandler:(void (^)(RCIODirectory *))block {
  [self startRightBarButtonItemActivityIndicator];
  self.tableView.userInteractionEnabled = NO;
	[ArchiveUtilities extractArchiveAtURL:zipURL completionHandler:^(NSURL *temporaryDirectoryURL) {
		if (temporaryDirectoryURL == nil) {
#warning TODO: error handling file failed to extract
			return;
		}
		
		// Get the extracted directories
		RACSignal *extractedDirectories = [[[RCIODirectory itemWithURL:temporaryDirectoryURL] flattenMap:^RACSignal *(RCIODirectory *temporaryDirectory) {
			return [[temporaryDirectory childrenSignal] take:1];
		}] flattenMap:^RACSignal *(NSArray *children) {
			// If there is only 1 extracted directory, return it's children, otherwise return all extracted items
			if (children.count != 1) {
				return [RACSignal return:children];
			}
			RCIOItem *onlyChild = [children lastObject];
			if ([onlyChild isKindOfClass:RCIODirectory.class]) {
				return [[(RCIODirectory *)onlyChild childrenSignal] take:1];
			} else {
				return [RACSignal return:children];
			}
		}];
		
		// Generate a unique name for the project
		NSString *zipFileName = zipURL.lastPathComponent.stringByDeletingPathExtension;
		__block NSUInteger attempt = 0;
		NSUInteger maxAttempts = 20;
		__block RACSignal *(^newProjectDirectorySignalBlock)() = nil;
		@weakify(newProjectDirectorySignalBlock);
		newProjectDirectorySignalBlock = ^{
			@strongify(newProjectDirectorySignalBlock);
			if (attempt > maxAttempts) return [RACSignal error:[NSError errorWithDomain:@"ArtCodeErrorDomain" code:-1 userInfo:nil]];
			NSString *projectName = zipFileName;
			if (attempt > 0) {
				projectName = [zipFileName stringByAppendingFormat:@" (%d)", ++attempt];
			}
			return [[RCIODirectory itemWithURL:[NSURL.projectsListDirectory URLByAppendingPathComponent:projectName] mode:RCIOItemModeExclusiveAccess] catch:newProjectDirectorySignalBlock];
		};

		[[[[RACSignal combineLatest:@[ extractedDirectories, newProjectDirectorySignalBlock() ]] flattenMap:^id(RACTuple *x) {
			NSArray *children = x.first;
			RCIODirectory *projectDirectory = x.second;
			NSMutableArray *moveSignals = [NSMutableArray arrayWithCapacity:children.count];
			
			for (RCIOItem *child in children) {
				[moveSignals addObject:[child moveTo:projectDirectory]];
			}
			
			return [[RACSignal zip:moveSignals] mapReplace:projectDirectory];
		}] finally:^{
			[self stopRightBarButtonItemActivityIndicator];
			self.tableView.userInteractionEnabled = YES;
			[NSFileManager.defaultManager removeItemAtURL:temporaryDirectoryURL error:NULL];
		}] subscribeNext:^(RCIODirectory *projectDirectory) {
			if (block) {
				block(projectDirectory);
			}
		} error:^(NSError *error) {
#warning TODO: error handling failed to create project after maxAttempts attempts or failed to move extracted directories in place
			ASSERT(NO);
			if (block) {
				block(nil);
			}
		}];
	}];
}

@end
