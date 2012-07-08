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
#import "NSTimer+BlockTimer.h"
#import "CodeView.h"
#import "TextRange.h"
#import "BezelAlert.h"

#import "CodeFileSearchOptionsController.h"

#import <CocoaOniguruma/OnigRegexp.h>

static NSString * findFilterPassBlockKey = @"findFilterPass";


@interface CodeFileSearchBarController ()

@property (nonatomic, readwrite, strong) NSRegularExpression *searchFilter;
@property (nonatomic, readwrite, copy) NSArray *searchFilterMatches;

- (void)_addFindFilterCodeViewPass;
- (void)_applyFindFilterAndFlash:(BOOL)shouldFlash;

@end


@implementation CodeFileSearchBarController {
  NSInteger _searchFilterMatchesLocation;
  NSTimer *_filterDebounceTimer;
  RACDisposable *_targetCodeViewTextDisposable;
  // Indicate if the controller is in a replacement procedure. This will avoid the file buffer changes to update the filter.
  BOOL _isReplacing;
}

#pragma mark - Properties

@synthesize targetCodeFileController = _targetCodeFileController;
@synthesize findTextField = _findTextField, replaceTextField = _replaceTextField, findResultLabel = _findResultLabel;
@synthesize searchFilter = _searchFilter, searchFilterMatches = _searchFilterMatches, regExpOptions = _regExpOptions, hitMustOption = _hitMustOption;

- (void)setTargetCodeFileController:(CodeFileController *)controller {
  if (controller == _targetCodeFileController) {
    return;
  }
  
  if (_targetCodeFileController) {
    [_targetCodeFileController.codeView removePassLayerForKey:findFilterPassBlockKey];
  }
  
  _targetCodeFileController = controller;
  
  if (self.isViewLoaded && self.view.window != nil) {
    [self _addFindFilterCodeViewPass];
    [self _applyFindFilterAndFlash:YES];
  }
}

- (void)setRegExpOptions:(NSRegularExpressionOptions)value {
  if (value == _regExpOptions)
    return;
  _regExpOptions = value;
  [self _applyFindFilterAndFlash:YES];
}

- (void)setHitMustOption:(CodeFileSearchHitMustOption)value {
  if (value == _hitMustOption)
    return;
  _hitMustOption = value;
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

- (void)viewDidUnload  {
  [self setSearchFilterMatches:nil];
  [self setFindTextField:nil];
  [self setReplaceTextField:nil];
  [self setFindResultLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self _addFindFilterCodeViewPass];
  [self _applyFindFilterAndFlash:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithUnsignedInteger:self.regExpOptions] forKey:@"CodeFileFindRegExpOptions"];
  [defaults setObject:[NSNumber numberWithUnsignedInteger:self.hitMustOption] forKey:@"CodeFileFindHitMustOption"];
  [defaults synchronize];
  
  [self.targetCodeFileController.codeView removePassLayerForKey:findFilterPassBlockKey];
  
  if ([_searchFilterMatches count] > 0)
  {
    [self.targetCodeFileController.codeView setNeedsDisplay];
  }
  self.searchFilterMatches = nil;
  
  [super viewDidDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.destinationViewController isKindOfClass:[CodeFileSearchOptionsController class]]) {
    [(CodeFileSearchOptionsController *)segue.destinationViewController setParentSearchBarController:self];
    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
      [(CodeFileSearchOptionsController *)segue.destinationViewController setParentPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
    }
  } else {
    [super prepareForSegue:segue sender:sender];
  }
}

#pragma mark - Text Field Delegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  if (_filterDebounceTimer) {
    [_filterDebounceTimer invalidate];
  }
  _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
    [self _applyFindFilterAndFlash:YES];
  } repeats:NO];
  
  return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
  [self textField:textField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:nil];
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - Action Methods

- (IBAction)moveResultAction:(id)sender {
  if (_targetCodeFileController == nil) {
    return;
  }
  
  _searchFilterMatchesLocation += [sender tag];
  if (_searchFilterMatchesLocation < 0) {
    // TODO use image isntead
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:nil image:[UIImage imageNamed:@"bezelAlert_cycleDownIcon"] displayImmediatly:YES];
    _searchFilterMatchesLocation = [_searchFilterMatches count] - 1;
  } else if (_searchFilterMatchesLocation >= (NSInteger)[_searchFilterMatches count]) {
    // TODO use image isntead
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:nil image:[UIImage imageNamed:@"bezelAlert_cycleUpIcon"] displayImmediatly:YES];
    _searchFilterMatchesLocation = 0;
  }
  
  [_targetCodeFileController.codeView flashTextInRange:[[_searchFilterMatches objectAtIndex:_searchFilterMatchesLocation] range]];
}

