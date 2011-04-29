#import <GHUnitIOS/GHUnit.h>
#import "../edit/Project.h"

@interface editTests : GHTestCase
{
    Project *project;
    NSString *filePathA;
    NSString *filePathB;
}
@end

@implementation editTests

//- (BOOL)shouldRunOnMainThread
//{
//    return NO;
//}
//
//- (void)setUpClass
//{
//    filePathA = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"a.txt"] retain];
//    filePathB = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"b.txt"] retain];
//    [@"1234567890" writeToFile:filePathA atomically:NO encoding:NSUTF8StringEncoding error:NULL];
//}
//
//- (void)tearDownClass
//{
//    [filePathA release];
//    [filePathB release];
//}
//
- (void)setUp
{
    project = [[Project alloc] init];
}

- (void)tearDown
{
    [project release];
}

- (void)emptyProjectTest
{
    
}

@end
