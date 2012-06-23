//
//  DocSetOutlineController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocSetContentController.h"
#import "UIViewController+Utilities.h"
#import "DocSet.h"
#import "HighlightTableViewCell.h"
#import "ArtCodeTab.h"


@interface DocSetContentController ()

@property (nonatomic, strong, readonly) DocSet *docSet;
@property (nonatomic, strong, readonly) NSManagedObject *rootNode;
@property (nonatomic, strong, readonly) NSArray *rootNodeSections;

@property (nonatomic, strong) NSArray *searchResults;
- (void)_reloadSearchResults;
- (void)_openNode:(NSManagedObject *)node;

@end

#pragma mark

@interface DocSetContentCell : HighlightTableViewCell

@property (nonatomic) BOOL deprecated;

@end

#pragma mark

@implementation DocSetContentController {
  UISearchDisplayController *_searchController;
}

#pragma mark Properties

@synthesize docSet = _docSet, rootNode = _rootNode, rootNodeSections = _rootNodeSections;
@synthesize searchResults = _searchResults;

#pragma mark Controller's lifecycle

- (id)initWithDocSet:(DocSet *)set rootNode:(NSManagedObject *)rootNode {
  self = [super initWithStyle:UITableViewStylePlain];
  if (!self) 
    return nil;
  
  _docSet = set;
  _rootNode = rootNode;
  _rootNodeSections = [set nodeSectionsForRootNode:rootNode];
  
  self.title = (rootNode != nil) ? [rootNode valueForKey:@"kName"] : set.name;
	self.contentSizeForViewInPopover = CGSizeMake(400.0, 1024.0);
  self.clearsSelectionOnViewWillAppear = YES;

  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

#pragma mark - View lifecycle

- (void)loadView {
	[super loadView];
  
  // This has the side effect of setting self.searchDisplayController
  _searchController = [UISearchDisplayController.alloc initWithSearchBar:UISearchBar.new contentsController:self];
  _searchController.delegate = self;
	_searchController.searchResultsDataSource = self;
	_searchController.searchResultsDelegate = self;
	
	_searchController.searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44);
	_searchController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:NSLocalizedString(@"API",nil), NSLocalizedString(@"Title",nil), nil];
	_searchController.searchBar.selectedScopeButtonIndex = 0;
	_searchController.searchBar.showsScopeBar = NO;
	self.tableView.tableHeaderView = _searchController.searchBar;
	
	self.tableView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
}

