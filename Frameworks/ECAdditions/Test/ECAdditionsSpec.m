//
//  ECCodeIndexerSpec.m
//  edit
//
//  Created by Uri Baghin on 2/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSURL+ECAdditions.h"
#import "../../Kiwi/Kiwi.h"

SPEC_BEGIN(ECAdditionsSpec)

describe(@"An NSURL with additions", ^
{
    it(@"checks a nonexistent file", ^
    {
        NSURL *nonexistentFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"thisfiledoesnotexist"]];
        [[theValue([nonexistentFileURL isFileURLAndExists]) should] beNo];
    });
    
    it(@"checks an existent file", ^
    {
        NSURL *existentFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"thisfileexists"]];
        [[NSData data] writeToURL:existentFile atomically:NO];
        [[theValue([existentFile isFileURLAndExists]) should] beYes];
    });
    
    it(@"checks a non-file URL", ^
    {
        NSURL *nonFileURL = [NSURL URLWithString:@"http://www.google.com"];
        [[theValue([nonFileURL isFileURLAndExists]) should] beNo];
    });
});

SPEC_END
