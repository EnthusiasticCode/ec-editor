//
//  DocSetBookmarksController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetBookmarksController.h"
#import "UIViewController+Utilities.h"
#import "DocSet.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "DocSetDownloadManager.h"

static NSString * const DocSetBookmarkTitleKey = @"title";
static NSString * const DocSetBookmarkSubtitleKey = @"subtitle";
static NSString * const DocSetBookmarkDocSetURLKey = @"URL";

@interface DocSetBookmarksController ()

- (void)_addBookmarkAction:(id)sender;

@end

@implementation DocSetBookmarksController {
  NSURL *_bookmarksPlistURL;
  NSMutableArray *_bookmarksArray;
}

#pragma mark - Properties

@synthesize docSet = _docSet, delegate = _delegate;

- (void)setDocSet:(DocSet *)docSet {
  if (docSet == _docSet)
    return;
  
  // Save current plist if any
  if (_bookmarksPlistURL && _bookmarksArray) {
    [[NSPropertyListSerialization dataWithPropertyList:_bookmarksArray format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL] writeToURL:_bookmarksPlistURL atomically:YES];
  }
  
  _docSet = docSet;
  
  // Load bookmarks plist
  _bookmarksPlistURL = docSet ? [NSURL fileURLWithPath:[docSet.path stringByAppendingPathComponent:@"Contents/Resources/Documents/bookmarks.plist"]] : nil;
  if (_bookmarksPlistURL && [[NSFileManager defaultManager] fileExistsAtPath:_bookmarksPlistURL.path]) {
    _bookmarksArray =[NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:_bookmarksPlistURL] options:NSPropertyListMutableContainers format:nil error:NULL];
  } else {
    _bookmarksArray = [[NSMutableArray alloc] init];
  }
  [self.tableView reloadData];
}

#pragma mark - Controller lifecycle

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self)
    return nil;
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_addBookmarkAction:)];
  self.title = L(@"Bookmarks");
    
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.artCodeTab.currentLocation.url.docSet) {
    self.docSet = self.artCodeTab.currentLocation.url.docSet;
  }
  NSURL *url = self.artCodeTab.currentLocation.url;
  if (url) {
    self.navigationItem.rightBarButtonItem.enabled = [url.scheme isEqualToString:@"docset"] && url.path.length > 0;
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  self.docSet = nil;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _bookmarksArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
  }
  
  NSDictionary *bookamrk = [_bookmarksArray objectAtIndex:indexPath.row];
  cell.textLabel.text = [bookamrk objectForKey:DocSetBookmarkTitleKey];
  cell.detailTextLabel.text = [bookamrk objectForKey:DocSetBookmarkSubtitleKey];
  
  return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *bookmark = [_bookmarksArray objectAtIndex:indexPath.row];
  NSString *url = [bookmark objectForKey:DocSetBookmarkDocSetURLKey];
  if (!url)
    return;
  
  [self.artCodeTab pushDocSetURL:[NSURL URLWithString:url]];
  [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - Private methods

- (void)_addBookmarkAction:(id)sender {
  ASSERT(self.artCodeTab.currentLocation);
  NSString *anchorTitle = @"";
  NSString *bookmarkTitle = [self.delegate respondsToSelector:@selector(docSetBookmarksController:titleForBookmarksAtURL:anchorTitle:)] ? [self.delegate docSetBookmarksController:self titleForBookmarksAtURL:self.artCodeTab.currentLocation.url anchorTitle:&anchorTitle] : self.artCodeTab.currentLocation.path.lastPathComponent;
  
  [_bookmarksArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:bookmarkTitle, DocSetBookmarkTitleKey, anchorTitle, DocSetBookmarkSubtitleKey, self.artCodeTab.currentLocation.url.absoluteString, DocSetBookmarkDocSetURLKey, nil]];
  [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_bookmarksArray.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
