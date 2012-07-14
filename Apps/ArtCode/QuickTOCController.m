//
//  QuickTOCController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 07/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickTOCController.h"
#import "QuickBrowsersContainerController.h"
#import "CodeFileController.h"
#import "CodeView.h"

#import "NSArray+ScoreForAbbreviation.h"

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"
#import "TMUnit.h"
#import "TMSymbol.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"

@implementation QuickTOCController {
  NSArray *_filteredSymbolList;
  NSArray *_filteredSymbolListHitMask;
}

#pragma mark - Properties

- (NSArray *)filteredItems
{
  if (!_filteredSymbolList)
  {
    if ([self.searchBar.text length])
    {
      NSArray *hitMask = nil;
      _filteredSymbolList = [[(CodeFileController *)self.quickBrowsersContainerController.contentController codeUnit].symbolList sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMask extrapolateTargetStringBlock:^NSString *(TMSymbol *element) {
        return element.title;
      }];
      _filteredSymbolListHitMask = hitMask;
    }
    else
    {
      _filteredSymbolList = [(CodeFileController *)self.quickBrowsersContainerController.contentController codeUnit].symbolList;
      _filteredSymbolListHitMask = nil;
    }
  }
  return _filteredSymbolList;
}

- (void)invalidateFilteredItems
{
  _filteredSymbolList = nil;
  _filteredSymbolListHitMask = nil;
}

#pragma mark - Controller lifecycle

- (id)init
{
  self = [super initWithTitle:@"Symbol list" searchBarStaticOnTop:YES];
  if (!self)
    return nil;
  self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Symbols" image:[UIImage imageNamed:@"UITabBar_symbol"] tag:0];
  self.navigationItem.title = @"Table of Content";
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.searchBar.placeholder = @"Filter symbols";
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
  TMSymbol *symbol = [[self filteredItems] objectAtIndex:indexPath.row];
  cell.textLabel.text = symbol.title;
  cell.imageView.image = symbol.icon;
//  cell.indentationLevel = symbol.indentation;
  cell.textLabelHighlightedCharacters = _filteredSymbolListHitMask ? [_filteredSymbolListHitMask objectAtIndex:indexPath.row] : nil;
  if (symbol.isSeparator)
  {
    if (!cell.backgroundView)
      cell.backgroundView = [UIView new];
    cell.backgroundView.backgroundColor = [UIColor lightGrayColor];
  }
  else
  {
    cell.backgroundView = nil;
  }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  TMSymbol *symbol = [[self filteredItems] objectAtIndex:indexPath.row];
  if (symbol.isSeparator)
    return 22;
  return UITableViewAutomaticDimension;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // TODO push an url instead
  [table deselectRowAtIndexPath:indexPath animated:YES];
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  TMSymbol *selectedSymbol = [[self filteredItems] objectAtIndex:indexPath.row];
  [[(CodeFileController *)self.quickBrowsersContainerController.contentController codeView] setSelectionRange:selectedSymbol.range];
}

@end
