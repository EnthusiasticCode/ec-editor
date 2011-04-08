//
//  FileViewController.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileController.h"
#import <ECUIKit/ECEditCodeView.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeDiagnostic.h>
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeCursor.h>

@interface FileController ()
{
@private
    NSDictionary *textStyles_;
    NSDictionary *diagnosticOverlayStyles_;
}
@end

@implementation FileController

@synthesize codeView = codeView_;
@synthesize scrollView = scrollView_;
@synthesize file = file_;
@synthesize codeUnit = codeUnit_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [textStyles_ release];
    [diagnosticOverlayStyles_ release];
    self.codeView = nil;
    self.scrollView = nil;
    self.file = nil;
    self.codeUnit = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableDictionary *textStyles = [NSMutableDictionary dictionary];
    UIFont *font = [UIFont fontWithName:@"Courier New" size:16.0];
    [textStyles setObject:[ECTextStyle textStyleWithName:@"Keyword" font:font color:[UIColor blueColor]] forKey:@"Keyword"];
    [textStyles setObject:[ECTextStyle textStyleWithName:@"Comment" font:font color:[UIColor greenColor]] forKey:@"Comment"];
    [textStyles setObject:[ECTextStyle textStyleWithName:@"Reference" font:font color:[UIColor purpleColor]] forKey:@"Reference"];
    [textStyles setObject:[ECTextStyle textStyleWithName:@"Literal" font:font color:[UIColor redColor]] forKey:@"Literal"];
    [textStyles setObject:[ECTextStyle textStyleWithName:@"Declaration" font:font color:[UIColor brownColor]] forKey:@"Declaration"];
    [textStyles setObject:[ECTextStyle textStyleWithName:@"Preprocessing" font:font color:[UIColor orangeColor]] forKey:@"Preprocessing"];
    textStyles_ = [textStyles copy];
    
    ECTextStyle *stringStyle = [ECTextStyle textStyleWithName:@"String" 
                                                         font:[UIFont fontWithName:@"Courier New" size:16.0]
                                                        color:[UIColor orangeColor]];
    ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" 
                                                          font:[UIFont fontWithName:@"Courier New" size:16.0]
                                                         color:[UIColor blueColor]];
    [self.codeView setTextStyle:stringStyle toTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 9}]];
    [self.codeView setTextStyles:[NSArray arrayWithObjects:
                                  keywordStyle, 
                                  keywordStyle, nil] 
                    toTextRanges:[NSArray arrayWithObjects:
                                  [ECTextRange textRangeWithRange:(NSRange){0, 3}],
                                  [ECTextRange textRangeWithRange:(NSRange){23, 6}], nil]];
    
    // Overlay test
    //    ECTextOverlayStyle *yellowMark = [ECTextOverlayStyle highlightTextOverlayStyleWithName:@"Yellow mark" 
    //                                                                                     color:[[UIColor yellowColor] colorWithAlphaComponent:0.5] 
    //                                                                          alternativeColor:nil 
    //                                                                              cornerRadius:1];
    //    ECTextOverlayStyle *errorMark = [ECTextOverlayStyle underlineTextOverlayStyleWithName:@"Error mark" 
    //                                                                                    color:[UIColor redColor] 
    //                                                                         alternativeColor:nil 
    //                                                                               waveRadius:1];
    //    diagnosticOverlayStyles_ = [[NSDictionary alloc] initWithObjectsAndKeys:yellowMark, @"Warning", errorMark, @"Error", nil];
    //    
    //    [self.codeView addTextOverlayStyle:yellowMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
    //    [self.codeView addTextOverlayStyle:errorMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
    
    self.codeView.text = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:nil];
    for (ECCodeToken *token in [self.codeUnit tokensInRange:NSMakeRange(0, [self.codeView.text length]) withCursors:YES])
    {
        switch (token.kind)
        {
            case ECCodeTokenKindKeyword:
                [self.codeView setTextStyle:[textStyles_ objectForKey:@"Keyword"] toTextRange:[ECTextRange textRangeWithRange:token.extent]];
                break;
            case ECCodeTokenKindComment:
                [self.codeView setTextStyle:[textStyles_ objectForKey:@"Comment"] toTextRange:[ECTextRange textRangeWithRange:token.extent]];
                break;
            case ECCodeTokenKindLiteral:
                [self.codeView setTextStyle:[textStyles_ objectForKey:@"Literal"] toTextRange:[ECTextRange textRangeWithRange:token.extent]];
                break;
            default:
                switch (token.cursor.kind)
            {
                case ECCodeCursorDeclaration:
                    [self.codeView setTextStyle:[textStyles_ objectForKey:@"Declaration"] toTextRange:[ECTextRange textRangeWithRange:token.extent]];
                    break;
                case ECCodeCursorReference:
                    [self.codeView setTextStyle:[textStyles_ objectForKey:@"Reference"] toTextRange:[ECTextRange textRangeWithRange:token.extent]];
                    break;
                case ECCodeCursorPreprocessing:
                    [self.codeView setTextStyle:[textStyles_ objectForKey:@"Preprocessing"] toTextRange:[ECTextRange textRangeWithRange:token.extent]];
                    break;
                default:
                    break;
            }
                break;
        }
    }
    [self.codeView sizeToFit];
    self.scrollView.contentSize = self.codeView.bounds.size;
    for (ECCodeDiagnostic *diagnostic in [self.codeUnit diagnostics])
    {
        //        switch (diagnostic.severity) {
        //            case ECCodeDiagnosticSeverityWarning:
        //                [self.codeView addTextOverlayStyle:[diagnosticOverlayStyles_ objectForKey:@"Warning"] forTextRange:[ECTextRange textRangeWithRange:(NSRange){diagnostic.offset, diagnostic.offset + 20}] alternative:NO];
        //                break;
        //                
        //            case ECCodeDiagnosticSeverityError:
        //            case ECCodeDiagnosticSeverityFatal:
        //                [self.codeView addTextOverlayStyle:[diagnosticOverlayStyles_ objectForKey:@"Error"] forTextRange:[ECTextRange textRangeWithRange:NSMakeRange(diagnostic.offset, diagnostic.offset + 20)] alternative:NO];
        //                break;
        //                
        //            default:
        //                break;
        //        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.scrollView = nil;
    self.codeView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)loadFile:(NSString *)file withCodeUnit:(ECCodeUnit *)codeUnit
{
    self.file = file;
    self.codeUnit = codeUnit;
}

@end
