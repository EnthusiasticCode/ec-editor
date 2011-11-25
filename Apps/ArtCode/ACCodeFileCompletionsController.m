//
//  ACCodeViewCompletionsController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 15/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileCompletionsController.h"
#import "ACCodeFileCompletionCell.h"

#import <ECFoundation/ECAttributedUTF8FileBuffer.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeIndex.h>

#import "ACFileDocument.h"
#import "ACCodeFileController.h"
#import "ACCodeFileKeyboardAccessoryView.h"


@interface ACCodeFileCompletionsController ()

@property (nonatomic, strong) ECCodeIndex *_codeIndex;
@property (nonatomic, strong) ECCodeUnit *_codeUnit;
@property (nonatomic, strong) id<ECCodeCompletionResultSet> _completionResults;

@end


@implementation ACCodeFileCompletionsController

#pragma mark - Properties

@synthesize targetCodeFileController, targetKeyboardAccessoryView;
@synthesize offsetInDocumentForCompletions;
@synthesize completionCell;
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
    if ([self._completionResults count])
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self._completionResults indexOfHighestRatedCompletionResult] inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (void)viewDidUnload
{
    [self setCompletionCell:nil];
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
    
    ACCodeFileCompletionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"CompletionControllerCell" owner:self options:nil];
        cell = self.completionCell;
        completionCell = nil;
        
        cell.definitionLabel.font = cell.typeLabel.font = [UIFont fontWithName:@"Inconsolata-dz" size:14];
        cell.typeLabelSize = 0;
    }
    
    id<ECCodeCompletionResult> result = [self._completionResults completionResultAtIndex:[indexPath indexAtPosition:1]];
    
    // Kind
    cell.kindImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"completionKind_%d", [result cursorKind]]];
    
    // Type
    // TODO
    
    // Definition
    NSInteger parenDepth = 0;
    NSMutableString *definition = [NSMutableString new];
    for (id<ECCodeCompletionChunk> chunk in [[result completionString] completionChunks])
    {
        switch ([chunk kind]) {
            case CXCompletionChunk_Comma:
                [definition appendString:@", "];
                break;
                
            case CXCompletionChunk_Equal:
                [definition appendString:@" = "];
                break;
                
                
            case CXCompletionChunk_LeftParen:
                parenDepth++;
                [definition appendString:[chunk text]];
                break;
                
            case CXCompletionChunk_RightParen:
                parenDepth--;
                [definition appendString:[chunk text]];
                break;
                
            case CXCompletionChunk_Text:
                if (parenDepth == 0)
                    break;
                [definition appendString:[chunk text]];
                break;
                
            case CXCompletionChunk_Informative:
            case CXCompletionChunk_SemiColon:
                // Ignore
                break;
                
            case CXCompletionChunk_Optional:
            case CXCompletionChunk_VerticalSpace:
                // Unhandled
                ECASSERT(NO && "Unhandled chunk kind");
                break;
                
            case CXCompletionChunk_Placeholder:
            default:
                [definition appendString:[chunk text]];
                break;
        }
    }
    cell.definitionLabel.text = definition;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Dismiss selection
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.targetKeyboardAccessoryView dismissPopoverForItemAnimated:YES];
}

@end