#pragma mark - Search display controller delegate

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
	[self.docSet prepareSearch];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	self.searchResults = nil;
	[self _reloadSearchResults];
	return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)searchResultsTableView {
	searchResultsTableView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
	self.searchResults = nil;
	[self.searchDisplayController.searchResultsTableView reloadData];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	if (searchString.length == 0) {
		self.searchResults = nil;
		return YES;
	} else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_reloadSearchResults) object:nil];
		[self performSelector:@selector(_reloadSearchResults) withObject:nil afterDelay:0.2];
		return (self.searchResults == nil);
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView 
{
	if (aTableView == self.tableView) {
		return [self.rootNodeSections count];
	} else if (aTableView == self.searchDisplayController.searchResultsTableView) {
		return 1;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
	if (aTableView == self.tableView) {
		NSDictionary *nodeSection = [self.rootNodeSections objectAtIndex:section];
		return [nodeSection objectForKey:kNodeSectionTitle];
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section 
{
	if (aTableView == self.tableView) {
		return [(NSArray *)[(NSDictionary *)[self.rootNodeSections objectAtIndex:section] objectForKey:kNodeSectionNodes] count];
	} else if (aTableView == self.searchDisplayController.searchResultsTableView) {
		if (!self.searchResults) {
			return 1;
		} else {
			return [self.searchResults count];
		}
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (aTableView == self.tableView) {
		static NSString *CellIdentifier = @"Cell";
		UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
			cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
		}
    
		NSDictionary *nodeSection = [self.rootNodeSections objectAtIndex:indexPath.section];
		NSManagedObject *node = [[nodeSection objectForKey:kNodeSectionNodes] objectAtIndex:indexPath.row];
		
		BOOL expandable = [self.docSet nodeIsExpandable:node];
		cell.accessoryType = (expandable) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
		
		if ([[node valueForKey:@"installDomain"] intValue] > 1) {
			//external link, e.g. man pages
			cell.textLabel.textColor = [UIColor grayColor];
		} else {
			cell.textLabel.textColor = [UIColor blackColor];
		}
		
		int documentType = [[node valueForKey:@"kDocumentType"] intValue];
		if (documentType == 1) {
			cell.imageView.image = [UIImage imageNamed:@"SampleCodeIcon.png"];
		} else if (documentType == 2) {
			cell.imageView.image = [UIImage imageNamed:@"ReferenceIcon.png"];
		} else if (!expandable) {
			cell.imageView.image = [UIImage imageNamed:@"BookIcon.png"];
		} else {
			cell.imageView.image = nil;
		}
		
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.textLabel.text = [node valueForKey:@"kName"];
		cell.detailTextLabel.text = nil;
		cell.accessoryView = nil;
		return cell;
	} else if (aTableView == self.searchDisplayController.searchResultsTableView) {
		static NSString *searchCellIdentifier = @"SearchResultCell";
		DocSetContentCell *cell = (DocSetContentCell *)[aTableView dequeueReusableCellWithIdentifier:searchCellIdentifier];
		if (cell == nil) {
			cell = [[DocSetContentCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:searchCellIdentifier];
      cell.textLabel.backgroundColor = [UIColor clearColor];
//			cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
		}
		
		if (!self.searchResults) {
      cell.textLabelHighlightedCharacters = nil;
			cell.textLabel.text = L(@"Searching...");
			cell.textLabel.textColor = [UIColor grayColor];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.imageView.image = nil;
			UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			[spinner startAnimating];
			cell.accessoryView = spinner;
			cell.detailTextLabel.text = nil;
		} else {
			NSDictionary *result = [self.searchResults objectAtIndex:indexPath.row];
			
			if ([result objectForKey:@"tokenType"]) {
        cell.textLabel.text = [result objectForKey:@"tokenName"];
				cell.accessoryType = UITableViewCellAccessoryNone;
        
        // Deprecation
				NSManagedObject *metaInfo = [self.docSet.managedObjectContext existingObjectWithID:[result objectForKey:@"metainformation"] error:NULL];
				NSSet *deprecatedVersions = [metaInfo valueForKey:@"deprecatedInVersions"];
				cell.deprecated = ([deprecatedVersions count] > 0);
    
        // Icon
        static NSDictionary *iconsByTokenType = nil;
        if (iconsByTokenType == nil) {
          iconsByTokenType = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [UIImage imageNamed:@"Const"], @"econst",
                              [UIImage imageNamed:@"Member.png"], @"intfm",
                              [UIImage imageNamed:@"Macro.png"], @"macro",
                              [UIImage imageNamed:@"Type.png"], @"tdef",
                              [UIImage imageNamed:@"Class.png"], @"cat",
                              [UIImage imageNamed:@"Property.png"], @"intfp",
                              [UIImage imageNamed:@"Const.png"], @"clconst",
                              [UIImage imageNamed:@"Protocol.png"], @"intf",
                              [UIImage imageNamed:@"Member.png"], @"instm",
                              [UIImage imageNamed:@"Class.png"], @"cl",
                              [UIImage imageNamed:@"Struct.png"], @"tag",
                              [UIImage imageNamed:@"Member.png"], @"clm",
                              [UIImage imageNamed:@"Property.png"], @"instp",
                              [UIImage imageNamed:@"Function.png"], @"func",
                              [UIImage imageNamed:@"Global.png"], @"data",
                              nil];
        }
				NSManagedObjectID *tokenTypeID = [result objectForKey:@"tokenType"];
				if (tokenTypeID) {
					NSManagedObject *tokenType = [[self.docSet managedObjectContext] existingObjectWithID:tokenTypeID error:NULL];
					NSString *tokenTypeName = [tokenType valueForKey:@"typeName"];
					UIImage *icon = [iconsByTokenType objectForKey:tokenTypeName];
					cell.imageView.image = icon;
				} else {
					cell.imageView.image = nil;
				}
				
				NSManagedObjectID *parentNodeID = [result objectForKey:@"parentNode"];
				if (parentNodeID) {
					NSManagedObject *parentNode = [[self.docSet managedObjectContext] existingObjectWithID:parentNodeID error:NULL];
					NSString *parentNodeTitle = [parentNode valueForKey:@"kName"];
					cell.detailTextLabel.text = parentNodeTitle;
				} else {
					cell.detailTextLabel.text = nil;
				}
			} else {
				cell.deprecated = NO;
				cell.textLabel.text = [result objectForKey:@"kName"];
				NSManagedObjectID *objectID = [result objectForKey:@"objectID"];
				
				NSManagedObject *node = [[self.docSet managedObjectContext] existingObjectWithID:objectID error:NULL];
        
				BOOL expandable = [self.docSet nodeIsExpandable:node];
				cell.accessoryType = (expandable) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        
				int documentType = [[node valueForKey:@"kDocumentType"] intValue];
				if (documentType == 1) {
					cell.imageView.image = [UIImage imageNamed:@"SampleCodeIcon.png"];
				} else if (documentType == 2) {
					cell.imageView.image = [UIImage imageNamed:@"ReferenceIcon.png"];
				} else if (!expandable) {
					cell.imageView.image = [UIImage imageNamed:@"BookIcon.png"];
				} else {
					cell.imageView.image = nil;
				}
				cell.detailTextLabel.text = nil;
			}
      
      cell.textLabelHighlightedCharacters = [NSIndexSet indexSetWithIndexesInRange:[[result objectForKey:@"tokenName"] rangeOfString:self.searchDisplayController.searchBar.text options:NSCaseInsensitiveSearch]];
			cell.textLabel.textColor = [UIColor blackColor];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryView = nil;
		}
		return cell;
	}
	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.tableView) {
		NSDictionary *nodeSection = [self.rootNodeSections objectAtIndex:indexPath.section];
		NSManagedObject *node = [[nodeSection objectForKey:kNodeSectionNodes] objectAtIndex:indexPath.row];
		[self _openNode:node];
	} else if (tableView == self.searchDisplayController.searchResultsTableView) {
		[self.searchDisplayController.searchBar resignFirstResponder];
		NSDictionary *result = [self.searchResults objectAtIndex:indexPath.row];
		if ([result objectForKey:@"tokenType"]) {
      [self.artCodeTab pushURL:[self.docSet docSetURLForToken:result]];
      [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
		} else {
			NSManagedObject *node = [[self.docSet managedObjectContext] existingObjectWithID:[result objectForKey:@"objectID"] error:NULL];
			[self _openNode:node];
		}
	}
}

#pragma mark - Private methods

- (void)_reloadSearchResults {
	NSString *searchTerm = self.searchDisplayController.searchBar.text;
	DocSetSearchCompletionHandler completionHandler = ^(NSString *completedSearchTerm, NSArray *results) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSString *currentSearchTerm = self.searchDisplayController.searchBar.text;
			if ([currentSearchTerm isEqualToString:completedSearchTerm]) {
				self.searchResults = results;
				[self.searchDisplayController.searchResultsTableView reloadData];
			}
		});
	};
	
	if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == 0) {
		[self.docSet searchForTokensMatching:searchTerm completion:completionHandler];
	} else {
		[self.docSet searchForNodesMatching:searchTerm completion:completionHandler];
	}
}

