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


@implementation ECCodeProjectController

@synthesize project;
@synthesize codeView;
@synthesize codeIndexer;
@synthesize possibleCompletions = _possibleCompletions;

- (NSMutableArray *)possibleCompletions
{
    if (!_possibleCompletions)
        _possibleCompletions = [[NSMutableArray alloc] init];
    return _possibleCompletions;
}

@synthesize fileManager;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

@synthesize completionPopover = _completionPopover;

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
    self.codeView = nil;
    self.codeIndexer = nil;
    self.completionPopover = nil;
    [project release];
    [fileManager release];
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
    if (project) return;
    project = [[ECCodeProject alloc] initWithRootDirectory:rootDirectory name:name];
}

- (void)loadFile:(NSString *)file
{
    [self.codeIndexer loadFile:file];
    self.codeView.text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
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
    [self showCompletions];
}

- (void)applyCompletion:(int)completionIndex
{
    NSString *completionText = [[[self.possibleCompletions objectAtIndex:completionIndex] firstChunk] string];
    self.codeView.text = [self.codeView.text stringByReplacingCharactersInRange:[self.codeIndexer completionRangeWithSelection:self.codeView.selectedRange inString:self.codeView.text] withString:[completionText stringByAppendingString:@" "]];
}

- (void)showCompletions
{
    [self.possibleCompletions removeAllObjects];
    [self.possibleCompletions addObjectsFromArray:[self.codeIndexer completionsWithSelection:self.codeView.selectedRange inString:self.codeView.text]];
    NSMutableArray *completionLabels = [[NSMutableArray alloc] initWithCapacity:[self.possibleCompletions count]];
    for (ECCompletionString *completion in self.possibleCompletions)
    {
        [completionLabels addObject:[[completion firstChunk] string]];
    }
    
    self.completionPopover.didSelectRow =
    ^ void (int row)
    {
        [self applyCompletion:row];
    };
    //    self.completionPopover.popoverRect = [self firstRectForRange:[self selectedRange]];
    self.completionPopover.strings = completionLabels;
    
    [completionLabels release];
}

@end
