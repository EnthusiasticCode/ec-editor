//
//  DocSetOutlineController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetOutlineController.h"
#import "UIViewController+Utilities.h"
#import "ArtCodeTab.h"
#import "DocSetDownloadManager.h"

@interface DocSetOutlineController ()

@property (nonatomic, strong, readwrite) NSString *bookJSONPath;

- (NSURL *)_docSetURLForOulineItem:(DocSetOutlineItem *)item;

@end

@implementation DocSetOutlineController {
  DocSetOutlineItem *_rootOutlineItem;
  NSArray *_visibleOutlineItems;
}

#pragma mark - Properties

@synthesize docSetURL = _docSetURL, bookJSONPath = _bookJSONPath;

- (void)setDocSetURL:(NSURL *)docSetURL {
  if (docSetURL == _docSetURL)
    return;
  
  _docSetURL = docSetURL;
  
  if ([docSetURL.scheme isEqualToString:@"docset"])
    docSetURL = docSetURL.docSetFileURLByResolvingDocSet;
    
  NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [docSetURL path];
	NSString *pathForBook = nil;
	while (path && ![path isEqual:@"/"]) {		
		NSString *possibleBookPath = [path stringByAppendingPathComponent:@"book.json"];
		BOOL bookExists = [fm fileExistsAtPath:possibleBookPath];
		if (bookExists) {
			pathForBook = possibleBookPath;
			break;
		}
		path = [path stringByDeletingLastPathComponent];
	}
	
  self.bookJSONPath = pathForBook;
}

- (void)setBookJSONPath:(NSString *)bookJSONPath {
  if ([bookJSONPath isEqualToString:_bookJSONPath])
    return;
  
  _bookJSONPath = bookJSONPath;
  
  NSDictionary *book = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:bookJSONPath] options:0 error:NULL];
  _rootOutlineItem = [[DocSetOutlineItem alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:(self.title = [book objectForKey:@"title"]), @"title", [book objectForKey:@"sections"], @"sections", nil] level:0];
  _visibleOutlineItems = [_rootOutlineItem flattenedChildren];
  if (self.isViewLoaded)
    [self.tableView reloadData];
}