- (IBAction)toggleReplaceAction:(id)sender {
  if (self.singleTabController.toolbarHeight != 88) {
    [self.singleTabController setToolbarHeight:88 animated:YES];
  } else {
    [self.singleTabController resetToolbarHeightAnimated:YES];
  }
}

- (IBAction)closeBarAction:(id)sender {
  ASSERT(self.singleTabController.toolbarViewController == self);
  [self.singleTabController setToolbarViewController:nil animated:YES];
}

- (IBAction)replaceSingleAction:(id)sender {
  if ([self.searchFilterMatches count] == 0) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
    return;
  }
  
  _isReplacing = YES;
  
  // Get the string to replace
  NSTextCheckingResult *match = [self.searchFilterMatches objectAtIndex:_searchFilterMatchesLocation];
  NSString *replacementString = self.replaceTextField.text;
  if (self.regExpOptions & NSRegularExpressionIgnoreMetacharacters) {
    replacementString = [NSRegularExpression escapedTemplateForString:replacementString];
  }
  replacementString = [self.searchFilter replacementStringForResult:match inString:self.targetCodeFileController.codeView.text offset:0 template:replacementString];
  
  [self.targetCodeFileController.codeView.undoManager beginUndoGrouping];
  [self.targetCodeFileController.codeView.undoManager setActionName:@"Replace"];
  [self.targetCodeFileController.codeView replaceRange:[TextRange textRangeWithRange:match.range] withText:replacementString];
  [self.targetCodeFileController.codeView.undoManager endUndoGrouping];
  
  _isReplacing = NO;
  [self.targetCodeFileController.codeView flashTextInRange:NSMakeRange(match.range.location, [replacementString length])];
  [self _applyFindFilterAndFlash:NO];
}

- (IBAction)replaceAllAction:(id)sender {
  if ([self.searchFilterMatches count] == 0) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
    return;
  }
  
  _isReplacing = YES;
  
  [self.targetCodeFileController.codeView.undoManager beginUndoGrouping];
  [self.targetCodeFileController.codeView.undoManager setActionName:@"Replace All"];
  
  NSString *templateString = self.replaceTextField.text;
  if (self.regExpOptions & NSRegularExpressionIgnoreMetacharacters) {
    templateString = [NSRegularExpression escapedTemplateForString:templateString];
  }
  
  NSArray *matches = self.searchFilterMatches;
  NSString *replacementString = nil;
  NSInteger offset = 0;
  for (NSTextCheckingResult *match in matches)
  {
    replacementString = [self.searchFilter replacementStringForResult:match inString:self.targetCodeFileController.codeView.text offset:offset template:templateString];
    [self.targetCodeFileController.codeView replaceRange:[TextRange textRangeWithRange:NSMakeRange(match.range.location + offset, match.range.length)] withText:replacementString];
    offset += replacementString.length - match.range.length;
  }
  
  [self.targetCodeFileController.codeView.undoManager endUndoGrouping];
  
  [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Replaced %u occurrences", matches.count] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
  
  _isReplacing = NO;
  [self _applyFindFilterAndFlash:NO];
}

#pragma mark - Private Methods

- (void)_addFindFilterCodeViewPass {
  // TODO retrieve from theme
  UIColor *decorationColor = [UIColor colorWithRed:249.0/255.0 green:254.0/255.0 blue:192.0/255.0 alpha:1];
  UIColor *decorationSecondaryColor = [UIColor colorWithRed:224.0/255.0 green:233.0/255.0 blue:128.0/255.0 alpha:1];
  
  __block NSMutableIndexSet *searchSectionIndexes = nil;
  __block NSUInteger lastLine = NSUIntegerMax;
  [_targetCodeFileController.codeView addPassLayerBlock:^(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
    NSArray *searchSection = self.searchFilterMatches;
    NSUInteger searchSectionCount = [searchSection count];
    if (searchSectionCount == 0) {
      return;
    }
    
    // Get indexes to search into
    if (searchSectionIndexes == nil || lineNumber < lastLine) {
      searchSectionIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [searchSection count])];
    }
    
    NSUInteger endStringRange = NSMaxRange(stringRange);
    [searchSection enumerateObjectsAtIndexes:searchSectionIndexes options:0 usingBlock:^(NSTextCheckingResult *result, NSUInteger idx, BOOL *stop) {
      // End loop if range after current string range
      NSRange range = result.range;
      if (range.location >= endStringRange) {
        *stop = YES;
        return;
      }
      
      // Skip indexes behind current string range
      if (NSMaxRange(range) < stringRange.location) {
        [searchSectionIndexes removeIndex:idx];
        return;
      }
      
      // Adjust range to fit in string
      if (range.location < stringRange.location) {
        range = NSMakeRange(stringRange.location, range.length - (stringRange.location - range.location));
      } else {
        range.location -= stringRange.location;
      }
      
      // Draw decoration
      CGRect rect = [line boundsForSubstringInRange:range];
      CGContextSetFillColorWithColor(context, decorationColor.CGColor);
      CGContextFillRect(context, rect);
      
      rect.size.height = 2;
      CGContextSetFillColorWithColor(context, decorationSecondaryColor.CGColor);
      CGContextFillRect(context, rect);            
    }];
  } underText:YES forKey:findFilterPassBlockKey];
  
  // Adding RAC for codeview text change
  [_targetCodeViewTextDisposable dispose];
  __weak CodeFileSearchBarController *this = self;
  _targetCodeViewTextDisposable = [[[[RACAble(self.targetCodeFileController.codeView, text) doNext:^(id x) {
    this.searchFilterMatches = nil;
  }] throttle:0.3] distinctUntilChanged] subscribeNext:^(id x) {
    [this _applyFindFilterAndFlash:NO];
  }];
}

