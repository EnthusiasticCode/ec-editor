//
//  QuickTOCController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 07/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickTOCController.h"

#import "CodeFileController.h"
#import "HighlightTableViewCell.h"
#import "QuickBrowsersContainerController.h"
#import "RACSignal+ScoreForAbbreviation.h"
#import "TMSymbol.h"


@implementation QuickTOCController {
  NSArray *_filteredSymbolList;
}

#pragma mark - Controller lifecycle

- (id)init {
  self = [super initWithNibNamed:nil title:@"Symbol list" searchBarStaticOnTop:YES];
  if (self == nil) return nil;
  self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Symbols" image:[UIImage imageNamed:@"UITabBar_symbol"] tag:0];
  self.navigationItem.title = @"Table of Content";
	
	[[[self rac_signalForKeyPath:@"quickBrowsersContainerController.contentController.codeUnit.symbolList" onObject:self] filterArraySignalByAbbreviation:self.searchBarTextSubject extrapolateTargetStringBlock:^(TMSymbol *symbol) {
		return symbol.title;
	}] toProperty:@keypath(self.filteredItems) onObject:self];
	
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchBar.placeholder = @"Filter symbols";
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
	RACTupleUnpack(TMSymbol *symbol, NSIndexSet *hitMask) = self.filteredItems[indexPath.row];

  cell.textLabel.text = symbol.title;
  cell.imageView.image = symbol.icon;
#warning TODO: indent here, remove leading spaces from the symbol text
//  cell.indentationLevel = symbol.indentation;
  cell.textLabelHighlightedCharacters = hitMask;
  if (symbol.isSeparator) {
    if (!cell.backgroundView) cell.backgroundView = [[UIView alloc] init];
    cell.backgroundView.backgroundColor = [UIColor lightGrayColor];
  } else {
    cell.backgroundView = nil;
  }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  TMSymbol *symbol = [self.filteredItems[indexPath.row] first];
  if (symbol.isSeparator) return 22;
  return UITableViewAutomaticDimension;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#warning TODO: push an url instead
  [table deselectRowAtIndexPath:indexPath animated:YES];
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  TMSymbol *selectedSymbol = [self.filteredItems[indexPath.row] first];
  [[(CodeFileController *)self.quickBrowsersContainerController.contentController codeView] setSelectionRange:selectedSymbol.range];
}

@end
