//
//  FileViewController.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileController.h"

#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeDiagnostic.h>
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeCursor.h>

#import <ECUIKit/ECCodeView.h>
#import <ECUIKit/ECCodeStringDataSource.h>

@interface FileController ()
{
@private
    NSDictionary *textStyles_;
    NSDictionary *diagnosticOverlayStyles_;
}
@end

@implementation FileController

@synthesize codeView = codeView_;
@synthesize file = file_;
@synthesize codeUnit = codeUnit_;

- (void)dealloc
{
    [textStyles_ release];
    [diagnosticOverlayStyles_ release];
    self.codeView = nil;
    self.file = nil;
    self.codeUnit = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    NSMutableDictionary *textStyles = [NSMutableDictionary dictionary];
//    UIFont *font = [UIFont fontWithName:@"Courier New" size:16.0];
//    [textStyles setObject:[ECTextStyle textStyleWithName:@"Keyword" font:font color:[UIColor blueColor]] forKey:@"Keyword"];
//    [textStyles setObject:[ECTextStyle textStyleWithName:@"Comment" font:font color:[UIColor greenColor]] forKey:@"Comment"];
//    [textStyles setObject:[ECTextStyle textStyleWithName:@"Reference" font:font color:[UIColor purpleColor]] forKey:@"Reference"];
//    [textStyles setObject:[ECTextStyle textStyleWithName:@"Literal" font:font color:[UIColor redColor]] forKey:@"Literal"];
//    [textStyles setObject:[ECTextStyle textStyleWithName:@"Declaration" font:font color:[UIColor brownColor]] forKey:@"Declaration"];
//    [textStyles setObject:[ECTextStyle textStyleWithName:@"Preprocessing" font:font color:[UIColor orangeColor]] forKey:@"Preprocessing"];
//    textStyles_ = [textStyles copy];
//    
//    ECTextStyle *stringStyle = [ECTextStyle textStyleWithName:@"String" 
//                                                         font:[UIFont fontWithName:@"Courier New" size:16.0]
//                                                        color:[UIColor orangeColor]];
//    ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" 
//                                                          font:[UIFont fontWithName:@"Courier New" size:16.0]
//                                                         color:[UIColor blueColor]];
//    [self.codeView setTextStyle:stringStyle toTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 9}]];
//    [self.codeView setTextStyles:[NSArray arrayWithObjects:
//                                  keywordStyle, 
//                                  keywordStyle, nil] 
//                    toTextRanges:[NSArray arrayWithObjects:
//                                  [ECTextRange textRangeWithRange:(NSRange){0, 3}],
//                                  [ECTextRange textRangeWithRange:(NSRange){23, 6}], nil]];
    
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
}

- (void)viewWillAppear:(BOOL)animated
{
    self.codeView.text = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:nil];
    
    ECCodeStringDataSource *codeSource = (ECCodeStringDataSource *)self.codeView.datasource;
    
    for (ECCodeToken *token in [self.codeUnit tokensInRange:NSMakeRange(0, [self.codeView.text length]) withCursors:YES])
    {
        switch (token.kind)
        {
            case ECCodeTokenKindKeyword:
                [codeSource addTextStyle:[textStyles_ objectForKey:@"Keyword"] toStringRange:token.extent];
                break;
            case ECCodeTokenKindComment:
                [codeSource addTextStyle:[textStyles_ objectForKey:@"Comment"] toStringRange:token.extent];
                break;
            case ECCodeTokenKindLiteral:
                [codeSource addTextStyle:[textStyles_ objectForKey:@"Literal"] toStringRange:token.extent];
                break;
            default:
                switch (token.cursor.kind)
            {
                case ECCodeCursorDeclaration:
                    [codeSource addTextStyle:[textStyles_ objectForKey:@"Declaration"] toStringRange:token.extent];
                    break;
                case ECCodeCursorReference:
                    [codeSource addTextStyle:[textStyles_ objectForKey:@"Reference"] toStringRange:token.extent];
                    break;
                case ECCodeCursorPreprocessing:
                    [codeSource addTextStyle:[textStyles_ objectForKey:@"Preprocessing"] toStringRange:token.extent];
                    break;
                default:
                    break;
            }
                break;
        }
    }

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
    self.title = [file lastPathComponent];
}

@end
