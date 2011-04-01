//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectController.h"
#import "Project.h"
#import <ECUIKit/ECCodeView.h>
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECCodeIndexing/ECCodeCompletionString.h>
#import <ECCodeIndexing/ECCodeDiagnostic.h>
#import <ECCodeIndexing/ECCodeToken.h>
#import <ECCodeIndexing/ECCodeCursor.h>


@implementation ProjectController

@synthesize project = _project;
@synthesize codeView = _codeView;
@synthesize codeIndexer = _codeIndexer;
@synthesize codeScrollView = _codeScrollView;
@synthesize fileManager = _fileManager;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    [textStyles_ release];
    [diagnosticOverlayStyles_ release];
    self.project = nil;
    self.codeView = nil;
    self.codeIndexer = nil;
    [_codeScrollView release];
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
    //    NSDictionary *keywordStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor blueColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    //    NSDictionary *commentStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor greenColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    //    NSDictionary *referenceStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor purpleColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    //    NSDictionary *literalStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor redColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    //    NSDictionary *declarationStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor magentaColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    //    NSDictionary *preprocessingStyle = [NSDictionary dictionaryWithObjectsAndKeys:(id)[[UIColor orangeColor] CGColor], (id)kCTForegroundColorAttributeName, nil];
    //    ECCodeView *codeView = (ECCodeView *) rootController.codeView;
    //    [codeView setAttributes:keywordStyle forStyleNamed:ECCodeStyleKeywordName];
    //    [codeView setAttributes:commentStyle forStyleNamed:ECCodeStyleCommentName];
    //    [codeView setAttributes:referenceStyle forStyleNamed:ECCodeStyleIdentifierName];
    //    [codeView setAttributes:literalStyle forStyleNamed:ECCodeStyleLiteralName];
    //    [codeView setAttributes:declarationStyle forStyleNamed:ECCodeStyleDeclarationName];
    //    [codeView setAttributes:preprocessingStyle forStyleNamed:ECCodeStylePreprocessingName];
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
    ECTextOverlayStyle *yellowMark = [ECTextOverlayStyle highlightTextOverlayStyleWithName:@"Yellow mark" 
                                                                                     color:[[UIColor yellowColor] colorWithAlphaComponent:0.5] 
                                                                              cornerRadius:0];
    ECTextOverlayStyle *errorMark = [ECTextOverlayStyle underlineTextOverlayStyleWithName:@"Error mark" 
                                                                                    color:[UIColor redColor] 
                                                                               waveRadius:1];
    diagnosticOverlayStyles_ = [[NSDictionary alloc] initWithObjectsAndKeys:yellowMark, @"Warning", errorMark, @"Error", nil];
//    
//    [self.codeView addTextOverlayStyle:yellowMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
//    [self.codeView addTextOverlayStyle:errorMark forTextRange:[ECTextRange textRangeWithRange:(NSRange){9, 15}] alternative:NO];
    
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
    self.project = [Project projectWithRootDirectory:rootDirectory];
    self.codeIndexer = [[[ECCodeIndex alloc] init] autorelease];
}

- (void)loadFile:(NSURL *)fileURL
{
    self.codeView.text = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    ECCodeUnit *codeUnit = [self.codeIndexer unitForURL:fileURL];
    for (ECCodeToken *token in [codeUnit tokensInRange:NSMakeRange(0, [self.codeView.text length]) withCursors:YES])
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
    CGSize codeViewSize = self.codeView.bounds.size;
    self.codeScrollView.contentSize = codeViewSize;
    
    for (ECCodeDiagnostic *diagnostic in [codeUnit diagnostics])
    {
        NSLog(@"%@", diagnostic);
        NSLog(@"%d", diagnostic.offset);
        switch (diagnostic.severity) {
            case ECCodeDiagnosticSeverityWarning:
                [self.codeView addTextOverlayLayerWithStyle:[diagnosticOverlayStyles_ objectForKey:@"Warning"] forTextRange:[ECTextRange textRangeWithRange:(NSRange){diagnostic.offset, diagnostic.offset + 20}]];
                break;
                
            case ECCodeDiagnosticSeverityError:
                [self.codeView addTextOverlayLayerWithStyle:[diagnosticOverlayStyles_ objectForKey:@"Error"] forTextRange:[ECTextRange textRangeWithRange:NSMakeRange(diagnostic.offset, diagnostic.offset + 20)]];
                break;
                
            default:
                break;
        }
    }
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
