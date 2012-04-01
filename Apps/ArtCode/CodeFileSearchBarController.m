//
//  CodeFileSearchBarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileSearchBarController.h"
#import "SingleTabController.h"

#import "CodeFileController.h"
#import "CodeBuffer.h"
#import "ACProjectFile.h"
#import "NSTimer+BlockTimer.h"
#import "CodeView.h"
#import "TextRange.h"
#import "BezelAlert.h"

#import "CodeFileSearchOptionsController.h"

static NSString * findFilterPassBlockKey = @"findFilterPass";


@interface CodeFileSearchBarController () {
    NSInteger _searchFilterMatchesLocation;
    NSTimer *_filterDebounceTimer;
    // Indicate if the controller is in a replacement procedure. This will avoid the file buffer changes to update the filter.
    BOOL _isReplacing;
}

@property (nonatomic, readwrite, copy) NSArray *searchFilterMatches;

- (void)_addFindFilterCodeViewPass;
- (void)_applyFindFilterAndFlash:(BOOL)shouldFlash;

@end


@implementation CodeFileSearchBarController

#pragma mark - Properties

@synthesize targetCodeFileController;
@synthesize findTextField, replaceTextField, findResultLabel;
@synthesize searchFilterMatches, regExpOptions, hitMustOption;

- (void)setTargetCodeFileController:(CodeFileController *)controller
{
    if (controller == targetCodeFileController)
        return;
    
    if (targetCodeFileController)
        [targetCodeFileController.codeView removePassLayerForKey:findFilterPassBlockKey];
    
    targetCodeFileController = controller;
    
    if (self.isViewLoaded && self.view.window != nil) {
        [self _addFindFilterCodeViewPass];
        [self _applyFindFilterAndFlash:YES];
    }
}

- (void)setRegExpOptions:(NSRegularExpressionOptions)value
{
    if (value == regExpOptions)
        return;
    regExpOptions = value;
    [self _applyFindFilterAndFlash:YES];
}

- (void)setHitMustOption:(CodeFileSearchHitMustOption)value
{
    if (value == hitMustOption)
        return;
    hitMustOption = value;
    [self _applyFindFilterAndFlash:YES];
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
    [super viewDidAppear:animated];
    
    [self _addFindFilterCodeViewPass];
    [self _applyFindFilterAndFlash:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithUnsignedInteger:self.regExpOptions] forKey:@"CodeFileFindRegExpOptions"];
    [defaults setObject:[NSNumber numberWithUnsignedInteger:self.hitMustOption] forKey:@"CodeFileFindHitMustOption"];
    [defaults synchronize];
    
    [self.targetCodeFileController.codeView removePassLayerForKey:findFilterPassBlockKey];
    
    if ([searchFilterMatches count] > 0)
    {
        [self.targetCodeFileController.codeView updateAllText];
    }
    self.searchFilterMatches = nil;
    
    [super viewDidDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[CodeFileSearchOptionsController class]])
    {
        [(CodeFileSearchOptionsController *)segue.destinationViewController setParentSearchBarController:self];
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]])
            [(CodeFileSearchOptionsController *)segue.destinationViewController setParentPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
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
        [self _applyFindFilterAndFlash:YES];
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
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:nil image:[UIImage imageNamed:@"bezelAlert_cycleDownIcon"] displayImmediatly:YES];
        _searchFilterMatchesLocation = [searchFilterMatches count] - 1;
    }
    else if (_searchFilterMatchesLocation >= (NSInteger)[searchFilterMatches count])
    {
        // TODO use image isntead
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:nil image:[UIImage imageNamed:@"bezelAlert_cycleUpIcon"] displayImmediatly:YES];
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
    ASSERT(self.singleTabController.toolbarViewController == self);
    [self.singleTabController setToolbarViewController:nil animated:YES];
}

- (IBAction)replaceSingleAction:(id)sender
{
    if ([self.searchFilterMatches count] == 0)
    {
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
        return;
    }
    
    _isReplacing = YES;
    
    // Get the string to replace
    NSTextCheckingResult *match = [self.searchFilterMatches objectAtIndex:_searchFilterMatchesLocation];
    NSString *replacementString = self.replaceTextField.text;
    if (self.regExpOptions & NSRegularExpressionIgnoreMetacharacters)
        replacementString = [NSRegularExpression escapedTemplateForString:replacementString];
    replacementString = [self.targetCodeFileController.projectFile.codeBuffer replacementStringForResult:match offset:0 template:replacementString];
    
    [self.targetCodeFileController.codeView.undoManager beginUndoGrouping];
    [self.targetCodeFileController.codeView.undoManager setActionName:@"Replace"];
    [self.targetCodeFileController.codeView replaceRange:[TextRange textRangeWithRange:match.range] withText:replacementString];
    [self.targetCodeFileController.codeView.undoManager endUndoGrouping];
    
    _isReplacing = NO;
    [self.targetCodeFileController.codeView flashTextInRange:NSMakeRange(match.range.location, [replacementString length])];
    [self _applyFindFilterAndFlash:NO];
}

