//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppStyle.h"
#import "ACState.h"
#import "ACFile.h"
#import "ACCodeFileController.h"

#import "ACNavigationController.h"

#import "ECPopoverController.h"
#import "ECCodeView.h"
#import "ACCodeIndexerDataSource.h"

#import "ACEditorToolSelectionController.h"
#import "ACCodeFileFilterController.h"

#import "NSTimer+block.h"
#import <QuartzCore/QuartzCore.h>

@implementation ACCodeFileController {
    ACEditorToolSelectionController *editorToolSelectionController;
    ECPopoverController *editorToolSelectionPopover;
    
    ACCodeFileFilterController *filterController;
    ECPopoverController *filterPopoverController;
    
    NSTimer *filterDebounceTimer;
}

@synthesize codeView;

- (ECCodeView *)codeView
{
    if (!codeView)
    {
        codeView = [ECCodeView new];
        
        // Datasource setup
        codeView.datasource = [ACCodeIndexerDataSource new];
        
        // Layout setup
        codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        codeView.backgroundColor = [UIColor whiteColor];
        codeView.caretColor = [UIColor styleThemeColorOne];
        codeView.selectionColor = [[UIColor styleThemeColorOne] colorWithAlphaComponent:0.3];
        
        codeView.lineNumbersEnabled = YES;
        codeView.lineNumbersWidth = 30;
        codeView.lineNumbersFont = [UIFont systemFontOfSize:10];
        codeView.lineNumbersColor = [UIColor colorWithWhite:0.8 alpha:1];
        // TODO maybe is not the best option to draw the line number in an external block
        codeView.lineNumberRenderingBlock = ^(CGContextRef context, CGRect lineNumberBounds, CGFloat baseline, NSUInteger lineNumber, BOOL isWrappedLine) {
            CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1].CGColor);
            CGContextMoveToPoint(context, lineNumberBounds.size.width + 3, 0);
            CGContextAddLineToPoint(context, lineNumberBounds.size.width + 3, lineNumberBounds.size.height);
            CGContextStrokePath(context);
            
//            if (!isWrappedLine)
//                return;
//
//            CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
//            CGContextFillRect(context, lineNumberBounds);
        };
        
        codeView.renderer.preferredLineCountPerSegment = 500;
    }
    return codeView;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Tool Target Protocol Implementation

@synthesize toolButton;

+ (id)newNavigationTargetController
{
    return [ACCodeFileController new];
}

- (void)openURL:(NSURL *)url
{
    // TODO handle error
    ACFile *file = (ACFile *)[[ACState sharedState] objectWithURL:url];
    
    // TODO start loading animation
    ACCodeIndexerDataSource *dataSource = (ACCodeIndexerDataSource *)self.codeView.datasource;
    [file loadCodeUnitWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            dataSource.codeUnit = file.codeUnit;
            [self.codeView updateAllText];
        }
        // TODO else report error
    }];
    
    self.codeView.text = file.contentString;
}

- (BOOL)enableTabBar
{
    return YES;
}

- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier
{
    return YES;
}

- (BOOL)shouldShowTabBar
{
    return YES;
}

- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController
{
    return YES;
}

- (id<UITextFieldDelegate>)delegateForFilterField:(UITextField *)textField
{
    return self;
}

- (UIButton *)toolButton
{
    if (!toolButton)
    {
        toolButton = [UIButton new];
        [toolButton setTitle:@"Tools" forState:UIControlStateNormal];
        [toolButton setTitleColor:[UIColor styleForegroundColor] forState:UIControlStateNormal];
        toolButton.titleLabel.font = [UIFont styleFontWithSize:14];
        [toolButton addTarget:self action:@selector(toolButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return toolButton;
}

#pragma mark -

- (void)toolButtonAction:(id)sender
{
    if (!editorToolSelectionController)
    {
        editorToolSelectionController = [[ACEditorToolSelectionController alloc] initWithNibName:@"ACEditorToolSelectionController" bundle:nil];
        editorToolSelectionController.contentSizeForViewInPopover = CGSizeMake(250, 284);
        editorToolSelectionController.targetNavigationController = self.ACNavigationController;
    }
    
    if (!editorToolSelectionPopover)
    {
        editorToolSelectionPopover = [[ECPopoverController alloc] initWithContentViewController:editorToolSelectionController];
        editorToolSelectionPopover.popoverView.contentCornerRadius = 0;
        
        editorToolSelectionController.containerPopoverController = editorToolSelectionPopover;
    }
    
    [editorToolSelectionPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = self.codeView;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    editorToolSelectionController = nil;
    editorToolSelectionPopover = nil;
    
    filterController = nil;
    filterPopoverController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UITextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (!filterController)
    {
        // TODO this require loading spinner
        filterController = [[ACCodeFileFilterController alloc] initWithStyle:UITableViewStylePlain];
        filterController.targetCodeView = self.codeView;
        filterController.contentSizeForViewInPopover = CGSizeMake(400, 300);
        
        // Scroll codeview to selected filter result range
        __weak ECCodeView *thisCodeView = codeView;
        filterController.didSelectFilterResultBlock = ^(NSRange range) {
            if (range.length == 0)
                return;
            
            ECRectSet *rangeRects = [thisCodeView.renderer rectsForStringRange:range limitToFirstLine:NO];
            
            // Scroll to position
            CGRect scrollRect = rangeRects.bounds;
            scrollRect.origin.y -= 50;
            scrollRect.size.height += 100;
            [thisCodeView scrollRectToVisible:scrollRect animated:YES];
            
            // Highlight with animation
            [rangeRects enumerateRectsUsingBlock:^(CGRect rect, BOOL *stop) {
                UIView *highlightView = [[UIView alloc] initWithFrame:rect];
                highlightView.backgroundColor = [UIColor redColor];
                highlightView.alpha = 0;
                [thisCodeView addSubview:highlightView];
                [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
                    highlightView.alpha = 1;
                    highlightView.transform = CGAffineTransformMakeScale(2, 2);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
                        highlightView.alpha = 0;
                        highlightView.transform = CGAffineTransformIdentity;
                    } completion:^(BOOL finished) {
                        [highlightView removeFromSuperview];
                    }];
                }];
            }];
        };
    }
    
    if (!filterPopoverController)
    {
        filterPopoverController = [[ECPopoverController alloc] initWithContentViewController:filterController];
        filterPopoverController.passthroughViews = [NSArray arrayWithObject:textField];
    }
    
    [filterPopoverController presentPopoverFromRect:textField.frame inView:textField.superview permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    // Select right button to allow content deletion
    if ([textField.rightView isKindOfClass:[UIButton class]])
    {
        [(UIButton *)textField.rightView setSelected:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    [filterPopoverController dismissPopoverAnimated:YES];
    
    // Select right button to normal icon
    // TODO set as arrow to cycle through search results
    if ([textField.rightView isKindOfClass:[UIButton class]])
    {
        [(UIButton *)textField.rightView setSelected:NO];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Calculate filter string
    NSMutableString *filterString = [textField.text mutableCopy];
    [filterString replaceCharactersInRange:range withString:string];
    
    // Apply filter to filterController with .3 second debounce
    [filterDebounceTimer invalidate];
    filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        filterController.filterString = filterString;
    } repeats:NO];
    
    return YES;
}

@end
