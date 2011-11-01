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
static void const * searchBarControllerContext;


@implementation ACCodeFileSearchOptionsController

#pragma mark - Properties

@synthesize searchBarController;

- (void)setSearchBarController:(ACCodeFileSearchBarController *)controller
{
    if (controller == searchBarController)
        return;
    
    [self willChangeValueForKey:@"searchBarController"];
    
    [searchBarController removeObserver:self forKeyPath:@"searchFilterMatches" context:&searchBarControllerContext];
    searchBarController = controller;
    [searchBarController addObserver:self forKeyPath:@"searchFilterMatches" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&searchBarControllerContext];
    
    [self didChangeValueForKey:@"searchBarController"];
}

#pragma mark - Controller Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &searchBarControllerContext)
    {
        // filter mathces changed
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:PREVIEW_SECTION] withRowAnimation:UITableViewRowAnimationAutomatic];
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
            return 1;
            
        case PREVIEW_SECTION:
            return (searchBarController && searchBarController.targetCodeFileController) ? [searchBarController.searchFilterMatches count] : 0;
            
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
        static NSString *OptionsCellIdentifier = @"OptionsCell";
        
        if ((cell = [tableView dequeueReusableCellWithIdentifier:OptionsCellIdentifier]) == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:OptionsCellIdentifier];
        }
        
        cell.textLabel.text = @"Option";
    }
    else
    {
        static NSString *PreviewCellIdentifier = @"PreviewCell";

        if ((cell = [tableView dequeueReusableCellWithIdentifier:PreviewCellIdentifier]) == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PreviewCellIdentifier];
        }
        
        ECASSERT([searchBarController.searchFilterMatches count] > index);
        ECASSERT([[searchBarController.searchFilterMatches objectAtIndex:index] respondsToSelector:@selector(rangeAtIndex:)]);
        
        // Retrieve the match bounding box in the code view rendered text.
        CGRect matchRect = [searchBarController.targetCodeFileController.codeView.renderer rectsForStringRange:[[searchBarController.searchFilterMatches objectAtIndex:index] rangeAtIndex:0] limitToFirstLine:NO].bounds;
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
            [searchBarController.targetCodeFileController.codeView.renderer drawTextWithinRect:clipRect inContext:context];
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