- (IBAction)replaceAllAction:(id)sender
{
    if ([self.searchFilterMatches count] == 0)
    {
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
        return;
    }
    
    NSArray *matches = self.searchFilterMatches;
    _isReplacing = YES;
    
    [self.targetCodeFileController.codeView.undoManager beginUndoGrouping];
    [self.targetCodeFileController.codeView.undoManager setActionName:@"Replace All"];
    
    NSString *replacementString = self.replaceTextField.text;
    if (self.regExpOptions & NSRegularExpressionIgnoreMetacharacters)
        replacementString = [NSRegularExpression escapedTemplateForString:replacementString];
        
    NSRange replacementRange;
    NSString *originalString = nil;
    NSInteger offset = 0;
    for (NSTextCheckingResult *match in matches)
    {
        originalString = [self.targetCodeFileController.projectFile.codeBuffer stringInRange:NSMakeRange(match.range.location + offset, match.range.length)];
        replacementRange = [self.targetCodeFileController.projectFile.codeBuffer replaceMatch:match withTemplate:replacementString offset:offset];
        [[self.targetCodeFileController.codeView.undoManager prepareWithInvocationTarget:self.targetCodeFileController.projectFile.codeBuffer] replaceCharactersInRange:replacementRange withString:originalString];
        offset += replacementRange.length - [originalString length];
    }
    
    [self.targetCodeFileController.codeView.undoManager endUndoGrouping];
    
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Replaced %u occurrences", [matches count]] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
    
    _isReplacing = NO;
    [self _applyFindFilterAndFlash:NO];
}

#pragma mark - Private Methods

- (void)_addFindFilterCodeViewPass
{
    // TODO retrieve from theme
    UIColor *decorationColor = [UIColor colorWithRed:249.0/255.0 green:254.0/255.0 blue:192.0/255.0 alpha:1];
    UIColor *decorationSecondaryColor = [UIColor colorWithRed:224.0/255.0 green:233.0/255.0 blue:128.0/255.0 alpha:1];
    
    __block NSMutableIndexSet *searchSectionIndexes = nil;
    __block NSUInteger lastLine = NSUIntegerMax;
    [targetCodeFileController.codeView addPassLayerBlock:^(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
        NSArray *searchSection = self.searchFilterMatches;
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

- (void)_applyFindFilterAndFlash:(BOOL)shouldFlash
{
    if (!targetCodeFileController)
        return;
    
    __block NSString *filterString = self.findTextField.text;
    
    if (filterString.length == 0)
    {
        findResultLabel.hidden = YES;
        self.searchFilterMatches = nil;
        [targetCodeFileController.codeView updateAllText];
        return;
    }
    
    self.loading = YES;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSRegularExpressionOptions options = self.regExpOptions;
        
        if (self.hitMustOption != CodeFileSearchHitMustContain)
        {
            NSMutableString *modifiedFilterString = nil;
            if (options & NSRegularExpressionIgnoreMetacharacters)
            {
                options &= ~NSRegularExpressionIgnoreMetacharacters;
                modifiedFilterString = [[NSRegularExpression escapedPatternForString:filterString] mutableCopy];
            }
            else
            {
                modifiedFilterString = [filterString mutableCopy];
            }
            if (self.hitMustOption == CodeFileSearchHitMustStartWith || self.hitMustOption == CodeFileSearchHitMustMatch)
                [modifiedFilterString insertString:@"\\b" atIndex:0];
            if (self.hitMustOption == CodeFileSearchHitMustEndWith || self.hitMustOption == CodeFileSearchHitMustMatch)
                [modifiedFilterString appendString:@"\\b"];
            filterString = modifiedFilterString;
        }
            
        // TODO create here? manage error
        NSRegularExpression *filterRegExp = [NSRegularExpression regularExpressionWithPattern:filterString options:options error:NULL];
        NSArray *matches = nil;
        if (filterRegExp != nil)
            matches = [self.targetCodeFileController.projectFile.codeBuffer matchesOfRegexp:filterRegExp options:0];
        
//        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchFilterMatches = matches;
            [targetCodeFileController.codeView updateAllText];
            // Set first match to flash
            _searchFilterMatchesLocation = 0;
            NSRange visibleRange = self.targetCodeFileController.codeView.visibleTextRange;
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *check, NSUInteger idx, BOOL *stop) {
                if ([check rangeAtIndex:0].location >= visibleRange.location)
                {
                    _searchFilterMatchesLocation = idx;
                    *stop = YES;
                }
            }];
            // Change report label
            if (filterRegExp == nil)
            {
                findResultLabel.text = @"Invalid RegExp";
            } 
            else if ([searchFilterMatches count] > 0)
            {
                if (shouldFlash)
                    [targetCodeFileController.codeView flashTextInRange:[[searchFilterMatches objectAtIndex:_searchFilterMatchesLocation] range]];
                findResultLabel.text = [NSString stringWithFormat:@"%u matches", [searchFilterMatches count]];
            }
            else
            {
                findResultLabel.text = @"Not found";
            }
            findResultLabel.hidden = NO;
            self.loading = NO;
//        });
//    });
}

@end

@implementation CodeFileSearchBarView
@end

@implementation CodeFileSearchTextField

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
