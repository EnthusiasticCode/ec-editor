//
//  ECCodeProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeProjectController.h"
#import "ECCodeProject.h"
#import <ECUIKit/ECCodeView.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeDiagnostic.h>
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeCursor.h>


@implementation ECCodeProjectController

@synthesize project = _project;
@synthesize codeView = _codeView;
@synthesize codeIndexer = _codeIndexer;
@synthesize fileManager = _fileManager;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    self.project = nil;
    self.codeView = nil;
    self.codeIndexer = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *file = [tableView dequeueReusableCellWithIdentifier:@"File"];
    if (!file)
    {
        file = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"File"] autorelease];
    }
    file.textLabel.text = [[self contentsOfRootDirectory] objectAtIndex:(indexPath.row)];
    return file;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self contentsOfRootDirectory] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *file = [NSURL fileURLWithPath:[[self.project.rootDirectory path] stringByAppendingPathComponent:[[self contentsOfRootDirectory] objectAtIndex:indexPath.row]]];
    [self loadFile:file];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.codeView.text = @"int main(arguments)\n{\n\treturn 0;\n}";
    
    // Styles test
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
    ECTextOverlayStyle *yellowMark = [ECTextOverlayStyle highlightTextOverlayStyleWithName:@"Yellow mark" 
                                                                                     color:[[UIColor yellowColor] colorWithAlphaComponent:0.5] 
                                                                          alternativeColor:nil 
                                                                              cornerRadius:1];
    ECTextOverlayStyle *errorMark = [ECTextOverlayStyle underlineTextOverlayStyleWithName:@"Error mark" 
                                                                                    color:[UIColor redColor] 
                                                                         alternativeColor:nil 
                                                                               waveRadius:1];
    [self.codeView addTextOverlayStyle:yellowMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
    [self.codeView addTextOverlayStyle:errorMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
    
    // Edit tests
    
    // Focus recognizer
    focusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureFocus:)];
    [self.codeView addGestureRecognizer:focusRecognizer];
    
    //    // Scroll view
    //    [codeScrollView setMinimumZoomScale:1.0];
    //    [codeScrollView setMaximumZoomScale:1.0];
    //    codeScrollView.contentSize = CGSizeMake(100, 3000);
    //    
    //    codeScrollView.marks.lineCount = 100;
    //    NSIndexSet *mlines = [NSIndexSet indexSetWithIndexesInRange:(NSRange){20,10}];
    //    [codeScrollView.marks addMarksWithColor:[UIColor blueColor] forLines:mlines];
}

- (void)loadProjectFromRootDirectory:(NSURL *)rootDirectory
{
    self.project = [ECCodeProject projectWithRootDirectory:rootDirectory];
    self.codeIndexer = [[[ECCodeIndex alloc] init] autorelease];
}

- (void)loadFile:(NSURL *)fileURL
{
    self.codeView.text = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
//    for (ECCodeToken *token in [[self.codeIndexer unitForURL:fileURL] tokensInRange:NSMakeRange(0, [self.codeView.text length]) withCursors:YES])
//    {
//        switch (token.kind)
//        {
//            case ECCodeTokenKindKeyword:
//                [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleKeywordName toRange:token.extent];
//                break;
//            case ECCodeTokenKindComment:
//                [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleCommentName toRange:token.extent];
//                break;
//            case ECCodeTokenKindLiteral:
//                [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleLiteralName toRange:token.extent];
//                break;
//            default:
//                switch (token.cursor.kind)
//                {
//                    case ECCodeCursorDeclaration:
//                        [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleDeclarationName toRange:token.extent];
//                        break;
//                    case ECCodeCursorReference:
//                        [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleReferenceName toRange:token.extent];
//                        break;
//                    case ECCodeCursorPreprocessing:
//                        [(ECCodeView *)self.codeView setStyleNamed:ECCodeStylePreprocessingName toRange:token.extent];
//                        break;
//                    default:
//                        break;
//                }
//                break;
//        }
//    }
    [self.codeView setNeedsLayout];
}

- (NSArray *)contentsOfRootDirectory
{
    return [self.fileManager contentsOfDirectoryAtPath:[self.project.rootDirectory path] error:NULL];
}

- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer
{
    if ([[recognizer view] canBecomeFirstResponder])
        recognizer.enabled = ![[recognizer view] becomeFirstResponder];
}

@end
