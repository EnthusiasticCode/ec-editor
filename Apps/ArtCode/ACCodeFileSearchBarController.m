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
#import "ACFileDocument.h"
#import <ECFoundation/ECAttributedUTF8FileBuffer.h>
#import <ECFoundation/NSTimer+block.h>
#import <ECUIKit/ECCodeView.h>
#import <ECUIKit/ECBezelAlert.h>

#import "ACCodeFileSearchOptionsController.h"

static NSString * findFilterPassBlockKey = @"findFilterPass";


@interface ACCodeFileSearchBarController () {
    NSInteger _searchFilterMatchesLocation;
    NSTimer *_filterDebounceTimer;
}

@property (readwrite, copy) NSArray *searchFilterMatches;

- (void)_addFindFilterCodeViewPass;
- (void)_applyFindFilter;

@end


@implementation ACCodeFileSearchBarController

#pragma mark - Properties

@synthesize targetCodeFileController;
@synthesize findTextField, replaceTextField, findResultLabel;
@synthesize searchFilterMatches, regExpOptions, hitMustOption;

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

- (void)setRegExpOptions:(NSRegularExpressionOptions)value
{
    if (value == regExpOptions)
        return;
    [self willChangeValueForKey:@"regExpOptions"];
    regExpOptions = value;
    [self _applyFindFilter];
    [self didChangeValueForKey:@"regExpOptions"];
}

- (void)setHitMustOption:(ACCodeFileSearchHitMustOption)value
{
    if (value == hitMustOption)
        return;
    [self willChangeValueForKey:@"hitMustOption"];
    hitMustOption = value;
    [self _applyFindFilter];
    [self didChangeValueForKey:@"hitMustOption"];
}

#pragma mark - Controller Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.regExpOptions = [[defaults objectForKey:@"CodeFileFindRegExpOptions"] unsignedIntegerValue] | NSRegularExpressionAnchorsMatchLines;
        self.hitMustOption = [[defaults objectForKey:@"CodeFileFindHitMustOption"] unsignedIntegerValue];
    }
    return self;
}

- (void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithUnsignedInteger:self.regExpOptions] forKey:@"CodeFileFindRegExpOptions"];
    [defaults setObject:[NSNumber numberWithUnsignedInteger:self.hitMustOption] forKey:@"CodeFileFindHitMustOption"];
    [defaults synchronize];
}

#pragma mark - View Lifecycle

- (void)viewDidUnload 
{
    [self setSearchFilterMatches:nil];
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
    if ([searchFilterMatches count] > 0)
    {
        [self.targetCodeFileController.codeView updateAllText];
    }
    self.searchFilterMatches = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[ACCodeFileSearchOptionsController class]])
    {
        [(ACCodeFileSearchOptionsController *)segue.destinationViewController setParentSearchBarController:self];
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]])
            [(ACCodeFileSearchOptionsController *)segue.destinationViewController setParentPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
    }
    else
    {
        [super prepareForSegue:segue sender:sender];
    }
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

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self textField:textField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:nil];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
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
        _searchFilterMatchesLocation = [searchFilterMatches count] - 1;
    }
    else if (_searchFilterMatchesLocation >= [searchFilterMatches count])
    {
        // TODO use image isntead
        [[ECBezelAlert centerBezelAlert] addAlertMessageWithText:@"Cycle to top" image:nil displayImmediatly:YES];
        _searchFilterMatchesLocation = 0;
    }
    
    [targetCodeFileController.codeView flashTextInRange:[[searchFilterMatches objectAtIndex:_searchFilterMatchesLocation] range]];
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

- (IBAction)replaceSingleAction:(id)sender {
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
        NSArray *searchSection = searchFilterMatches;
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
        self.searchFilterMatches = nil;
        [targetCodeFileController.codeView updateAllText];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // TODO create here? manage error
        #warning TODO wire in 'hit must' option
        NSRegularExpression *filterRegExp = [NSRegularExpression regularExpressionWithPattern:filterString options:self.regExpOptions error:NULL];
        NSArray *matches = [self.targetCodeFileController.document.fileBuffer matchesOfRegexp:filterRegExp options:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchFilterMatches = matches;
            _searchFilterMatchesLocation = 0;
            [targetCodeFileController.codeView updateAllText];
            if ([searchFilterMatches count] > 0)
            {
                [targetCodeFileController.codeView flashTextInRange:[[searchFilterMatches objectAtIndex:0] range]];
                findResultLabel.text = [NSString stringWithFormat:@"%u matches", [searchFilterMatches count]];
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

@implementation ACCodeFileSearchBarView
@end

@implementation ACCodeFileSearchTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    bounds = [super textRectForBounds:bounds];
    bounds.origin.x += 30;
    bounds.size.width -= 30;
    return bounds;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end