#pragma mark - Controller lifecycle

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self)
    return nil;
  
  self.contentSizeForViewInPopover = CGSizeMake(500, 500);
  
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.artCodeTab.currentDocSet) {
    self.docSetURL = self.artCodeTab.currentLocation;
  }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _visibleOutlineItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  DocSetOutlineCell *cell = (DocSetOutlineCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[DocSetOutlineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
	DocSetOutlineItem *item = [_visibleOutlineItems objectAtIndex:indexPath.row];
	cell.outlineItem = item;
	cell.delegate = self;
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self.artCodeTab pushURL:[self _docSetURLForOulineItem:[_visibleOutlineItems objectAtIndex:indexPath.row]]];
  [self.presentingPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - Outline cell delegate

- (void)docSetOutlineCellDidTapDisclosureButton:(DocSetOutlineCell *)cell {
	DocSetOutlineItem *item = cell.outlineItem;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_visibleOutlineItems indexOfObject:item] inSection:0];
	
	if (item.children.count > 0 && !item.expanded) {
		//expand
		item.expanded = YES;
		NSArray *expandedChildren = [item flattenedChildren];
		NSMutableArray *addedIndexPaths = [NSMutableArray array];
		for (NSUInteger i=0; i<expandedChildren.count; i++) {
			NSIndexPath *addedIndexPath = [NSIndexPath indexPathForRow:indexPath.row + i + 1 inSection:0];
			[addedIndexPaths addObject:addedIndexPath];
		}
		_visibleOutlineItems = [_rootOutlineItem flattenedChildren];
		[self.tableView insertRowsAtIndexPaths:addedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	} else if (item.children.count > 0 && item.expanded) {
		//collapse
		NSMutableArray *removedIndexPaths = [NSMutableArray array];
		NSArray *collapsedChildren = [item flattenedChildren];
		item.expanded = NO;
		for (NSUInteger i=0; i<collapsedChildren.count; i++) {
			NSIndexPath *removedIndexPath = [NSIndexPath indexPathForRow:indexPath.row + i + 1 inSection:0];
			[removedIndexPaths addObject:removedIndexPath];
		}
		_visibleOutlineItems = [_rootOutlineItem flattenedChildren];
		[self.tableView deleteRowsAtIndexPaths:removedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

#pragma mark - Private methods

- (NSURL *)_docSetURLForOulineItem:(DocSetOutlineItem *)item {
  NSString *href = item.href;
  
  //strip the anchor from the URL:
//  NSRange hashRange = [href rangeOfString:@"#"];
//  if (hashRange.location != NSNotFound) href = [href substringToIndex:hashRange.location];
  
  NSURL *itemURL = [[NSURL fileURLWithPath:[self.bookJSONPath stringByDeletingLastPathComponent]] URLByAppendingPathComponent:href];
  return itemURL.docSetURLByRetractingFileURL;
}

@end

#pragma mark

@implementation DocSetOutlineItem

@synthesize expanded, title, aref, href, level, children;

- (id)initWithDictionary:(NSDictionary *)outlineInfo level:(int)outlineLevel
{
	self = [super init];
	if (self) {
		title = [outlineInfo objectForKey:@"title"];
		level = outlineLevel;
		expanded = (level <= 0);
		NSArray *sections = [outlineInfo objectForKey:@"sections"];
		aref = [outlineInfo objectForKey:@"aref"];
		href = [outlineInfo objectForKey:@"href"];
		NSMutableArray *subItems = [NSMutableArray array];
		for (NSDictionary *subItemInfo in sections) {
			DocSetOutlineItem *subItem = [[DocSetOutlineItem alloc] initWithDictionary:subItemInfo level:level + 1];
			[subItems addObject:subItem];
		}
		children = [NSArray arrayWithArray:subItems];
	}
	return self;
}

- (NSArray *)flattenedChildren
{
	NSMutableArray *flatList = [NSMutableArray array];
	for (DocSetOutlineItem *child in children) {
		[child addOpenChildren:flatList];
	}
	return [NSArray arrayWithArray:flatList];
}

- (void)addOpenChildren:(NSMutableArray *)list
{
	[list addObject:self];
	if (expanded) {
		for (DocSetOutlineItem *child in children) {
			[child addOpenChildren:list];
		}
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ (level %i)", title, level];
}

@end

#pragma mark

@implementation DocSetOutlineCell

@synthesize delegate, outlineItem;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		outlineDisclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
		outlineDisclosureButton.frame = CGRectMake(0, 0, 44, 44);
		[outlineDisclosureButton setBackgroundImage:[UIImage imageNamed:@"OutlineDisclosureButton.png"] forState:UIControlStateNormal];
		outlineDisclosureButton.hidden = YES;
		[outlineDisclosureButton addTarget:self action:@selector(expandOrCollapse:) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:outlineDisclosureButton];
	}
	return self;
}

- (void)setOutlineItem:(DocSetOutlineItem *)item
{
	outlineItem = item;
	self.textLabel.text = outlineItem.title;
	
	self.indentationWidth = 32.0 + 15.0 * (outlineItem.level - 1);
	self.indentationLevel = 1; //outlineItem.level;
	self.textLabel.font = (outlineItem.level <= 1) ? [UIFont boldSystemFontOfSize:17.0] : [UIFont boldSystemFontOfSize:15.0];
	
	if (outlineItem.children.count > 0) {
		outlineDisclosureButton.frame = CGRectMake(15 * (outlineItem.level - 1), 0, 44, 44);
		if (outlineItem.expanded) {
			outlineDisclosureButton.transform = CGAffineTransformMakeRotation(M_PI / 2);
		} else {
			outlineDisclosureButton.transform = CGAffineTransformIdentity;
		}
		outlineDisclosureButton.hidden = NO;
	} else {
		outlineDisclosureButton.hidden = YES;
	}
}

- (void)expandOrCollapse:(id)sender
{
	[UIView beginAnimations:nil context:nil];
	if (outlineItem.expanded) {
		outlineDisclosureButton.transform = CGAffineTransformIdentity;
	} else {
		outlineDisclosureButton.transform = CGAffineTransformMakeRotation(M_PI / 2);
	}
	if ([self.delegate respondsToSelector:@selector(docSetOutlineCellDidTapDisclosureButton:)]) {
		[self.delegate docSetOutlineCellDidTapDisclosureButton:self];
	}
	[UIView commitAnimations];
}

@end
