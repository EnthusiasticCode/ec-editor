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
    // Indicate if the controller is in a replacement procedure. This will avoid the file buffer changes to update the filter.
    BOOL _isReplacing;
}

@property (readwrite, copy) NSArray *searchFilterMatches;

- (void)_addFindFilterCodeViewPass;
- (void)_applyFindFilterAndFlash:(BOOL)shouldFlash;
- (void)_fileBufferWillChangeNotification:(NSNotification *)notification;
- (void)_fileBufferDidChangeNotification:(NSNotification *)notification;

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
        [self _applyFindFilterAndFlash:YES];
    }
    
    [self didChangeValueForKey:@"targetCodeFileController"];
}

- (void)setRegExpOptions:(NSRegularExpressionOptions)value
{
    if (value == regExpOptions)
        return;
    [self willChangeValueForKey:@"regExpOptions"];
    regExpOptions = value;
    [self _applyFindFilterAndFlash:YES];
    [self didChangeValueForKey:@"regExpOptions"];
}

- (void)setHitMustOption:(ACCodeFileSearchHitMustOption)value
{
    if (value == hitMustOption)
        return;
    [self willChangeValueForKey:@"hitMustOption"];
    hitMustOption = value;
    [self _applyFindFilterAndFlash:YES];
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
    [self _applyFindFilterAndFlash:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fileBufferWillChangeNotification:) name:ECFileBufferWillReplaceCharactersNotificationName object:self.targetCodeFileController.document.fileBuffer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fileBufferDidChangeNotification:) name:ECFileBufferDidReplaceCharactersNotificationName object:self.targetCodeFileController.document.fileBuffer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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

- (IBAction)replaceSingleAction:(id)sender
{
}

- (IBAction)replaceAllAction:(id)sender
{
    if ([self.searchFilterMatches count] == 0)
    {
        [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" image:nil displayImmediatly:YES];
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
        originalString = [self.targetCodeFileController.document.fileBuffer stringInRange:NSMakeRange(match.range.location + offset, match.range.length)];
        replacementRange = [self.targetCodeFileController.document.fileBuffer replaceMatch:match withTemplate:replacementString offset:offset];
        [[self.targetCodeFileController.codeView.undoManager prepareWithInvocationTarget:self.targetCodeFileController.document.fileBuffer] replaceCharactersInRange:replacementRange withString:originalString];
        offset += replacementRange.length - [originalString length];
    }
    
    [self.targetCodeFileController.codeView.undoManager endUndoGrouping];
    
    [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Replaced %u occurrences", [matches count]] image:nil displayImmediatly:YES];
    
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
    [targetCodeFileController.codeView addPassLayerBlock:^(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSRegularExpressionOptions options = self.regExpOptions;
        
        if (self.hitMustOption != ACCodeFileSearchHitMustContain)
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
            if (self.hitMustOption == ACCodeFileSearchHitMustStartWith || self.hitMustOption == ACCodeFileSearchHitMustMatch)
                [modifiedFilterString insertString:@"\\b" atIndex:0];
            if (self.hitMustOption == ACCodeFileSearchHitMustEndWith || self.hitMustOption == ACCodeFileSearchHitMustMatch)
                [modifiedFilterString appendString:@"\\b"];
            filterString = modifiedFilterString;
        }
            
        // TODO create here? manage error
        NSRegularExpression *filterRegExp = [NSRegularExpression regularExpressionWithPattern:filterString options:options error:NULL];
        NSArray *matches = nil;
        if (filterRegExp != nil)
            matches = [self.targetCodeFileController.document.fileBuffer matchesOfRegexp:filterRegExp options:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
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
            if ([searchFilterMatches count] > 0)
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
        });
    });
}

- (void)_fileBufferWillChangeNotification:(NSNotification *)notification
{
    self.searchFilterMatches = nil;
}

- (void)_fileBufferDidChangeNotification:(NSNotification *)notification
{
    if (!_isReplacing)
        [self _applyFindFilterAndFlash:NO];
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
