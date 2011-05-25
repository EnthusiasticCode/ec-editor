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

@interface FileController ()
@property (nonatomic, retain) ECCodeUnit *unit;
@end

@implementation FileController

@synthesize codeView;
@synthesize file;
@synthesize completionButton;

@synthesize unit;

- (void)dealloc
{
    self.file = nil;
    self.unit = nil;
    [completionButton release];
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
                switch (token.cursor.kind)
                {
                    case ECCodeCursorDeclaration:
                        [codeSource addTextStyle:declarationStyle toStringRange:token.extent];
                        break;
                    case ECCodeCursorReference:
                        [codeSource addTextStyle:referenceStyle toStringRange:token.extent];
                        break;
                    case ECCodeCursorPreprocessing:
                        [codeSource addTextStyle:preprocessingStyle toStringRange:token.extent];
                        break;
                    default:
                        break;
                }
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
    self.navigationItem.rightBarButtonItem = self.completionButton;
}

- (void)viewDidUnload
{
    [self setCompletionButton:nil];
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
    for (ECCodeCompletionString *string in array)
        [trie setObject:string forKey:[string firstChunk].string];
    NSArray *groups = [trie nodesForKeysStartingWithString:@"" options:ECPatriciaTrieEnumerationOptionsSkipNotEndOfWord | ECPatriciaTrieEnumerationOptionsStopAtShallowestMatch];
    for (ECPatriciaTrie *node in groups)
        NSLog(@"%@ -> %@", node, node.key);
}

@end
