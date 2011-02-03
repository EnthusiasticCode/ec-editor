//
//  ECCodeProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeProjectController.h"
#import "ECCodeProject.h"
#import "ECCodeIndexer.h"
#import "ECPopoverTableController.h"
#import "ECCompletionString.h"
#import "ECDiagnostic.h"
#import "ECToken.h"


@implementation ECCodeProjectController

@synthesize project = _project;
@synthesize codeView = _codeView;
@synthesize text = _text;
@synthesize codeIndexer = _codeIndexer;
@synthesize fileManager = _fileManager;
@synthesize completionPopover = _completionPopover;

- (NSString *)text
{
    if (!self.codeView)
        return @"";
    return self.codeView.text;
}

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}


- (ECPopoverTableController *)completionPopover
{
    if (!_completionPopover)
    {
        _completionPopover = [[ECPopoverTableController alloc] init];
        _completionPopover.viewToPresentIn = self.codeView;
    }   
    return _completionPopover;
}

- (void)dealloc
{
    self.project = nil;
    self.codeView = nil;
    self.codeIndexer = nil;
    self.completionPopover = nil;
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
    self.project = [[ECCodeProject alloc] initWithRootDirectory:rootDirectory name:name];
}

- (void)loadFile:(NSString *)file
{
    self.codeView.text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    ECCodeIndexer *codeIndexer = [[ECCodeIndexer alloc] init];
    codeIndexer.source = file;
    codeIndexer.delegate = self;
    codeIndexer.delegateTextKey = @"text";
    for (ECDiagnostic *diagnostic in codeIndexer.diagnostics)
        NSLog(@"%@", diagnostic.spelling);
    for (ECToken *token in codeIndexer.tokens)
        NSLog(@"%@", token.spelling);
    self.codeIndexer = codeIndexer;
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

- (void)applyCompletion:(NSString *)completion
{
    self.codeView.text = [self.codeView.text stringByReplacingCharactersInRange:[self.codeIndexer completionRangeWithSelection:self.codeView.selectedRange] withString:[completion stringByAppendingString:@" "]];
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
