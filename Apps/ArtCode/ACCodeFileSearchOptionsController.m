//
//  ACCodeFileSearchOptionsController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileSearchOptionsController.h"
#import "ACCodeFileSearchBarController.h"
#import "ACCodeFileController.h"
#import <ECUIKit/ECCodeView.h>
#import <ECUIKit/ECTextRenderer.h>

#define OPTIONS_SECTION 0
#define PREVIEW_SECTION 1
#define PREVIEW_SECTION_IMAGE_HEIGHT 55
#define PREVIEW_SECTION_IMAGE_WIDTH 280
static void const * parentSearchBarControllerContext;


@implementation ACCodeFileSearchOptionsController {
    NSArray *_searchFilterMatches;
}

#pragma mark - Properties

@synthesize parentSearchBarController, parentPopoverController;

- (void)setParentSearchBarController:(ACCodeFileSearchBarController *)controller
{
    if (controller == parentSearchBarController)
        return;
    
    [self willChangeValueForKey:@"parentSearchBarController"];
    
    [parentSearchBarController removeObserver:self forKeyPath:@"searchFilterMatches" context:&parentSearchBarControllerContext];
    parentSearchBarController = controller;
    [parentSearchBarController addObserver:self forKeyPath:@"searchFilterMatches" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&parentSearchBarControllerContext];
    
    [self didChangeValueForKey:@"parentSearchBarController"];
}

#pragma mark - Controller Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    _searchFilterMatches = [self.parentSearchBarController.searchFilterMatches copy];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _searchFilterMatches = nil;
}

- (void)dealloc
{
    self.parentSearchBarController = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &parentSearchBarControllerContext)
    {
        // filter mathces changed
        if (self.isViewLoaded && self.view.window != nil)
        {
            _searchFilterMatches = [self.parentSearchBarController.searchFilterMatches copy];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PREVIEW_SECTION] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case OPTIONS_SECTION:
            return 3;
            
        case PREVIEW_SECTION:
            return MAX([_searchFilterMatches count], 1);
            
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case OPTIONS_SECTION:
            return @"Find Options";
            
        case PREVIEW_SECTION:
            return @"Matches Preview";
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSUInteger index = [indexPath indexAtPosition:1];
    if ([indexPath indexAtPosition:0] == OPTIONS_SECTION)
    {  
        switch (index) {
            case 0:
                cell = [tableView dequeueReusableCellWithIdentifier:@"RegExpOptionCell"];
                break;
                
            case 1:
                cell = [tableView dequeueReusableCellWithIdentifier:@"MatchCaseOptionCell"];
                break;
                
            case 2:
                cell = [tableView dequeueReusableCellWithIdentifier:@"HitMustOptionCell"];
                break;
                
            default:
                ECASSERT(NO && "There shoud be a cell");
                break;
        }
        
        ECASSERT(cell != nil && "Cell not defined in storyboard");
    }
    else if ([_searchFilterMatches count] == 0)
    {
        static NSString *NoMatchesCellIdentifier = @"NoMatchesCell";
        
        if ((cell = [tableView dequeueReusableCellWithIdentifier:NoMatchesCellIdentifier]) == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoMatchesCellIdentifier];
        }
        
        cell.textLabel.text = @"No matches";
    }
    else
    {
        static NSString *PreviewCellIdentifier = @"PreviewCell";

        if ((cell = [tableView dequeueReusableCellWithIdentifier:PreviewCellIdentifier]) == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PreviewCellIdentifier];
        }
        
        ECASSERT([_searchFilterMatches count] > index);
        ECASSERT([[_searchFilterMatches objectAtIndex:index] respondsToSelector:@selector(rangeAtIndex:)]);
        
        // Retrieve the match bounding box in the code view rendered text.
        CGRect matchRect = [self.parentSearchBarController.targetCodeFileController.codeView.renderer rectsForStringRange:[[_searchFilterMatches objectAtIndex:index] rangeAtIndex:0] limitToFirstLine:NO].bounds;
        CGRect clipRect = CGRectMake(0, 0, PREVIEW_SECTION_IMAGE_WIDTH, PREVIEW_SECTION_IMAGE_HEIGHT);
        clipRect.origin.x = CGRectGetMidX(matchRect) - PREVIEW_SECTION_IMAGE_WIDTH / 2;
        clipRect.origin.y = CGRectGetMidY(matchRect) - PREVIEW_SECTION_IMAGE_HEIGHT / 2;
        
        // Generate preview image mask
        // Draw gradient
        static CGImageRef mask = NULL;
        if (!mask)
        {
            // Create gradiend
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            NSArray *gradientColors = [NSArray arrayWithObjects:
                                       (__bridge id)[UIColor clearColor].CGColor,
                                       (__bridge id)[UIColor whiteColor].CGColor,
                                       (__bridge id)[UIColor clearColor].CGColor,nil];
            CGFloat gradientLocations[] = {0, 0.5, 1};
            CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
            
            // Generate mask image
            UIGraphicsBeginImageContext(clipRect.size);
            CGContextRef maskContext = UIGraphicsGetCurrentContext();
            CGContextDrawLinearGradient(maskContext, gradient, CGPointMake(PREVIEW_SECTION_IMAGE_WIDTH / 2, 0), CGPointMake(PREVIEW_SECTION_IMAGE_WIDTH / 2, clipRect.size.height), 0);
            mask = CGImageRetain(UIGraphicsGetImageFromCurrentImageContext().CGImage);
            UIGraphicsEndImageContext();
            
            // Clean up
            CGColorSpaceRelease(colorSpace);
            CGGradientRelease(gradient);
        }
        
        // Generate preview image
        UIGraphicsBeginImageContext(clipRect.size);
        {
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextClipToMask(context, (CGRect){CGPointZero, clipRect.size}, mask);
            
            if (clipRect.origin.x > 0)
                CGContextTranslateCTM(context, -clipRect.origin.x, 0);
            
            // Draw text
            [parentSearchBarController.targetCodeFileController.codeView.renderer drawTextWithinRect:clipRect inContext:context];
        }
        UIImageView *previewImageView = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
        UIGraphicsEndImageContext();
    
        // Apply preview image to cell
        [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [cell.contentView addSubview:previewImageView];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath indexAtPosition:0] == PREVIEW_SECTION)
        return PREVIEW_SECTION_IMAGE_HEIGHT;
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:1];
    if ([indexPath indexAtPosition:0] == OPTIONS_SECTION)
    {
        // TODO manage options
    }
    else
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.parentPopoverController dismissPopoverAnimated:YES];
        [self.parentSearchBarController.targetCodeFileController.codeView flashTextInRange:[[_searchFilterMatches objectAtIndex:index] range]];
    }
}

@end
