//
//  ECCodeIndexerSpec.m
//  edit
//
//  Created by Uri Baghin on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextDocument.h"
#import "ECPersistentDocument.h"
#import "../../Kiwi/Kiwi.h"

SPEC_BEGIN(ECMobileAppKitSpec)

describe(@"An ECDocument", ^
{
    __block ECDocument *document;
    __block NSURL *fileURL;
    beforeAll(^
    {
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test"];
        fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
        [[NSData data] writeToURL:fileURL atomically:NO];
    });
    
    afterAll(^
    {
        [fileURL release];
    });
    
    beforeEach(^
    {
        document = [ECDocument alloc];
    });
    
    afterEach(^
    {
        [document release];
    });
    
    it(@"doesn't read files", ^
    {
        [[document should] receive:@selector(readFromData:ofType:error:)];
        [document stub:@selector(readFromData:ofType:error:)];
        [document readFromURL:fileURL ofType:nil error:NULL];
    });
    
    it(@"doesn't write files", ^
    {
        [[document should] receive:@selector(dataOfType:error:)];
        [document stub:@selector(dataOfType:error:)];
        [document writeToURL:fileURL ofType:nil error:NULL];
    });
});

describe(@"An ECTextDocument", ^
{
    __block ECTextDocument *document;
    __block NSURL *fileURLA;
    __block NSURL *fileURLB;
    beforeAll(^
    {
        NSString *filePathA = [NSTemporaryDirectory() stringByAppendingPathComponent:@"a.txt"];
        NSString *filePathB = [NSTemporaryDirectory() stringByAppendingPathComponent:@"b.txt"];
        fileURLA = [[NSURL alloc] initFileURLWithPath:filePathA];
        fileURLB = [[NSURL alloc] initFileURLWithPath:filePathB];
        [[NSData dataWithBytes:"1234567890" length:10] writeToURL:fileURLA atomically:NO];
    });
    
    afterAll(^
    {
        [fileURLA release];
        [fileURLB release];
    });
    
    beforeEach(^
    {
        document = [ECTextDocument alloc];
    });
    
    afterEach(^
    {
        [document release];
    });
    
//    it(@"initializes with an existing file", ^
//    {
//        document = [document initWithContentsOfURL:fileURLA ofType:@"public.plain-text" error:NULL];
//        [[document.text should] equal:@"1234567890"];
//    });
    
    it(@"initializes without a file", ^
    {
        document = [document initWithType:@"public.plain-text" error:NULL];
        [[document.text should] equal:@""];
    });
    
//    it(@"saves changes to file", ^
//    {
//        document = [document initWithContentsOfURL:fileURLB ofType:@"public.plain-text" error:NULL];
//        document.text = @"testing";
//        [document writeToURL:fileURLB ofType:@"public.plain-text" error:NULL];
//        [[[NSString stringWithUTF8String:[[NSData dataWithContentsOfURL:fileURLB] bytes]] should] equal:@"testing"];
//    });
});

describe(@"An ECPersistentDocument", ^
{
    __block ECPersistentDocument *document;
    __block NSURL *fileURL;
    beforeAll(^
    {
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"pd.xml"];
        fileURL = [[NSURL alloc] initFileURLWithPath:filePath];
        [[NSData data] writeToURL:fileURL atomically:NO];
    });
    
    afterAll(^
    {
        [fileURL release];
    });
    
    beforeEach(^
    {
        document = [ECTextDocument alloc];
    });
    
    afterEach(^
    {
        [document release];
    });
});

SPEC_END
