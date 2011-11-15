//
//  ACCodeViewCompletionsController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 15/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileCompletionsController.h"

#import <ECFoundation/ECAttributedUTF8FileBuffer.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeIndex.h>

#import "ACFileDocument.h"
#import "ACCodeFileController.h"

#import <ECUIKit/ECPopoverController.h>


@interface ACCodeFileCompletionsController ()

@property (nonatomic, strong) ECCodeIndex *_codeIndex;
@property (nonatomic, strong) ECCodeUnit *_codeUnit;
@property (nonatomic, strong) id<ECCodeCompletionResultSet> _completionResults;

@end


@implementation ACCodeFileCompletionsController

#pragma mark - Properties

@synthesize targetCodeFileController, targetPopoverController;
@synthesize offsetInDocumentForCompletions;
@synthesize _codeIndex, _codeUnit, _completionResults;

- (void)setTargetCodeFileController:(ACCodeFileController *)value
{
    if (value == targetCodeFileController)
        return;
    [self willChangeValueForKey:@"targetCodeFileController"];
    targetCodeFileController = value;
    self._codeUnit = nil;
    [self didChangeValueForKey:@"targetCodeFileController"];
}

- (void)setOffsetInDocumentForCompletions:(NSUInteger)value
{
    if (value == offsetInDocumentForCompletions)
        return;
    [self willChangeValueForKey:@"offsetInDocumentForCompletions"];
    offsetInDocumentForCompletions = value;
    self._completionResults = nil;
    [self.tableView reloadData];
    [self didChangeValueForKey:@"offsetInDocumentForCompletions"];
}

- (ECCodeIndex *)_codeIndex
{
    if (!_codeIndex)
        _codeIndex = [ECCodeIndex new];
    return _codeIndex;
}

- (ECCodeUnit *)_codeUnit
{
    ECASSERT(self.targetCodeFileController != nil);
    
    if (!_codeUnit)
        _codeUnit = [self._codeIndex codeUnitForFileBuffer:[self.targetCodeFileController.document fileBuffer] scope:nil];
    return _codeUnit;
}

- (id<ECCodeCompletionResultSet>)_completionResults
{
    ECASSERT(self.targetCodeFileController.document.fileBuffer.length > self.offsetInDocumentForCompletions);
    
    if (!_completionResults)
        _completionResults = [self._codeUnit completionsAtOffset:self.offsetInDocumentForCompletions];
    return _completionResults;
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self._completionResults indexOfHighestRatedCompletionResult] inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self._codeUnit = nil;
    self._codeIndex = nil;
    self._completionResults = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self._completionResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    id<ECCodeCompletionResult> result = [self._completionResults completionResultAtIndex:[indexPath indexAtPosition:1]];
    
    NSMutableString *text = [NSMutableString new];
    for (id<ECCodeCompletionChunk> chunk in [[result completionString] completionChunks])
        [text appendFormat:@"%@, ", [chunk text]];
    cell.textLabel.text = text;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
