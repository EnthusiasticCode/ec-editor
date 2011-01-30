//
//  ECCodeProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeProjectController.h"
#import "Index.h"
#import "ECClangCodeIndexer.h"
#import "ECCodeCompletionString.h"


@implementation ECCodeProjectController

@synthesize project;
@synthesize fileManager;
@synthesize codeView;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

@synthesize codeIndexers = _codeIndexers;

- (NSArray *)codeIndexers
{
    if (!_codeIndexers)
        _codeIndexers = [[NSArray alloc] init];
    return _codeIndexers;
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

- (void)awakeFromNib
{
    // viewDidLoad can be called multiple times without deallocating the view
    if (![self.codeIndexers count])
    {
        ECClangCodeIndexer *codeIndexer = [[ECClangCodeIndexer alloc] init];
        [self addCodeIndexer:codeIndexer];
        [codeIndexer release];
    }
}

- (void)dealloc
{
    [_codeIndexers release];
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
    for (id<ECCodeIndexer>codeIndexer in _codeIndexers)
    {
        [codeIndexer loadFile:file];
    }
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

- (void) addCodeIndexer:(id<ECCodeIndexer>)codeIndexer
{
    NSArray *oldCodeIndexers = _codeIndexers;
    _codeIndexers = [self.codeIndexers arrayByAddingObject:codeIndexer];
    [_codeIndexers retain];
    [oldCodeIndexers release];
}

- (void)showCompletions
{
    NSMutableArray *possibleCompletions = [[NSMutableArray alloc] init];
    for (id<ECCodeIndexer>codeIndexer in _codeIndexers)
    {
        [possibleCompletions addObjectsFromArray:[codeIndexer completionsWithSelection:self.codeView.selectedRange inString:self.codeView.text]];
    }
    NSMutableArray *completionLabels = [[NSMutableArray alloc] initWithCapacity:[possibleCompletions count]];
    for (ECCodeCompletionString *completion in possibleCompletions)
    {
        [completionLabels addObject:completion.label];
    }
    
    self.completionPopover.didSelectRow =
    ^ void (int row)
    {
        NSRange replacementRange = [[possibleCompletions objectAtIndex:row] replacementRange];
        NSString *replacementString = [[possibleCompletions objectAtIndex:row] string];
        self.codeView.text = [self.codeView.text stringByReplacingCharactersInRange:replacementRange withString:replacementString];
    };
    //    self.completionPopover.popoverRect = [self firstRectForRange:[self selectedRange]];
    self.completionPopover.strings = completionLabels;
    
    [completionLabels release];
    [possibleCompletions release];
}

@end
