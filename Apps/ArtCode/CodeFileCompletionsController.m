//
//  CodeViewCompletionsController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 15/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileCompletionsController.h"
#import "CodeFileCompletionCell.h"

#import "TMUnit.h"
#import "Index.h"
#import "TextRange.h"

#import "CodeFileController.h"
#import "CodeFile.h"
#import "CodeFileKeyboardAccessoryView.h"

#import "ACProjectFile.h"


@interface CodeFileCompletionsController () {
    CGFloat _minimumTypeLabelSize;
}

@property (nonatomic, strong) id<TMCompletionResultSet> _completionResults;

@end

@implementation CodeFileCompletionsController

#pragma mark - Properties

@synthesize targetCodeFileController, targetKeyboardAccessoryView;
@synthesize offsetInDocumentForCompletions;
@synthesize completionCell;
@synthesize _completionResults;


- (void)setOffsetInDocumentForCompletions:(NSUInteger)value
{
    if (value == offsetInDocumentForCompletions)
        return;
    offsetInDocumentForCompletions = value;
    self._completionResults = nil;
    _minimumTypeLabelSize = 0;
    [self.tableView reloadData];
}

- (id<TMCompletionResultSet>)_completionResults
{
    ASSERT(self.targetCodeFileController.projectFile.codeFile.length > self.offsetInDocumentForCompletions);

    if (!_completionResults)
        _completionResults = [self.targetCodeFileController.codeUnit completionsAtOffset:self.offsetInDocumentForCompletions];
    return _completionResults;
}

- (BOOL)hasCompletions
{
    return [self._completionResults count] > 0;
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
    
    CodeFileCompletionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"CompletionControllerCell" owner:self options:nil];
        cell = self.completionCell;
        completionCell = nil;
        
        cell.definitionLabel.font = cell.typeLabel.font = [UIFont fontWithName:@"Inconsolata-dz" size:14];
        cell.typeLabelSize = 0;
    }
    
    id<TMCompletionResult> result = [self._completionResults completionResultAtIndex:[indexPath indexAtPosition:1]];
    
    // Kind
    cell.kindImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"completionKind_%d", [result cursorKind]]];
    
    // Definition
    NSInteger parenDepth = 0;
    NSMutableString *definition = [NSMutableString new];
    NSString *resultType = nil;
    for (id<TMCompletionChunk> chunk in [[result completionString] completionChunks])
    {
        switch ([chunk kind]) {
            case CXCompletionChunk_ResultType:
                ASSERT(resultType == nil && "There should be only one result type");
                resultType = [chunk text];
                break;
                
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
                ASSERT(NO && "Unhandled chunk kind");
                break;
                
            default:
                [definition appendString:[chunk text]];
                break;
        }
    }
    cell.definitionLabel.text = definition;
    cell.typeLabel.text = resultType;
    
    // Type label size
    if (resultType)
    {
        CGSize typeLabelSize = [cell.typeLabel sizeThatFits:CGSizeZero];
        _minimumTypeLabelSize = MIN(typeLabelSize.width, 100);
    }
    cell.typeLabelSize = _minimumTypeLabelSize;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Insert selected completion
    id<TMCompletionResult> result = [self._completionResults completionResultAtIndex:[indexPath indexAtPosition:1]];
    NSMutableString *completionString = [NSMutableString new];
    for (id<TMCompletionChunk> chunk in [[result completionString] completionChunks])
    {
        NSLog(@"%d - %@", [chunk kind], [chunk text]);
        switch ([chunk kind]) {
            case CXCompletionChunk_Placeholder:
                [completionString appendFormat:@"<#%@#>", [chunk text]];
                break;
                
            case CXCompletionChunk_ResultType:
            case CXCompletionChunk_Informative:
            case CXCompletionChunk_SemiColon:
            case CXCompletionChunk_Equal:
                // Ignore
                break;
                
            case CXCompletionChunk_Optional:
            case CXCompletionChunk_VerticalSpace:
                // Unhandled
                ASSERT(NO && "Unhandled chunk kind");
                break;
                
            default:
                [completionString appendString:[chunk text]];
                break;
        }
    }
    [self.targetCodeFileController.codeView replaceRange:[TextRange textRangeWithRange:[self._completionResults filterStringRange]] withText:completionString];
    
    // Dismiss selection
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.targetKeyboardAccessoryView dismissPopoverForItemAnimated:YES];
}

@end