- (void)_openNode:(NSManagedObject *)node {
	BOOL expandable = [self.docSet nodeIsExpandable:node];
	if (expandable) {
		DocSetContentController *childViewController = [[DocSetContentController alloc] initWithDocSet:self.docSet rootNode:node];
		[self.navigationController pushViewController:childViewController animated:YES];
	} else {
		if ([[node valueForKey:@"installDomain"] intValue] > 1) {
			NSURL *webURL = [self.docSet webURLForNode:node];
			[[UIApplication sharedApplication] openURL:webURL];
			return;
		}
    [self.artCodeTab pushURL:[self.docSet docSetURLForNode:node]];
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
	}
}

@end

#pragma mark

@implementation DocSetContentCell {
  UIView *_deprecatedView;
}

@synthesize deprecated = _deprecated;

- (void)setDeprecated:(BOOL)deprecated {
  if (deprecated == _deprecated)
    return;
  
  _deprecated = deprecated;
  
  if (deprecated) {
    _deprecatedView = UIView.new;
    _deprecatedView.backgroundColor = [UIColor redColor];
    [self.contentView insertSubview:_deprecatedView aboveSubview:self.textLabel];
  } else {
    [_deprecatedView removeFromSuperview];
    _deprecatedView = nil;
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  if (_deprecatedView) {
    CGRect deprecatedViewFrame = self.textLabel.frame;
    deprecatedViewFrame.origin.y += deprecatedViewFrame.size.height / 2.0;
    deprecatedViewFrame.size.height = 1;
    _deprecatedView.frame = deprecatedViewFrame;
  }
}

@end