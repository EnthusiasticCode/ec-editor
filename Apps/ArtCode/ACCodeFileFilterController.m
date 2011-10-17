//
//  ACCodeFileFilterController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileFilterController.h"

#import "AppStyle.h"

#import <ECUIKit/ECCodeView.h>
#import <ECUIKit/ECTextRenderer.h>
#import <ECCodeIndexing/ECCodeIndex.h>

#import "ACToolFiltersView.h"
#import "ACToolTextField.h"

enum ACCodeFileFilterSections {
    /// Identifies the symbol section of the filter table view.
    ACCodeFileFilterSymbolsSection,
    
    /// Identifies the search in file section of the filter table view.
    ACCodeFileFilterSearchSection,
    
    /// Identifies the additional section containing go-to-line and other filter results.
    ACCodeFileFilterOtherSection
    
    // TODO add recent searches (global)
};

static BOOL codeFileFilterUseRegularExpression = YES;

@implementation ACCodeFileFilterController {
    NSRegularExpression *goToLineRegExp;
    
    /// Array with sections arranges as in ACCodeFileFilterSections.
    /// Every entry of the sections array is another array that contains fitlered
    /// restults for the section.
    NSArray *sections;
    
    /// Filter regular expression
    NSRegularExpression *filterRegExp;
    
    /// Controls in search tools
    UIButton *searchToolsRegExpButton;
    UITextField *searchToolsReplaceTextField;
}

#pragma mark - Properties

@synthesize targetCodeView, filterString;
@synthesize startSearchingBlock, endSearchingBlock, didSelectFilterResultBlock;

- (void)setTargetCodeView:(ECCodeView *)codeView
{    
    static NSString * filteringBlockKey = @"filteringHighlight";
    
    if (targetCodeView == codeView)
        return;
    
    if (targetCodeView)
        [targetCodeView removePassLayerForKey:filteringBlockKey];
    
    targetCodeView = codeView;
    
    UIColor *decorationColor = [UIColor colorWithRed:249.0/255.0 green:254.0/255.0 blue:192.0/255.0 alpha:1];
    UIColor *decorationSecondaryColor = [UIColor colorWithRed:224.0/255.0 green:233.0/255.0 blue:128.0/255.0 alpha:1];
    
    __block NSMutableIndexSet *searchSectionIndexes = nil;
    __block NSUInteger lastLine = NSUIntegerMax;
    [targetCodeView addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
        NSMutableArray *searchSection = [sections objectAtIndex:ACCodeFileFilterSearchSection];
        NSUInteger searchSectionCount = [searchSection count];
        if (searchSectionCount == 0)
            return;
        
        // Get indexes to search into
        if (searchSectionIndexes == nil || lineNumber < lastLine)
            searchSectionIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [searchSection count])];
        
        NSUInteger endStringRange = NSMaxRange(stringRange);
        [searchSection enumerateObjectsAtIndexes:searchSectionIndexes options:0 usingBlock:^(NSTextCheckingResult *result, NSUInteger idx, BOOL *stop) {
            // End loop if range after current string range
            NSRange range = [result rangeAtIndex:0];
            if (range.location >= endStringRange)
            {
                *stop = YES;
                return;
            }
            
            // Skip indexes behind current string range
            if (NSMaxRange(range) < stringRange.location)
            {
                [searchSectionIndexes removeIndex:idx];
                return;
            }
            
            // Adjust range to fit in string
            if (range.location < stringRange.location)
                range = NSMakeRange(stringRange.location, range.length - (stringRange.location - range.location));
            else
                range.location -= stringRange.location;
            
            // Draw decoration
            CGRect rect = [line boundsForSubstringInRange:range];
            CGContextSetFillColorWithColor(context, decorationColor.CGColor);
            CGContextFillRect(context, rect);
            
            rect.size.height = 2;
            CGContextSetFillColorWithColor(context, decorationSecondaryColor.CGColor);
            CGContextFillRect(context, rect);            
        }];
    } underText:YES forKey:filteringBlockKey];
    
    // Apply filtering
    [self setFilterString:filterString];
}

