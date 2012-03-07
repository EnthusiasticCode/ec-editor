//
//  ACProjectSpec.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi.h>
#import "ACProject.h"
#import "ACProjectFolder.h"

SPEC_BEGIN(ACProjectSpec)

describe(@"A non-existing ACProject", ^{
    
    context(@"with a valid URL", ^{

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
            [[theValue([project documentState]) should] equal:theValue(UIDocumentStateClosed)];
            __block BOOL saved = NO;
            [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                saved = success;
            }];
            [[expectFutureValue(theValue(saved)) shouldEventually] beYes];
            [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
            [[theValue([[[NSFileManager alloc] init] fileExistsAtPath:[projectURL path]]) should] beYes];
        });
        
        it(@"should not have a root folder", ^{
            [[project.rootFolder should] beNil];
        });
        
    });
    
    context(@"with an invalid URL", ^{
        
        it(@"should not be initialized", ^{
            NSURL *invalidProjectURL = [NSURL URLWithString:@"http://www.google.com"];
            [[theBlock(^{
                ACProject *project = [[ACProject alloc] initWithFileURL:invalidProjectURL];
                project = nil;
            }) should] raise];
        });
        
    });
    
});

describe(@"An existing ACProject", ^{
    NSURL *projectURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"testproject.acproj"]];
    __block ACProject *project = nil;
    
    beforeEach(^{
        [[[NSFileManager alloc] init] removeItemAtURL:projectURL error:NULL];
        ACProject *newProject = [[ACProject alloc] initWithFileURL:projectURL];
        [newProject saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
        [newProject closeWithCompletionHandler:nil];
        project = [[ACProject alloc] initWithFileURL:projectURL];
    });
    
    it(@"can be opened", ^{
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateClosed)];
        __block BOOL opened = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            opened = success;
        }];
        [[expectFutureValue(theValue(opened)) shouldEventually] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
    });

    it(@"can be opened and then closed", ^{
        __block BOOL opened = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            opened = success;
        }];
        [[expectFutureValue(theValue(opened)) shouldEventually] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
        __block BOOL closed = NO;
        [project closeWithCompletionHandler:^(BOOL success) {
            closed = success;
        }];
        [[expectFutureValue(theValue(closed)) shouldEventually] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateClosed)];
    });
    
    it(@"should have a root folder", ^{
        [[project.rootFolder should] beNonNil];
    });
    
});

SPEC_END


