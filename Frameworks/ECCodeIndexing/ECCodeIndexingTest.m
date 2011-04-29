#import <GHUnitIOS/GHUnit.h>
#import "ECCodeIndex.h"
#import "ECCodeUnit.h"

@interface ECCodeIndexingTest : GHTestCase
{
    ECCodeIndex *codeIndex;
    ECCodeUnit *codeUnit;
    NSString *cFilePath;
    NSString *invalidFilePath;
}
@end

@implementation ECCodeIndexingTest

- (BOOL)shouldRunOnMainThread
{
    return NO;
}

- (void)setUpClass
{
    cFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"main.c"] retain];
    invalidFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"thisfiledoesnotexist"] retain];
    [@"#include <stdio.h>\n int main(int argc, char **argv)\n { printf(\"hello world\"); }" writeToFile:cFilePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

- (void)tearDownClass
{
    [cFilePath release];
    [invalidFilePath release];
}

- (void)setUp
{
    codeIndex = [[ECCodeIndex alloc] init];
}

- (void)tearDown
{
    [codeIndex release];
}

- (void)testLanguageToExtensionMapping
{
    GHAssertEqualStrings([codeIndex languageForExtension:@"m"], @"Objective C", nil);
    GHAssertEquals([[codeIndex languageToExtensionMap] count], (NSUInteger)4, nil);
}

- (void)testExtensionToLanguageMapping
{
    GHAssertEqualStrings([codeIndex extensionForLanguage:@"Objective C"], @"m", nil);
    GHAssertEquals([[codeIndex extensionToLanguageMap] count], (NSUInteger)5, nil);
}

- (void)testCodeUnitFromInvalidFile
{
    GHAssertNil([codeIndex unitForFile:invalidFilePath], nil);
}

- (void)testCodeUnitFromFile
{
    GHAssertNotNil(codeUnit = [codeIndex unitForFile:cFilePath], nil);
    GHAssertEqualStrings(codeUnit.language, @"C", nil);
    GHAssertEquals([[codeUnit diagnostics] count], (NSUInteger)0, nil); // Currently fails because code indexer can't find stdio header.
    GHAssertEquals([[codeUnit tokensWithCursors:NO] count], (NSUInteger)25, nil);
    GHAssertEquals([[codeUnit tokensInRange:NSMakeRange(8, 10) withCursors:NO] count], (NSUInteger)6, nil);
    GHAssertGreaterThan([[codeUnit completionsWithSelection:NSMakeRange(57, 0)] count], (NSUInteger)400, nil);
}

@end
