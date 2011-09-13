//
//  ACCodeFileFilterController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileFilterController.h"

#import "AppStyle.h"
#import "ACCodeIndexerDataSource.h"

#import "ECTextRenderer.h"

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

#pragma mark - Properties

@synthesize targetCodeView, filterString;
@synthesize startSearchingBlock, endSearchingBlock, didSelectFilterResultBlock;
@synthesize filterHighlightTextStyle;

- (void)setTargetCodeView:(ECCodeView *)codeView
{
    ECASSERT([codeView.datasource isKindOfClass:[ACCodeIndexerDataSource class]]);
    
    static NSString * filteringBlockKey = @"filteringHighlight";
    
    if (targetCodeView == codeView)
        return;
    
    if (targetCodeView)
        [(ACCodeIndexerDataSource *)targetCodeView.datasource removeStylingBlockForKey:filteringBlockKey];
    
    targetCodeView = codeView;
    
    [(ACCodeIndexerDataSource *)targetCodeView.datasource addStylingBlock:^(NSMutableAttributedString *string, NSRange stringRange) {
        if (filterHighlightTextStyle == nil)
            return;
        
        NSMutableArray *searchSection = [sections objectAtIndex:ACCodeFileFilterSearchSection];
        if ([searchSection count] == 0)
            return;
        
        NSRange range;
        NSUInteger endStringRange = NSMaxRange(stringRange);
        for (NSTextCheckingResult *result in searchSection)
        {
            range = [result rangeAtIndex:0];
            if (range.location >= endStringRange)
                break;
            
            if (NSMaxRange(range) < stringRange.location)
                continue;
            
            if (range.location < stringRange.location)
                range = NSMakeRange(stringRange.location, range.length - (stringRange.location - range.location));
            else
                range.location -= stringRange.location;
            
            [string addAttributes:filterHighlightTextStyle.CTAttributes range:range];
        }
    } forKey:filteringBlockKey];
}

- (void)setFilterString:(NSString *)string
{
    filterString = string;
    
    if (startSearchingBlock)
        startSearchingBlock(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO create here? keep? manage error
        NSRegularExpression *filterExp = [NSRegularExpression regularExpressionWithPattern:filterString options:0 error:NULL];
        
        // Prepare text search section
        NSMutableArray *searchSection = [sections objectAtIndex:ACCodeFileFilterSearchSection];
        [searchSection removeAllObjects];
        
        /// Search in text
        if (targetCodeView)
        {
            NSString *text = targetCodeView.text;
            NSArray *matches = [filterExp matchesInString:text options:0 range:NSMakeRange(0, [text length])];
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
        
        [self.tableView reloadData];
        [targetCodeView updateAllText];
        
        if (endSearchingBlock)
            endSearchingBlock(self);
    });
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
        
        // Solid color selection highlight
        UIView *selectedBackgroundView = [UIView new];
        selectedBackgroundView.backgroundColor = [UIColor styleHighlightColor];
        cell.selectedBackgroundView = selectedBackgroundView;
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
                [targetCodeView.renderer drawTextWithinRect:clipRect inContext:context withLineBlock:nil];
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
    label.font = [UIFont styleFontWithSize:16];
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
    NSObject *obj = [[sections objectAtIndex:section] objectAtIndex:index];
    
    // Produce range of found element in target code view text
    NSRange range;
    switch (section) {
        case ACCodeFileFilterSymbolsSection:
            range = NSMakeRange(0, 0);
            break;
            
        case ACCodeFileFilterSearchSection:
            range = [(NSTextCheckingResult *)obj rangeAtIndex:0];
            
        default:
            if ([obj isKindOfClass:[NSNumber class]])
            {
                NSInteger lineTerminatorLength = [@"\n" length];
                __block NSInteger lineIndex = [(NSNumber *)obj integerValue];
                __block NSInteger location = 0;
                [targetCodeView.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                    if (lineIndex-- == 0)
                        *stop = YES;
                    else
                        location += [line length] + lineTerminatorLength;
                }];
                range = NSMakeRange(location, 0);
            }
            break;
    }
    
    if (didSelectFilterResultBlock)
        didSelectFilterResultBlock(range);
}

@end
