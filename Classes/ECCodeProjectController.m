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
#import "ECCodeCompletion.h"


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
    NSString *fileName = [[self contentsOfRootDirectory] objectAtIndex:indexPath.row];
    NSString *filePath = [self.project.rootDirectory stringByAppendingPathComponent:fileName];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    int parameter_count = 10;
    const char const *parameters[] = {"-ObjC", "-nostdinc", "-nobuiltininc", "-I/Xcode4//usr/lib/clang/2.0/include", "-I/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/usr/include", "-F/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/System/Library/Frameworks", "-isysroot=/Xcode4/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator4.2.sdk/", "-DTARGET_OS_IPHONE=1", "-UTARGET_OS_MAC", "-miphoneos-version-min=4.2"};
    self.codeView.text = fileContents;
    CXTranslationUnit TranslationUnit = clang_parseTranslationUnit(self.project.Index, [filePath cStringUsingEncoding:NSUTF8StringEncoding], parameters, parameter_count, 0, 0, CXTranslationUnit_None);
    int numDiagnostics = clang_getNumDiagnostics(TranslationUnit);
    for (int i = 0; i < numDiagnostics; i++)
    {
        CXDiagnostic Diagnostic = clang_getDiagnostic(TranslationUnit, i);
        CXString String = clang_formatDiagnostic(Diagnostic, clang_defaultDiagnosticDisplayOptions());
        NSLog(@"%s", clang_getCString(String));
        clang_disposeString(String);
        clang_disposeDiagnostic(Diagnostic);
    }
    clang_disposeTranslationUnit(TranslationUnit);
}

- (void)loadProject:(NSString *)name from:(NSString *)rootDirectory
{
    if (project) return;
    project = [[ECCodeProject alloc] initWithRootDirectory:rootDirectory name:name];
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
    for (ECCodeCompletion *completion in possibleCompletions)
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
