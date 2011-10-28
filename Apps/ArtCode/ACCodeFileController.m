//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppStyle.h"
#import "ACFileDocument.h"
#import "ACCodeFileController.h"

#import <ECUIKit/ECPopoverController.h>
#import <ECUIKit/ECCodeView.h>

#import "ACSingleTabController.h"

#import "ACEditorToolSelectionController.h"
#import "ACCodeFileFilterController.h"

#import <ECFoundation/NSTimer+block.h>
#import <QuartzCore/QuartzCore.h>

@interface ACCodeFileController ()
{
    ACEditorToolSelectionController *editorToolSelectionController;
    ECPopoverController *editorToolSelectionPopover;
    
    ACCodeFileFilterController *filterController;
    ECPopoverController *filterPopoverController;
    
    NSTimer *filterDebounceTimer;
}
@property (nonatomic, strong) ACFileDocument *document;
@end

@implementation ACCodeFileController

@synthesize fileURL = _fileURL;
@synthesize tab = _tab;
@synthesize codeView;
@synthesize document = _document;

- (void)setFileURL:(NSURL *)fileURL
{
    if (fileURL == _fileURL)
        return;
    
    [self willChangeValueForKey:@"fileURL"];
    
    _fileURL = fileURL;
    
    if (fileURL)
    {
        self.loading = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ACFileDocument *document = [[ACFileDocument alloc] initWithFileURL:fileURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.document = document;
                self.loading = NO;
            });
        });
    }
    
    [self didChangeValueForKey:@"fileURL"];
}

- (ECCodeView *)codeView
{
    return (ECCodeView *)self.view;
}

- (ACFileDocument *)document
{
    if (!self.fileURL)
        return nil;
    if (!_document)
    {
        self.document = [[ACFileDocument alloc] initWithFileURL:self.fileURL];
    }
    return _document;
}

- (void)setDocument:(ACFileDocument *)document
{
    if (document == _document)
        return;
    
    [self willChangeValueForKey:@"document"];
    
    [_document closeWithCompletionHandler:nil];
    _document = document;
    [_document openWithCompletionHandler:^(BOOL success) {
        ECASSERT(success);
        self.codeView.dataSource = _document;
    }];
    
    [self didChangeValueForKey:@"document"];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Single Tab Controller Toolbar Actions

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar
{
    return YES;
}

- (void)toolButtonAction:(id)sender
{
    if (!editorToolSelectionController)
    {
        editorToolSelectionController = [[ACEditorToolSelectionController alloc] initWithNibName:@"ACEditorToolSelectionController" bundle:nil];
        editorToolSelectionController.contentSizeForViewInPopover = CGSizeMake(250, 284);
//        editorToolSelectionController.targetNavigationController = self.ACNavigationController;
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
    codeView = [ECCodeView new];
        
    // Layout setup
    codeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    codeView.backgroundColor = [UIColor whiteColor];
    codeView.caretColor = [UIColor styleThemeColorOne];
    codeView.selectionColor = [[UIColor styleThemeColorOne] colorWithAlphaComponent:0.3];
    codeView.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    codeView.lineNumbersEnabled = YES;
    codeView.lineNumbersWidth = 30;
    codeView.lineNumbersFont = [UIFont systemFontOfSize:10];
    codeView.lineNumbersColor = [UIColor colorWithWhite:0.8 alpha:1];
    
    codeView.alwaysBounceVertical = YES;
    
    self.view = codeView;
}

- (void)viewDidLoad
{
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:@"tools" style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
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
