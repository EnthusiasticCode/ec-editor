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

describe(@"An newly created project ACProject", ^{
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
});

describe(@"The ACProject class", ^{
    
    it(@"define a global projects directory URL", ^{
        BOOL isDirectory = NO;
        [[[ACProject projectsURL] should] beNonNil];
        [[theValue([[NSFileManager new] fileExistsAtPath:[[ACProject projectsURL] path] isDirectory:&isDirectory]) should] beYes];
        [[theValue(isDirectory) should] beYes];
    });
    
    context(@"project creation", ^{
        
        NSString *projectName = @"testproject";
        __block NSURL *projectURL = nil;
        
        beforeAll(^{
            projectURL = [[[ACProject projectsURL] URLByAppendingPathComponent:projectName] URLByAppendingPathExtension:@"acproj"];
        });
        
        beforeEach(^{
            [[NSFileManager new] removeItemAtURL:projectURL error:NULL];
        });
        
        afterAll(^{
            [[NSFileManager new] removeItemAtURL:projectURL error:NULL];
        });
        
        it(@"is successful", ^{
            __block BOOL successful = NO;
            [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(BOOL success) {
                successful = success;
            }];
            
            [[expectFutureValue(theValue(successful)) shouldEventually] beYes];
        });
    });
});

describe(@"An opened ACProject", ^{
    
    NSURL *projectURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"testproject.acproj"]];
    __block ACProject *project = nil;
    
    beforeEach(^{
        __block BOOL isOpened = NO;
        [[NSFileManager new] removeItemAtURL:projectURL error:NULL];
        project = [[ACProject alloc] initWithFileURL:projectURL];
        [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [project openWithCompletionHandler:^(BOOL success) {
                isOpened = success;
            }];
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventually] beYes];
    });
    
    afterEach(^{
        [project closeWithCompletionHandler:^(BOOL success) {
            [[NSFileManager new] removeItemAtURL:projectURL error:NULL];
        }];
    });
    
    it(@"has a root folder", ^{
        [[project.rootFolder should] beNonNil];
    });
    
    it(@"has a UUID", ^{
        [[project.UUID should] beNonNil];
    });
    
    context(@"label color", ^{
        
        it(@"is nil on a new project", ^{
            [[project.labelColor should] beNil];
        });
        
        it(@"is settable with a UIColor", ^{
            UIColor *testColor = [UIColor blackColor];
            project.labelColor = testColor;
            [[project.labelColor should] equal:testColor];
        });
    });
    
    context(@"remotes", ^{
        
        it(@"are empty on a new project", ^{
            [[[project should] have:0] remotes];
        });
        
        it(@"can be added with valid data", ^{
            [project addRemoteWithName:@"testremote" URL:[NSURL URLWithString:@"ssh://test@test.com:21"]];
            [[[project should] have:1] remotes];
        });
    });
});

SPEC_END


