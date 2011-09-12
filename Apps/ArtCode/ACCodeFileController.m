//
//  ACCodeFileController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppStyle.h"
#import "ACCodeFileController.h"

#import "ECPopoverController.h"
#import "ECCodeView.h"
#import "ACCodeIndexerDataSource.h"

#import "ACCodeFileFilterController.h"
#import "AppStyle.h"
#import "ACFile.h"
#import "ACProject.h"
#import "ACProjectDocument.h"

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
        filterController = [ACCodeFileFilterController new];
        filterController.contentSizeForViewInPopover = CGSizeMake(300, 300);
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
    // TODO apply filter to filterController
    return YES;
}

@end
