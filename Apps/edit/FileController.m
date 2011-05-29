//
//  FileViewController.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileController.h"

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"
#import "ECCodeToken.h"
#import "ECCodeCursor.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"

#import "ECCodeStringDataSource.h"
#import "ECTextStyle.h"
#import "ECTextRange.h"

#import "ECPatriciaTrie.h"

#import "CompletionController.h"

@interface FileController ()
@property (nonatomic, retain) ECCodeUnit *unit;
@end

@implementation FileController

@synthesize codeView;
@synthesize file;
@synthesize completionButton;
@synthesize popoverController;
@synthesize completionController;

@synthesize unit;

- (void)dealloc
{
    self.file = nil;
    self.unit = nil;
    [completionButton release];
    [popoverController release];
    [completionController release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.codeView.text = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:nil];
    ECCodeStringDataSource *codeSource = (ECCodeStringDataSource *)self.codeView.datasource;
    ECCodeIndex *index = [[[ECCodeIndex alloc] init] autorelease];
    self.unit = [index unitForFile:self.file];
    ECTextStyle *keywordStyle = [ECTextStyle textStyleWithName:@"Keyword" font:nil color:[UIColor blueColor]];
    ECTextStyle *commentStyle = [ECTextStyle textStyleWithName:@"Comment" font:nil color:[UIColor greenColor]];
    ECTextStyle *referenceStyle = [ECTextStyle textStyleWithName:@"Reference" font:nil color:[UIColor purpleColor]];
    ECTextStyle *literalStyle = [ECTextStyle textStyleWithName:@"Literal" font:nil color:[UIColor redColor]];
    ECTextStyle *declarationStyle = [ECTextStyle textStyleWithName:@"Declaration" font:nil color:[UIColor brownColor]];
    ECTextStyle *preprocessingStyle = [ECTextStyle textStyleWithName:@"Preprocessing" font:nil color:[UIColor orangeColor]];
    for (ECCodeToken *token in [self.unit tokensWithCursors:YES])
    {
        switch (token.kind)
        {
            case ECCodeTokenKindKeyword:
                [codeSource addTextStyle:keywordStyle toStringRange:token.extent];
                break;
            case ECCodeTokenKindComment:
                [codeSource addTextStyle:commentStyle toStringRange:token.extent];
                break;
            case ECCodeTokenKindLiteral:
                [codeSource addTextStyle:literalStyle toStringRange:token.extent];
                break;
            default:
                if (token.cursor.kind >= ECCodeCursorKindFirstDecl && token.cursor.kind <= ECCodeCursorKindLastDecl)
                    [codeSource addTextStyle:declarationStyle toStringRange:token.extent];
                else if (token.cursor.kind >= ECCodeCursorKindFirstRef && token.cursor.kind <= ECCodeCursorKindLastRef)
                    [codeSource addTextStyle:referenceStyle toStringRange:token.extent];
                else if (token.cursor.kind >= ECCodeCursorKindFirstPreprocessing && token.cursor.kind <= ECCodeCursorKindLastPreprocessing)
                    [codeSource addTextStyle:preprocessingStyle toStringRange:token.extent];
                break;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [codeView setNeedsLayout];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.completionButton;
    self.popoverController = [[[UIPopoverController alloc] initWithContentViewController:self.completionController] autorelease];
    self.popoverController.popoverContentSize = CGSizeMake(800.0, 500.0);
    self.completionController.resultSelectedBlock = ^(ECCodeCompletionResult *result) {
        [self.codeView insertText:[result.completionString typedText]];
        [self.popoverController dismissPopoverAnimated:YES];
    };
}

- (void)viewDidUnload
{
    [self setCompletionButton:nil];
    [self setPopoverController:nil];
    [self setCompletionController:nil];
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

- (void)loadFile:(NSString *)aFile
{
    self.file = aFile;
    self.title = [aFile lastPathComponent];
}

- (IBAction)complete:(id)sender {
    NSArray *array = [self.unit completionsWithSelection:[(ECTextRange *)[self.codeView selectedTextRange] range]];
    ECPatriciaTrie *trie = [[[ECPatriciaTrie alloc] init] autorelease];
    for (ECCodeCompletionResult *result in array)
        [trie setObject:result forKey:[result.completionString typedText]];
    self.completionController.results = trie;
    self.completionController.match = @"";
    [self.popoverController presentPopoverFromBarButtonItem:self.completionButton permittedArrowDirections:0 animated:YES];
}

@end