- (void)_applyFindFilterAndFlash:(BOOL)shouldFlash {
  if (!_targetCodeFileController) {
    return;
  }
  
  __block NSString *filterString = self.findTextField.text;
  
  if (filterString.length == 0) {
    _findResultLabel.hidden = YES;
    self.searchFilterMatches = nil;
    [_targetCodeFileController.codeView setNeedsDisplay];
    return;
  }
  
  self.loading = YES;
  NSRegularExpressionOptions options = self.regExpOptions;
  
  if (self.hitMustOption != CodeFileSearchHitMustContain) {
    NSMutableString *modifiedFilterString = nil;
    if (options & NSRegularExpressionIgnoreMetacharacters) {
      options &= ~NSRegularExpressionIgnoreMetacharacters;
      // TODO URI use OnigRegExp instead
      modifiedFilterString = [[NSRegularExpression escapedPatternForString:filterString] mutableCopy];
    } else {
      modifiedFilterString = [filterString mutableCopy];
    }
    if (self.hitMustOption == CodeFileSearchHitMustStartWith || self.hitMustOption == CodeFileSearchHitMustMatch) {
      [modifiedFilterString insertString:@"\\b" atIndex:0];
    }
    if (self.hitMustOption == CodeFileSearchHitMustEndWith || self.hitMustOption == CodeFileSearchHitMustMatch) {
      [modifiedFilterString appendString:@"\\b"];
    }
    filterString = modifiedFilterString;
  }
  
  // TODO create here? manage error and convert NSRegularExpression options to OnigRegexp options
  self.searchFilter = [NSRegularExpression regularExpressionWithPattern:filterString options:options error:NULL];
  NSArray *matches = nil;
  if (self.searchFilter != nil) {
    NSString *targetString = self.targetCodeFileController.codeView.text;
    matches = [self.searchFilter matchesInString:targetString options:0 range:NSMakeRange(0, targetString.length)];
  }
  
  self.searchFilterMatches = matches;
  [_targetCodeFileController.codeView setNeedsDisplay];
  // Set first match to flash
  _searchFilterMatchesLocation = 0;
  NSRange visibleRange = self.targetCodeFileController.codeView.visibleTextRange;
  [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *check, NSUInteger idx, BOOL *stop) {
    if ([check rangeAtIndex:0].location >= visibleRange.location) {
      _searchFilterMatchesLocation = idx;
      *stop = YES;
    }
  }];
  // Change report label
  if (self.searchFilter == nil) {
    _findResultLabel.text = @"Invalid RegExp";
  } else if ([_searchFilterMatches count] > 0) {
    if (shouldFlash) {
      [_targetCodeFileController.codeView flashTextInRange:[[_searchFilterMatches objectAtIndex:_searchFilterMatchesLocation] range]];
    }
    _findResultLabel.text = [NSString stringWithFormat:@"%u matches", [_searchFilterMatches count]];
  } else {
    _findResultLabel.text = @"Not found";
  }
  _findResultLabel.hidden = NO;
  self.loading = NO;
}

@end

@implementation CodeFileSearchBarView
@end

@implementation CodeFileSearchTextField

- (CGRect)textRectForBounds:(CGRect)bounds {
  bounds = [super textRectForBounds:bounds];
  bounds.origin.x += 30;
  bounds.size.width -= 30;
  return bounds;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  return [self textRectForBounds:bounds];
}

@end