- (void)setFilterString:(NSString *)string
{
    filterString = string;
    
    if (startSearchingBlock)
        startSearchingBlock(self);
    
    // TODO divide filtering in various methods
    dispatch_async(dispatch_get_main_queue(), ^{
        // Prepare symbol section
//        [self populateSymbolsArrayWithFilter:filterString];
        
        if (filterString)
        {
            // TODO useRegularExpression to see if create a regexp or use normal search 
            // TODO create here? manage error
           filterRegExp = [NSRegularExpression regularExpressionWithPattern:filterString options:0 error:NULL];
            
            // Prepare text search section
            NSMutableArray *searchSection = [sections objectAtIndex:ACCodeFileFilterSearchSection];
            [searchSection removeAllObjects];
            
            /// Search in text
            if (targetCodeView)
            {
                NSString *text = targetCodeView.text;
                NSArray *matches = [filterRegExp matchesInString:text options:0 range:NSMakeRange(0, [text length])];
                // TODO save only rangeAtPosition:0?
                [searchSection addObjectsFromArray:matches];
            }
            
            // Prepare other section
            NSMutableArray *otherSection = [sections objectAtIndex:ACCodeFileFilterOtherSection];
            [otherSection removeAllObjects];
            
            // Search for go to line
            [goToLineRegExp enumerateMatchesInString:filterString options:0 range:NSMakeRange(0, [filterString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                if ([result numberOfRanges] > 1)
                {   
                    // Get actual line number to navigate to
                    NSRange lineRange = [result rangeAtIndex:1];
                    NSInteger line = [[filterString substringWithRange:lineRange] integerValue];
                    [otherSection addObject:[NSNumber numberWithInteger:line]];
                }
            }];
        }
        
        [self.tableView reloadData];
        [targetCodeView setNeedsDisplay];
        
        if (endSearchingBlock)
            endSearchingBlock(self);
    });
}

- (BOOL)isUsingRegularExpression
{
    return codeFileFilterUseRegularExpression;
}

- (void)setUseRegularExpression:(BOOL)value
{
    if (codeFileFilterUseRegularExpression == value)
        return;
    
    codeFileFilterUseRegularExpression = value;
    
    searchToolsRegExpButton.selected = value;
    
    // TODO reapply filter
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

- (void)populateSymbolsArrayWithFilter:(NSString *)filter
{
    UNIMPLEMENTED_VOID();
}

#pragma mark - Search tools actions

- (void)searchToolsRegExpAction:(id)sender
{
    [self setUseRegularExpression:!codeFileFilterUseRegularExpression];
}

/// Will replace all the occurence of the current filter string with the content
/// of the replace text field.
- (void)searchToolsReplaceAllAction:(id)sender
{
    if (codeFileFilterUseRegularExpression)
    {
        ECASSERT(filterRegExp != nil);
        // The new ECCodeView does not have a method to retrieve the whole text
        // Running regexes on the file should probably be ACFileDocument's responsability anyway
        UNIMPLEMENTED_VOID();
//        NSMutableString *newContent = [targetCodeView.text mutableCopy];
//        [filterRegExp replaceMatchesInString:newContent options:0 range:NSMakeRange(0, [newContent length]) withTemplate:searchToolsReplaceTextField.text];
//        targetCodeView.text = newContent;
    }
}

#pragma mark - Controller lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
 
    goToLineRegExp = nil;
    sections = nil;
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
    
    self.tableView.backgroundColor = [UIColor styleBackgroundColor];
    self.tableView.separatorColor = [UIColor styleForegroundColor];
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewDidUnload
{
    sections = nil;
    [super viewDidUnload];
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
    NSUInteger count = [[sections objectAtIndex:section] count];
    if (section == ACCodeFileFilterSearchSection)
        count += count ? 1 : 0;
    return count;
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
    NSInteger index = [indexPath indexAtPosition:1];
    NSString *CellIdentifier = nil;
    if (section == ACCodeFileFilterSearchSection && index == 0)
        CellIdentifier = @"Search Options";
    else
        CellIdentifier = [self tableView:tableView titleForHeaderInSection:section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if (section == ACCodeFileFilterSearchSection && index == 0)
        {
            // Create search options cell
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            ACToolFiltersView *toolsView = [[ACToolFiltersView alloc] initWithFrame:cell.bounds];
            toolsView.backgroundColor = [UIColor styleForegroundColor];
            toolsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            searchToolsRegExpButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 44)];
            searchToolsRegExpButton.titleLabel.font = [UIFont styleFontWithSize:14];
            [searchToolsRegExpButton setTitle:@"RegExp" forState:UIControlStateNormal];
            [toolsView addSubview:searchToolsRegExpButton];
            [searchToolsRegExpButton addTarget:self action:@selector(searchToolsRegExpAction:) forControlEvents:UIControlEventTouchUpInside];
            searchToolsRegExpButton.selected = codeFileFilterUseRegularExpression;
            
            CGRect replaceFieldFrame = CGRectMake(75, 0, cell.bounds.size.width - (75 + 40 + 40), 44);
            ACToolTextField *replaceField = [[ACToolTextField alloc] initWithFrame:replaceFieldFrame];
            replaceField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            replaceField.placeholder = @"Replace";
            replaceField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            [toolsView addSubview:replaceField];
            searchToolsReplaceTextField = replaceField;
            
            UIButton *allButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(replaceFieldFrame), 0, 40, 44)];
            allButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            allButton.titleLabel.font = [UIFont styleFontWithSize:14];
            [allButton setTitle:@"All" forState:UIControlStateNormal];
            [toolsView addSubview:allButton];
            [allButton addTarget:self action:@selector(searchToolsReplaceAllAction:) forControlEvents:UIControlEventTouchUpInside];
            
            UIButton *modalButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(replaceFieldFrame) + 40, 0, 40, 44)];
            modalButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            modalButton.titleLabel.font = [UIFont styleFontWithSize:14];
            [modalButton setTitle:@"F" forState:UIControlStateNormal];
            [toolsView addSubview:modalButton];
            
            [cell.contentView addSubview:toolsView];
        }
        else if (section == ACCodeFileFilterSearchSection)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            // Solid color selection highlight
            UIView *selectedBackgroundView = [UIView new];
            selectedBackgroundView.backgroundColor = [UIColor styleHighlightColor];
            cell.selectedBackgroundView = selectedBackgroundView;
        }
    }
    
    // Configure the cell
    NSArray *sectionObjects = [sections objectAtIndex:section];
    switch (section)
    {
        case ACCodeFileFilterSymbolsSection:
        {
//            ECCodeCursor *cursor = [sectionObjects objectAtIndex:index];
//            cell.textLabel.text = cursor.spelling;
            break;
        }
            
        case ACCodeFileFilterSearchSection:
        {
            // The first row will be a special cell with replace controls
            if (index == 0)
            {
                break;
            }
            index--;
            
            NSTextCheckingResult *result = [sectionObjects objectAtIndex:index];
            CGRect resultRect = [targetCodeView.renderer rectsForStringRange:[result rangeAtIndex:0] limitToFirstLine:YES].bounds;
            CGRect clipRect = cell.bounds;
            clipRect.origin.x = CGRectGetMidX(resultRect) - clipRect.size.width / 2;
            clipRect.origin.y = CGRectGetMidY(resultRect) - clipRect.size.height / 2;
            
            // TODO do in background?
            UIGraphicsBeginImageContext(clipRect.size);
            {
                CGContextRef context = UIGraphicsGetCurrentContext();
                
                if (clipRect.origin.x > 0)
                    CGContextTranslateCTM(context, -clipRect.origin.x, 0);
                
                // Draw text
                CGContextSaveGState(context);
                [targetCodeView.renderer drawTextWithinRect:clipRect inContext:context];
                CGContextRestoreGState(context);
                
                // Draw gradient
                static CGGradientRef gradient = NULL;
                if (!gradient)
                {
                    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                    NSArray *gradientColors = [NSArray arrayWithObjects:
                                               (__bridge id)tableView.backgroundColor.CGColor,
                                               (__bridge id)[tableView.backgroundColor colorWithAlphaComponent:0].CGColor,
                                               (__bridge id)tableView.backgroundColor.CGColor,nil];
                    CGFloat gradientLocations[] = {0, 0.5, 1};
                    gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
                    CGColorSpaceRelease(colorSpace);
                }
                
                CGContextDrawLinearGradient(context, gradient, CGPointMake(clipRect.size.width / 2, 0), CGPointMake(clipRect.size.width / 2, clipRect.size.height), 0);
            }
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [cell.contentView addSubview:[[UIImageView alloc] initWithImage:image]];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *label = [UILabel new];
    label.font = [UIFont styleFontWithSize:14];
    label.backgroundColor = [UIColor styleForegroundColor];
    label.textColor = [UIColor styleBackgroundColor];
    
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    
    return label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger section = [self filterSectionForSection:[indexPath indexAtPosition:0]];
    NSInteger index = [indexPath indexAtPosition:1];
    if (section == ACCodeFileFilterSearchSection)
    {
        if (index == 0)
            return;
        index--;
    }
    NSObject *obj = [[sections objectAtIndex:section] objectAtIndex:index];
    
    // Produce range of found element in target code view text
    NSRange range = NSMakeRange(0, 0);
    switch (section) {
        case ACCodeFileFilterSymbolsSection:
            break;
            
        case ACCodeFileFilterSearchSection:
            range = [(NSTextCheckingResult *)obj rangeAtIndex:0];
            
        default:
            if ([obj isKindOfClass:[NSNumber class]])
            {
                NSInteger lineTerminatorLength = [@"\n" length];
                __block NSInteger lineIndex = [(NSNumber *)obj integerValue] - 1;
                __block NSRange lineStringRange = NSMakeRange(0, 0);
                [targetCodeView.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                    if (lineIndex-- == 0)
                    {
                        lineStringRange.length = [line length];
                        *stop = YES;
                    }
                    else
                    {
                        lineStringRange.location += [line length] + lineTerminatorLength;
                    }
                }];
                range = lineStringRange;
            }
            break;
    }
    
    if (didSelectFilterResultBlock)
        didSelectFilterResultBlock(range);
}

@end
