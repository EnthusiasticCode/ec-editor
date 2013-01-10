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
#import "CodeView.h"
#import "TextRange.h"
#import "BezelAlert.h"

#import "CodeFileSearchOptionsController.h"

#import <CocoaOniguruma/OnigRegexp.h>

static NSString * findFilterPassBlockKey = @"findFilterPass";


@interface CodeFileSearchBarController ()

// RegExp matches resulting from searching the search string in the target code view text.
@property (nonatomic, readwrite, copy) NSArray *searchFilterMatches;

// Index in searchFilterMatches of the match that has been flashed last.
// Used to keep the state of which match to flash with previous and next UI buttons.
@property (nonatomic) NSUInteger searchFilterHighlightedMatchIndex;

@property (nonatomic, strong) RACCommand *replaceOnceCommand;
@property (nonatomic, strong) RACCommand *replaceAllCommand;

// Utility method to apply a filter pass to the given codeview.
// The filter will use searchFilterMatches to know which locations to highlight in the codeview.
- (void)_addFindFilterPassToCodeView:(CodeView *)codeView;

@end


@implementation CodeFileSearchBarController {
  // Indicate if the controller is in a replacement procedure. This will avoid the file buffer changes to update the filter.
  BOOL _isReplacing;
}

#pragma mark - Controller Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (!self) return nil;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.regExpOptions = [[defaults objectForKey:@"CodeFileFindRegExpOptions"] unsignedIntegerValue] | NSRegularExpressionAnchorsMatchLines;
	self.hitMustOption = [[defaults objectForKey:@"CodeFileFindHitMustOption"] unsignedIntegerValue];
	
	// RAC
	@weakify(self);
	RACSignal *regExpOptionsSignal = RACAbleWithStart(self.regExpOptions);
	
	// Raw search string signal
	RACSignal *searchStringSignal = [[[[RACAble(self.findTextField) map:^(UITextField *field) {
		return field.rac_textSignal;
	}] switchToLatest] throttle:0.3] distinctUntilChanged];
	
	// Reaction to show/hide findResultLabel
	[[searchStringSignal map:^(NSString *string) {
		return @(string.length == 0);
	}] toProperty:@keypath(self.findResultLabel.hidden) onObject:self];
	
	// Reaction to generate the search regular expression
	RACSignal *searchRegExpSignal = [RACSignal combineLatest:@[ searchStringSignal, regExpOptionsSignal, RACAbleWithStart(self.hitMustOption) ] reduce:^(NSString *filterString, NSNumber *regExpOptionsNumber, NSNumber *hitMustOptionNumber) {
		if (filterString.length == 0) return (NSRegularExpression *)nil;
		
		NSRegularExpressionOptions regExpOptions = (NSRegularExpressionOptions)regExpOptionsNumber.unsignedIntegerValue;
		CodeFileSearchHitMustOption hitMustOption = (CodeFileSearchHitMustOption)hitMustOptionNumber.unsignedIntegerValue;
		
		// Modify filter string for containing in string
		if (hitMustOption != CodeFileSearchHitMustContain) {
			NSMutableString *modifiedFilterString = nil;
			if (regExpOptions & NSRegularExpressionIgnoreMetacharacters) {
				regExpOptions &= ~NSRegularExpressionIgnoreMetacharacters;
				// TODO: URI use OnigRegExp instead
				modifiedFilterString = [[NSRegularExpression escapedPatternForString:filterString] mutableCopy];
			} else {
				modifiedFilterString = [filterString mutableCopy];
			}
			if (hitMustOption == CodeFileSearchHitMustStartWith || hitMustOption == CodeFileSearchHitMustMatch) {
				[modifiedFilterString insertString:@"\\b" atIndex:0];
			}
			if (hitMustOption == CodeFileSearchHitMustEndWith || hitMustOption == CodeFileSearchHitMustMatch) {
				[modifiedFilterString appendString:@"\\b"];
			}
			filterString = modifiedFilterString;
		}
		
		// Returning the regular expression to use to search
		// TODO: create here? manage error and convert NSRegularExpression options to OnigRegexp options
		return [NSRegularExpression regularExpressionWithPattern:filterString options:regExpOptions error:NULL];
	}];
	
	// Reaction to setup the codeview and get it's text when changed
	RACSignal *targetCodeViewTextSignal = [[[RACAble(self.targetCodeFileController) mapPreviousWithStart:nil combine:^(CodeFileController *previous, CodeFileController *next) {
		@strongify(self);
		// Clean previous codeview
		[previous.codeView removePassLayerForKey:findFilterPassBlockKey];
		if (self.searchFilterMatches.count > 0) {
			[previous.codeView setNeedsDisplay];
		}
		// Prepare new codeview
		[self _addFindFilterPassToCodeView:next.codeView];
		return RACAbleWithStart(next, codeView.text);
	}] switchToLatest] throttle:0.3];
	
	// Reaction to update matches
	[[RACSignal combineLatest:@[ targetCodeViewTextSignal, searchRegExpSignal ] reduce:^(NSString *targetString, NSRegularExpression *searchRegExp) {
		if (targetString.length == 0) return (NSArray *)nil;
		// TODO: self.loading = YES; ??
		return [searchRegExp matchesInString:targetString options:0 range:NSMakeRange(0, targetString.length)];
	}] toProperty:@keypath(self.searchFilterMatches) onObject:self];
	
	// searchFilterMatches related reactions
	RACSignal *searchFilterMatchesSignal = RACAble(self.searchFilterMatches);
	
	// Reaction to update target CodeView so that the added layer pass will use searchFilterMatches to highlight
	[[searchFilterMatchesSignal map:^(NSArray *matches) {
		@strongify(self);
		// TODO: self.loading = NO; ??
		// Side effect to update matches highlight layer pass in target CodeView
		[self.targetCodeFileController.codeView setNeedsDisplay];
		// Find the first visible match to flash
		NSRange visibleRange = self.targetCodeFileController.codeView.visibleTextRange;
		__block NSUInteger firstVisibleMatchIndex = 0;
		[matches enumerateObjectsUsingBlock:^(NSTextCheckingResult *check, NSUInteger idx, BOOL *stop) {
			if ([check rangeAtIndex:0].location >= visibleRange.location) {
				firstVisibleMatchIndex = idx;
				*stop = YES;
			}
		}];
		return @(firstVisibleMatchIndex);
	}] toProperty:@keypath(self.searchFilterHighlightedMatchIndex) onObject:self];
	
	// Reaction to flash an highlighted match
	RACSignal *searchFilterHighlightedMatchIndexSignal = RACAble(self.searchFilterHighlightedMatchIndex);
	[searchFilterHighlightedMatchIndexSignal subscribeNext:^(NSNumber *indexNumber) {
		@strongify(self);
		NSUInteger index = indexNumber.unsignedIntegerValue;
		if (index >= self.searchFilterMatches.count) return;
		[self.targetCodeFileController.codeView flashTextInRange:[self.searchFilterMatches[index] range]];
	}];
	
	// Reaction to update the findResultLabel report text
	[[RACSignal combineLatest:@[ searchRegExpSignal, searchFilterMatchesSignal ] reduce:^(id regExp, NSArray *matches) {
		if (regExp == nil) return @"Invalid RegExp";
		if (matches.count > 0) return (NSString *)[NSString stringWithFormat:@"%u matches", matches.count];
		return @"Not found";
	}] toProperty:@keypath(self.findResultLabel.text) onObject:self];
	
	// Reaction to enable/disable move through results buttons
	[searchFilterMatchesSignal subscribeNext:^(NSArray *matches) {
		@strongify(self);
		BOOL enabled = matches.count > 0;
		self.previousResultButton.enabled = enabled;
		self.nextResultButton.enabled = enabled;
	}];
	
	// Replace
	RACSignal *replaceStringSignal = [RACSignal combineLatest:@[ [[[[RACAble(self.replaceTextField) map:^(UITextField *field) {
		return field.rac_textSignal;
	}] switchToLatest] throttle:0.3] distinctUntilChanged], regExpOptionsSignal ] reduce:^(NSString *replaceString, NSNumber *regExpOptionsNumber) {
		NSRegularExpressionOptions regExpOptions = (NSRegularExpressionOptions)regExpOptionsNumber.unsignedIntegerValue;
		if (regExpOptions & NSRegularExpressionIgnoreMetacharacters) {
			replaceString = [NSRegularExpression escapedTemplateForString:replaceString];
		}
		return replaceString;
	}];
	
	RACSignal *replaceInfoSignal = [RACSignal combineLatest:@[ searchRegExpSignal, replaceStringSignal, searchFilterMatchesSignal, searchFilterHighlightedMatchIndexSignal ]];
	
	RACSignal *canReplaceSignal = [replaceInfoSignal map:^(RACTuple *replaceInfo) {
		// Check if there is both a search regexp, a replacement string and the index to replace is contained in the matches
		return @(replaceInfo.first && [replaceInfo.second length] && [replaceInfo.third count] > [replaceInfo.fourth unsignedIntegerValue]);
	}];
	[canReplaceSignal toProperty:@keypath(self.replaceOnceButton.enabled) onObject:self];
	[canReplaceSignal toProperty:@keypath(self.replaceAllButton.enabled) onObject:self];
	
	self.replaceOnceCommand = [RACCommand commandWithCanExecuteSignal:canReplaceSignal block:nil];
	[[replaceInfoSignal sample:self.replaceOnceCommand] subscribeNext:^(RACTuple *replaceInfo) {
		@strongify(self);
		CodeView *codeView = self.targetCodeFileController.codeView;
		if (!codeView) return;
		
		RACTupleUnpack(NSRegularExpression *searchRegExp, NSString *replaceString, NSArray *matches, NSNumber *matchIndex) = replaceInfo;
		NSTextCheckingResult *match = matches[matchIndex.unsignedIntegerValue];
		replaceString = [searchRegExp replacementStringForResult:match inString:codeView.text offset:0 template:replaceString];
		
		[codeView.undoManager beginUndoGrouping];
		[codeView.undoManager setActionName:@"Replace"];
		[codeView replaceRange:[TextRange textRangeWithRange:match.range] withText:replaceString];
		[codeView.undoManager endUndoGrouping];

		[codeView flashTextInRange:NSMakeRange(match.range.location, [replaceString length])];
	}];
	
	self.replaceAllCommand = [RACCommand commandWithCanExecuteSignal:canReplaceSignal block:nil];
	[[replaceInfoSignal sample:self.replaceAllCommand] subscribeNext:^(RACTuple *replaceInfo) {
		@strongify(self);
		CodeView *codeView = self.targetCodeFileController.codeView;
		if (!codeView) return;
		
		RACTupleUnpack(NSRegularExpression *searchRegExp, NSString *replaceTemplateString, NSArray *matches) = replaceInfo;
		
		[self.targetCodeFileController.codeView.undoManager beginUndoGrouping];
		[self.targetCodeFileController.codeView.undoManager setActionName:@"Replace All"];
		
		NSString *replacementString = nil;
		NSInteger offset = 0;
		for (NSTextCheckingResult *match in matches) {
			replacementString = [searchRegExp replacementStringForResult:match inString:codeView.text offset:offset template:replaceTemplateString];
			[codeView replaceRange:[TextRange textRangeWithRange:NSMakeRange(match.range.location + offset, match.range.length)] withText:replacementString];
			offset += replacementString.length - match.range.length;
		}
		
		[self.targetCodeFileController.codeView.undoManager endUndoGrouping];
		
		[[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Replaced %u occurrences", matches.count] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
	}];
	
  return self;
}

#pragma mark - View Lifecycle

- (void)didReceiveMemoryWarning  {
  [self setSearchFilterMatches:nil];
  [super didReceiveMemoryWarning];
}

- (void)viewDidDisappear:(BOOL)animated {
	// Save find options as defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:@(self.regExpOptions) forKey:@"CodeFileFindRegExpOptions"];
  [defaults setObject:@(self.hitMustOption) forKey:@"CodeFileFindHitMustOption"];
  [defaults synchronize];
  
	self.targetCodeFileController = nil;
  
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

- (BOOL)textFieldShouldClear:(UITextField *)textField {
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - Action Methods

- (IBAction)moveResultAction:(id)sender {
  if (self.targetCodeFileController == nil || self.searchFilterMatches.count == 0) return;
	
	if ([sender tag] > 0) {
		if (self.searchFilterHighlightedMatchIndex + 1 >= self.searchFilterMatches.count) {
			self.searchFilterHighlightedMatchIndex = 0;
			[[BezelAlert defaultBezelAlert] addAlertMessageWithText:nil image:[UIImage imageNamed:@"bezelAlert_cycleUpIcon"] displayImmediatly:YES];
		} else {
			self.searchFilterHighlightedMatchIndex++;
		}
	} else {
		if (self.searchFilterHighlightedMatchIndex == 0) {
			self.searchFilterHighlightedMatchIndex = self.searchFilterMatches.count - 1;
			[[BezelAlert defaultBezelAlert] addAlertMessageWithText:nil image:[UIImage imageNamed:@"bezelAlert_cycleDownIcon"] displayImmediatly:YES];
		} else {
			self.searchFilterHighlightedMatchIndex--;
		}
	}
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
  if (self.searchFilterMatches.count == 0) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
    return;
  }
	
	[self.replaceOnceCommand execute:sender];
}

- (IBAction)replaceAllAction:(id)sender {
  if ([self.searchFilterMatches count] == 0) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Nothing to replace" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
    return;
  }
	
	[self.replaceAllCommand execute:sender];
//
//  _isReplacing = YES;
//  
//  [self.targetCodeFileController.codeView.undoManager beginUndoGrouping];
//  [self.targetCodeFileController.codeView.undoManager setActionName:@"Replace All"];
//  
//  NSString *templateString = self.replaceTextField.text;
//  if (self.regExpOptions & NSRegularExpressionIgnoreMetacharacters) {
//    templateString = [NSRegularExpression escapedTemplateForString:templateString];
//  }
//  
//  NSArray *matches = self.searchFilterMatches;
//  NSString *replacementString = nil;
//  NSInteger offset = 0;
//  for (NSTextCheckingResult *match in matches)
//  {
//    replacementString = [self.searchFilter replacementStringForResult:match inString:self.targetCodeFileController.codeView.text offset:offset template:templateString];
//    [self.targetCodeFileController.codeView replaceRange:[TextRange textRangeWithRange:NSMakeRange(match.range.location + offset, match.range.length)] withText:replacementString];
//    offset += replacementString.length - match.range.length;
//  }
//  
//  [self.targetCodeFileController.codeView.undoManager endUndoGrouping];
//  
//  [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:@"Replaced %u occurrences", matches.count] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
//  
//  _isReplacing = NO;
//  [self _applyFindFilterAndFlash:NO];
}

#pragma mark - Private Methods

- (void)_addFindFilterPassToCodeView:(CodeView *)codeView {
  // TODO: retrieve from theme
  UIColor *decorationColor = [UIColor colorWithRed:249.0/255.0 green:254.0/255.0 blue:192.0/255.0 alpha:1];
  UIColor *decorationSecondaryColor = [UIColor colorWithRed:224.0/255.0 green:233.0/255.0 blue:128.0/255.0 alpha:1];
  
  __block NSMutableIndexSet *searchSectionIndexes = nil;
  __block NSUInteger lastLine = NSUIntegerMax;
  [codeView addPassLayerBlock:^(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber) {
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
