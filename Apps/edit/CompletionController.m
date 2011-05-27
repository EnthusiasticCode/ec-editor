//
//  CompletionController.m
//  edit
//
//  Created by Uri Baghin on 5/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CompletionController.h"

#import "ECPatriciaTrie.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"

static const ECPatriciaTrieEnumerationOptions _options = ECPatriciaTrieEnumerationOptionsSkipRoot | ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord | ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch;

@interface CompletionController ()
@property (nonatomic, retain) NSArray *filteredResults;
- (void)_filterResults;
@end

@implementation CompletionController

@synthesize results = _results;
@synthesize match = _match;
@synthesize filteredResults = _filteredResults;
@synthesize resultSelectedBlock = _resultSelectedBlock;

- (void)setResults:(ECPatriciaTrie *)results
{
    if (results == _results)
        return;
    [_results release];
    _results = [results retain];
    NSLog(@"number of results in completion controller: %u", [results count]);
    [self _filterResults];
    [self.tableView reloadData];
}

- (void)setMatch:(NSString *)match
{
    if ([match isEqualToString:_match])
        return;
    [_match release];
    _match = [match retain];
    [self _filterResults];
    [self.tableView reloadData];
}

- (void)dealloc
{
    self.results = nil;
    self.match = nil;
    self.filteredResults = nil;
    self.resultSelectedBlock = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)_filterResults
{
    self.filteredResults = [self.results nodesForKeysStartingWithString:self.match options:_options];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    ECPatriciaTrie *node = [self.filteredResults objectAtIndex:indexPath.row];
    cell.textLabel.text = node.key;
    if (![node nodeCountWithOptions:_options])
        cell.accessoryType = UITableViewCellAccessoryNone;
    else
        if (node.object)
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ECPatriciaTrie *node = [self.filteredResults objectAtIndex:indexPath.row];
    if (!node.object && [node nodeCountWithOptions:_options])
        return [self setMatch:node.key];
    if (!node.object)
        return;
    self.resultSelectedBlock(node.object);
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    ECPatriciaTrie *node = [self.filteredResults objectAtIndex:indexPath.row];
    if ([node count])
        return [self setMatch:node.key];
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
