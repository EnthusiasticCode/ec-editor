//
//  ECCodeProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeProjectController.h"
#import "Index.h"


@implementation ECCodeProjectController

@synthesize project;
@synthesize fileManager;
@synthesize codeView;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)dealloc
{
    [project release];
    [fileManager release];
    [super dealloc];
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
    self.codeView.attributedText = [[NSAttributedString alloc] initWithString:fileContents attributes:nil];
    CXTranslationUnit TranslationUnit = clang_parseTranslationUnit(self.project.Index, [filePath cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, 0, 0, CXTranslationUnit_None);
    int numDiagnostics = clang_getNumDiagnostics(TranslationUnit);
    for (int i = 0; i < numDiagnostics; i++)
    {
        CXDiagnostic Diagnostic = clang_getDiagnostic(TranslationUnit, i);
        CXString String = clang_formatDiagnostic(Diagnostic, clang_defaultDiagnosticDisplayOptions());
        NSLog(@"%s", clang_getCString(String));
        clang_disposeString(String);
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

@end
