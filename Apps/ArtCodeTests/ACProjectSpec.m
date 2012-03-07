//
//  ACProjectSpec.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi.h>
#import "ACProject.h"

SPEC_BEGIN(ACProjectSpec)

describe(@"A non-existing ACProject", ^{
    NSURL *projectURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"testproject.acproj"]];
    __block ACProject *project = nil;
    
    beforeEach(^{
        [[[NSFileManager alloc] init] removeItemAtURL:projectURL error:NULL];
        project = [[ACProject alloc] initWithFileURL:projectURL];
    });
    
    it(@"can be initialized", ^{
        [[project should] beNonNil];
    });
    
    it(@"can be saved", ^{
        __block BOOL saved;
        [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            saved = success;
        }];
        [[theValue(saved) should] beYes];
    });
    
});

describe(@"An existing ACProject", ^{
    NSURL *projectURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"testproject.acproj"]];
    __block ACProject *project = nil;
    
    beforeEach(^{
        [[[NSFileManager alloc] init] removeItemAtURL:projectURL error:NULL];
        project = [[ACProject alloc] initWithFileURL:projectURL];
        [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
    });
    
    it(@"can be opened", ^{
        [project openWithCompletionHandler:nil];
        [[theValue([project documentState]) shouldEventuallyBeforeTimingOutAfter(2)] equal:theValue(UIDocumentStateNormal)];
    });

    it(@"can be opened and then closed", ^{
        [project openWithCompletionHandler:nil];
        [[theValue([project documentState]) shouldEventuallyBeforeTimingOutAfter(2)] equal:theValue(UIDocumentStateNormal)];
        [project closeWithCompletionHandler:nil];
        [[theValue([project documentState]) shouldEventuallyBeforeTimingOutAfter(2)] equal:theValue(UIDocumentStateClosed)];
    });

});

SPEC_END


