//
//  ACCodeFileSearchBarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileSearchBarController.h"
#import "ACSingleTabController.h"

#import "ACCodeFileController.h"
#import <ECFoundation/NSTimer+block.h>
#import <ECUIKit/ECCodeView.h>
#import <ECUIKit/ECBezelAlert.h>

static NSString * findFilterPassBlockKey = @"findFilterPass";


@interface ACCodeFileSearchBarController () {
    NSArray *_searchFilterMatches;
    NSInteger _searchFilterMatchesLocation;
    NSTimer *_filterDebounceTimer;
}

- (void)_addFindFilterCodeViewPass;
- (void)_applyFindFilter;

@end


@implementation ACCodeFileSearchBarController

#pragma mark - Properties

@synthesize targetCodeFileController;
@synthesize findTextField, replaceTextField, findResultLabel;

- (void)setTargetCodeFileController:(ACCodeFileController *)controller
{
    if (controller == targetCodeFileController)
        return;
    
    [self willChangeValueForKey:@"targetCodeFileController"];
    
    if (targetCodeFileController)
        [targetCodeFileController.codeView removePassLayerForKey:findFilterPassBlockKey];
    
    targetCodeFileController = controller;
    
    if (self.isViewLoaded && self.view.window != nil) {
        [self _addFindFilterCodeViewPass];
        [self _applyFindFilter];
    }
    
    [self didChangeValueForKey:@"targetCodeFileController"];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload 
{
    _searchFilterMatches = nil;
    
    [self setFindTextField:nil];
    [self setReplaceTextField:nil];
    [self setFindResultLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self _addFindFilterCodeViewPass];
    [self _applyFindFilter];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.targetCodeFileController.codeView removePassLayerForKey:findFilterPassBlockKey];
    if ([_searchFilterMatches count] > 0)
    {
        [self.targetCodeFileController.codeView updateAllText];
    }
    _searchFilterMatches = nil;
}

#pragma mark - Text Field Delegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (_filterDebounceTimer)
        [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 usingBlock:^(NSTimer *timer) {
        [self _applyFindFilter];
    } repeats:NO];
    
    return YES;
}

#pragma mark - Action Methods

- (IBAction)moveResultAction:(id)sender
{
    if (targetCodeFileController == nil)
        return;
    
    _searchFilterMatchesLocation += [sender tag];
    if (_searchFilterMatchesLocation < 0)
    {
        // TODO use image isntead
        [[ECBezelAlert centerBezelAlert] addAlertMessageWithText:@"Cycle to bottom" image:nil displayImmediatly:YES];
        _searchFilterMatchesLocation = [_searchFilterMatches count] - 1;
    }
    else if (_searchFilterMatchesLocation >= [_searchFilterMatches count])
    {
        // TODO use image isntead
        [[ECBezelAlert centerBezelAlert] addAlertMessageWithText:@"Cycle to top" image:nil displayImmediatly:YES];
        _searchFilterMatchesLocation = 0;
    }
    
    [targetCodeFileController.codeView flashTextInRange:[[_searchFilterMatches objectAtIndex:_searchFilterMatchesLocation] range]];
}

- (IBAction)toggleReplaceAction:(id)sender
{
    if (self.singleTabController.toolbarHeight != 88)
        [self.singleTabController setToolbarHeight:88 animated:YES];
    else
        [self.singleTabController resetToolbarHeightAnimated:YES];
}

- (IBAction)closeBarAction:(id)sender
{
    ECASSERT(self.singleTabController.toolbarViewController == self);
    [self.singleTabController setToolbarViewController:nil animated:YES];
}

- (IBAction)replaceAllAction:(id)sender {
}

#pragma mark - Private Methods

- (void)_addFindFilterCodeViewPass
{
    // TODO retrieve from theme
    UIColor *decorationColor = [UIColor colorWithRed:249.0/255.0 green:254.0/255.0 blue:192.0/255.0 alpha:1];
    UIColor *decorationSecondaryColor = [UIColor colorWithRed:224.0/255.0 green:233.0/255.0 blue:128.0/255.0 alpha:1];
    
    __block NSMutableIndexSet *searchSectionIndexes = nil;
    __block NSUInteger lastLine = NSUIntegerMax;
    [targetCodeFileController.codeView addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
        NSArray *searchSection = _searchFilterMatches;
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
    } underText:YES forKey:findFilterPassBlockKey];
}

- (void)_applyFindFilter
{
    if (!targetCodeFileController)
        return;
    
    NSString *filterString = self.findTextField.text;
    
    if (filterString.length == 0)
    {
        findResultLabel.hidden = YES;
        _searchFilterMatches = nil;
        [targetCodeFileController.codeView updateAllText];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // TODO create here? manage error
        NSRegularExpression *filterRegExp = [NSRegularExpression regularExpressionWithPattern:filterString options:0 error:NULL];
        
        // TODO get string from document instead
        NSString *text = [targetCodeFileController.codeView text];
        _searchFilterMatches = [filterRegExp matchesInString:text options:0 range:NSMakeRange(0, [text length])];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _searchFilterMatchesLocation = 0;
            [targetCodeFileController.codeView updateAllText];
            if ([_searchFilterMatches count] > 0)
            {
                [targetCodeFileController.codeView flashTextInRange:[[_searchFilterMatches objectAtIndex:0] range]];
                findResultLabel.text = [NSString stringWithFormat:@"%u matches", [_searchFilterMatches count]];
            }
            else
            {
                findResultLabel.text = @"Not found";
            }
            findResultLabel.hidden = NO;
        });
    });
}

@end
