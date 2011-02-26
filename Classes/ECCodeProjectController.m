//
//  ECCodeProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeProjectController.h"
#import "ECCodeProject.h"
#import "ECCodeView.h"
#import <ECCodeIndexing/ECCodeIndexer.h>
#import <ECCodeIndexing/ECCompletionString.h>
#import <ECCodeIndexing/ECDiagnostic.h>
#import <ECCodeIndexing/ECToken.h>


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
    NSString *file = [self.project.rootDirectory stringByAppendingPathComponent:[[self contentsOfRootDirectory] objectAtIndex:indexPath.row]];
    [self loadFile:file];
}

- (void)loadProject:(NSString *)name from:(NSString *)rootDirectory
{
    self.project = [[ECCodeProject alloc] initWithRootDirectory:rootDirectory];
}

- (void)loadFile:(NSString *)file
{
    self.codeView.text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    ECCodeIndexer *codeIndexer = [[ECCodeIndexer alloc] initWithSource:[NSURL fileURLWithPath:file]];
    self.codeIndexer = codeIndexer;
    for (ECToken *token in [self.codeIndexer tokens])
    {
        NSLog(@"%d : %@", token.kind, token.spelling);
        switch (token.kind)
        {
            case ECTokenKindKeyword:
                [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleKeywordName toRange:[token.extent range]];
                break;
            case ECtokenKindComment:
                [(ECCodeView *)self.codeView setStyleNamed:ECCodeStyleKeywordName toRange:[token.extent range]];
                break;
            default:
                break;
        }
    }
    [codeIndexer release];
}

- (NSArray *)contentsOfRootDirectory
{
    return [self.fileManager contentsOfDirectoryAtPath:self.project.rootDirectory error:NULL];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self showCompletions];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (!textView.text)
        return;
    [self showCompletions];
}

- (NSString *)indexedTextBuffer
{
    return self.codeView.text;
}

- (NSRange)indexedTextSelection
{
    return self.codeView.selectedRange;
}

- (void)applyCompletion:(NSString *)completion
{
//    self.codeView.text = [self.codeView.text stringByReplacingCharactersInRange:[self.codeIndexer completionRange] withString:[completion stringByAppendingString:@" "]];
}

- (void)showCompletions
{
//    NSMutableArray *completionLabels = [[NSMutableArray alloc] initWithCapacity:[self.possibleCompletions count]];
//    for (ECCompletionString *completion in self.possibleCompletions)
//    {
//        [completionLabels addObject:[[completion firstChunk] string]];
//    }
//    
//    self.completionPopover.didSelectRow =
//    ^ void (int row)
//    {
//        [self applyCompletion:row];
//    };
//    //    self.completionPopover.popoverRect = [self firstRectForRange:[self selectedRange]];
//    self.completionPopover.strings = completionLabels;
//    
//    [completionLabels release];
}

@end
