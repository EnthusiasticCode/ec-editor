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
#import "CodeFile.h"
#import "CodeView.h"

#import "NSArray+ScoreForAbbreviation.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"

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
            _filteredSymbolList = [[[(CodeFileController *)self.quickBrowsersContainerController.contentController codeFile] symbolList] sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMask extrapolateTargetStringBlock:^NSString *(CodeFileSymbol *element) {
                return element.title;
            }];
            _filteredSymbolListHitMask = hitMask;
        }
        else
        {
            _filteredSymbolList = [[(CodeFileController *)self.quickBrowsersContainerController.contentController codeFile] symbolList];
            _filteredSymbolListHitMask = nil;
        }
    }
    return _filteredSymbolList;
}

- (void)invalidateFilteredItems
{
    _filteredSymbolList = nil;
    _filteredSymbolListHitMask = nil;
    [super invalidateFilteredItems];
}

#pragma mark - Controller lifecycle

- (id)init
{
    self = [super initWithTitle:@"Symbol list" searchBarStaticOnTop:YES];
    if (!self)
        return nil;
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Symbols" image:nil tag:0];
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
    
    CodeFileSymbol *symbol = [[self filteredItems] objectAtIndex:indexPath.row];
    cell.textLabel.text = symbol.title;
    cell.imageView.image = symbol.icon;
    cell.indentationLevel = symbol.indentation;
    cell.textLabelHighlightedCharacters = _filteredSymbolListHitMask ? [_filteredSymbolListHitMask objectAtIndex:indexPath.row] : nil;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [table deselectRowAtIndexPath:indexPath animated:YES];
    [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
    [[(CodeFileController *)self.quickBrowsersContainerController.contentController codeView] setSelectionRange:[[[self filteredItems] objectAtIndex:indexPath.row] range]];
}

@end
