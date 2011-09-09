//
//  ACCodeFileFilterController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileFilterController.h"

enum ACCodeFileFilterSections {
    /// Identifies the symbol section of the filter table view.
    ACCodeFileFilterSymbolsSection,
    
    /// Identifies the search in file section of the filter table view.
    ACCodeFileFilterSearchSection,
    
    /// Identifies the additional section containing go-to-line and other filter results.
    ACCodeFileFilterOtherSection
    
    // TODO add recent searches (global)
};

@implementation ACCodeFileFilterController {
    NSRegularExpression *goToLineRegExp;
    
    /// Array with sections arranges as in ACCodeFileFilterSections.
    /// Every entry of the sections array is another array that contains fitlered
    /// restults for the section.
    NSArray *sections;
}

#pragma mark - Private Methods

/// Returns the ACCodeFileFilterSections
- (NSInteger)filterSectionForSection:(NSInteger)section
{
    ECASSERT(section < [sections count]);
    
    NSInteger result = 0;
    for (NSArray *sec in sections)
    {
        if ([sec count] > 0)
        {
            if (section == 0)
                return result;
            else
                section--;
        }
        result++;
    }
    
    return -1;
}

#pragma mark - Properties

@synthesize targetCodeIndexerDataSource, filterString;
@synthesize startSearchingBlock, endSearchingBlock;
@synthesize tableView = _tableView;
@synthesize replaceToolView;

- (void)setFilterString:(NSString *)string
{
    filterString = string;
    
    if (startSearchingBlock)
        startSearchingBlock(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __block NSUInteger sectionIndex = 0;
        
        // Prepare other section
        NSMutableArray *otherSection = [sections objectAtIndex:ACCodeFileFilterOtherSection];
        NSInteger otherSectionOldCount = [otherSection count];
        [otherSection removeAllObjects];
        
        // Search for go to line
        [goToLineRegExp enumerateMatchesInString:filterString options:NSMatchingReportCompletion range:NSMakeRange(0, [filterString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSUInteger otherSectionCount = [otherSection count];
            if (flags & NSMatchingCompleted)
            {
                if (otherSectionCount == 0 && otherSectionOldCount > 0)
                {
                    // Remove section if no result found
                    [_tableView beginUpdates];
                    [_tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [_tableView endUpdates];
                }
                return;
            }
            
            if ([result numberOfRanges] > 1)
            {   
                // Get actual line number to navigate to
                NSRange lineRange = [result rangeAtIndex:1];
                NSInteger line = [[filterString substringWithRange:lineRange] integerValue];
                [otherSection addObject:[NSNumber numberWithInteger:line]];
                otherSectionCount++;
                
                [_tableView beginUpdates];
                // Add section if not already present
                if (otherSectionCount == 1 && otherSectionOldCount == 0)
                    [_tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
                // Create new row for go to line
                if (otherSectionCount > otherSectionOldCount)
                    [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:otherSectionCount - 1 inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationAutomatic];
                else // reload
                    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:otherSectionCount - 1 inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [_tableView endUpdates];
            }
        }];    
    });
}

#pragma mark - Controller lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
 
    goToLineRegExp = nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO handle error
    if (!goToLineRegExp)
        goToLineRegExp = [NSRegularExpression regularExpressionWithPattern:@"^(?:line\\s+)?(\\d+)$" options:NSRegularExpressionCaseInsensitive error:nil];
    
    // Initialize sections with filtered restuls
    sections = [NSArray arrayWithObjects:[NSMutableArray array], [NSMutableArray array], [NSMutableArray array], nil];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setReplaceToolView:nil];
    [super viewDidUnload];
    
    sections = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    for (NSArray *obj in sections) 
    {
        if ([obj count] > 0)
            count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    section = [self filterSectionForSection:section];
    return [[sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    section = [self filterSectionForSection:section];
    switch (section)
    {
        case ACCodeFileFilterSymbolsSection:
            return @"Symbols";
            
        case ACCodeFileFilterSearchSection:
            return @"Find in File";
            
        case ACCodeFileFilterOtherSection:
            return @"Other";
            
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Calculate section
    NSUInteger section = [self filterSectionForSection:[indexPath indexAtPosition:0]];
    NSString *CellIdentifier = [self tableView:tableView titleForHeaderInSection:section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        switch (section)
        {
            case ACCodeFileFilterSymbolsSection:
            {
                // TODO cell for symbol
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
            }
                
            case ACCodeFileFilterSearchSection:
            {
                // TODO cell for find in file
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
            }
                
            default:
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                break;
            }
        }
    }
    
    // Configure the cell
    NSArray *sectionObjects = [sections objectAtIndex:section];
    NSInteger index = [indexPath indexAtPosition:1];
    switch (section)
    {
        case ACCodeFileFilterSymbolsSection:
        {
            break;
        }
            
        case ACCodeFileFilterSearchSection:
        {
            break;
        }
            
        case ACCodeFileFilterOtherSection:
        {
            NSNumber *line = [sectionObjects objectAtIndex:index];
            cell.textLabel.text = [NSString stringWithFormat:@"Go to line %@", line];
            break;
        }
            
        default:
            return nil;
    }
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

@end
