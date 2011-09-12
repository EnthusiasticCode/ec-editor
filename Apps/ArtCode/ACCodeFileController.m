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

#import "ECPopoverController.h"
#import "ECCodeView.h"
#import "ACCodeIndexerDataSource.h"

#import "ACCodeFileFilterController.h"

#import <QuartzCore/QuartzCore.h>

@implementation ACCodeFileController {
    ACCodeFileFilterController *filterController;
    ECPopoverController *filterPopoverController;
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
        codeView.textInsets = UIEdgeInsetsMake(10, 40, 10, 10);
        
        codeView.lineNumberWidth = 30;
        codeView.lineNumberFont = [UIFont systemFontOfSize:10];
        codeView.lineNumberColor = [UIColor colorWithWhite:0.8 alpha:1];
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

+ (id)newNavigationTargetController
{
    return [ACCodeFileController new];
}

- (void)openURL:(NSURL *)url
{
    // TODO handle error
    ACFile *file = (ACFile *)[[ACState sharedState] nodeWithURL:url];
    
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

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = self.codeView;
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
        filterController = [[ACCodeFileFilterController alloc] initWithNibName:@"ACCodeFileFilterController" bundle:nil];
        filterController.targetCodeView = self.codeView;
        filterController.contentSizeForViewInPopover = CGSizeMake(300, 300);
        
        // Scroll codeview to selected filter result range
        __weak ECCodeView *thisCodeView = codeView;
        filterController.didSelectFilterResultBlock = ^(NSRange range) {
            if (range.length == 0)
                range.length = 1; // Go to line
            
            CGRect rangeRect = [thisCodeView.renderer rectsForStringRange:range limitToFirstLine:NO].bounds;
            rangeRect.origin.x += thisCodeView.textInsets.left;
            rangeRect.origin.y += thisCodeView.textInsets.top - 50;
            rangeRect.size.height += 100;
            [thisCodeView scrollRectToVisible:rangeRect animated:YES];
        };
    }
    
    if (!filterPopoverController)
    {
        filterPopoverController = [[ECPopoverController alloc] initWithContentViewController:filterController];
    }
    
    [filterPopoverController presentPopoverFromRect:textField.frame inView:textField.superview permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [filterPopoverController dismissPopoverAnimated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Apply filter to filterController
    NSMutableString *filterString = [textField.text mutableCopy];
    [filterString replaceCharactersInRange:range withString:string];
    filterController.filterString = filterString;
    
    // TODO Use a debounce timer instead
    
    return YES;
}

@end
