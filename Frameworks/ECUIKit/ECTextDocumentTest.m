#import <GHUnitIOS/GHUnit.h>
#import <ECUIKit/ECTextDocument.h>

@interface ECTextDocumentTest : GHTestCase
{
    ECTextDocument *document;
    NSString *filePathA;
    NSString *filePathB;
}
@end

@implementation ECTextDocumentTest

- (BOOL)shouldRunOnMainThread
{
    return NO;
}

- (void)setUpClass
{
    filePathA = [NSTemporaryDirectory() stringByAppendingPathComponent:@"a.txt"];
    filePathB = [NSTemporaryDirectory() stringByAppendingPathComponent:@"b.txt"];
    [@"1234567890" writeToFile:filePathA atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

- (void)tearDownClass
{
    [filePathA release];
    [filePathB release];
}

- (void)setUp
{
    document = [[ECTextDocument alloc] init];
}

- (void)tearDown
{
    [document release];
}  

- (void)testReading
{
    [document readFromPath:filePathA error:NULL];
    GHAssertEqualStrings(document.text, @"1234567890", nil);
}

- (void)testNew
{
    GHAssertEqualStrings(document.text, @"", nil);
}

- (void)testWriting
{
    document.text = @"Testing";
    [document writeToPath:filePathB error:NULL];
    GHAssertEqualStrings([NSString stringWithContentsOfFile:filePathB encoding:NSUTF8StringEncoding error:NULL], @"Testing", nil);
}

@end
