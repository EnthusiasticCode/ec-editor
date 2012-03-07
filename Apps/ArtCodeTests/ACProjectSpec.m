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
#import "ACProjectFile.h"
#import "ACProjectFileBookmark.h"
#import "ACProjectRemote.h"

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

describe(@"A new opened ACProject", ^{
    
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
    
    context(@"root folder", ^{
        
        it(@"is not nil", ^{
            [[project.rootFolder should] beNonNil];
        });
       
        it(@"has no children", ^{
            [[[project.rootFolder should] have:0] children];
        });
    });
    
    context(@"root folder's subfolder", ^{
        
        NSString *subfolderName = @"testsubfolder";
        
        it(@"can be created and deleted with no error", ^{
            NSError *err = nil;
            [[theValue([project.rootFolder addNewFolderWithName:subfolderName error:&err]) should] beYes];
            [[err should] beNil];
            [[[project.rootFolder should] have:1] children];
            
            // Retrieve
            id item = [project.rootFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFolder class]];
            
            // Remove
            [item remove];
            [[[project.rootFolder should] have:0] children];
        });
        
        context(@"when created", ^{
            
            __block ACProjectFolder *subfolder = nil;
            
            beforeEach(^{
                [project.rootFolder addNewFolderWithName:subfolderName error:nil];
                subfolder = [project.rootFolder.children objectAtIndex:0];
            });
            
            afterEach(^{
                [subfolder remove];
            });
            
            it(@"has a consistent name", ^{
                [[[subfolder name] should] equal:subfolderName];
            });
            
            it(@"has no children", ^{
                [[[subfolder should] have:0] children];
            });
        });
    });
    
    context(@"root folder's text file", ^{
       
        NSString *fileName = @"testfile.txt";
        NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
        
        it(@"can be created and deleted with no error", ^{
            NSError *err = nil;
            [[theValue([project.rootFolder addNewFileWithName:fileName data:fileData error:&err]) should] beYes];
            [[err should] beNil];
            [[[project.rootFolder should] have:1] children];
            
            id item = [project.rootFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFile class]];
            
            [item remove];
            [[[project.rootFolder should] have:0] children];
        });
        
        context(@"when created", ^{
            
            __block ACProjectFile *file = nil;
            
            beforeEach(^{
                [project.rootFolder addNewFileWithName:fileName data:fileData error:nil];
                file = [project.rootFolder.children objectAtIndex:0];
            });
            
            afterEach(^{
                [file remove];
            });
            
            it(@"has a consistent name", ^{
                [[[file name] should] equal:fileName];
            });
            
            it(@"has UTF8 encoding by default", ^{
                [[theValue(file.fileEncoding) should] equal:theValue(NSUTF8StringEncoding)];
            });
            
            it(@"has no bookmarks", ^{
                [[[file should] have:0] bookmarks];
            });
            
            it(@"can create and remove a bookmark", ^{
                [file addBookmarkWithPoint:[NSNumber numberWithInt:0]];
                [[[file should] have:1] bookmarks];
                
                id item = [file.bookmarks objectAtIndex:0];
                [[item should] beMemberOfClass:[ACProjectFileBookmark class]];
                
                [item remove];
                [[[file should] have:0] bookmarks];
            });
            
            context(@"having a line bookmark", ^{
                
                __block ACProjectFileBookmark *bookmark = nil;
                NSNumber *bookmarkPoint = [NSNumber numberWithInt:0];
                
                beforeEach(^{
                    [file addBookmarkWithPoint:bookmarkPoint];
                    bookmark = [file.bookmarks objectAtIndex:0];
                });
                
                afterEach(^{
                    [bookmark remove];
                });
                
                it(@"with a consistent file", ^{
                    [[bookmark.file should] equal:file]; 
                });
                
                it(@"with a consistent line point", ^{
                    [[bookmark.bookmarkPoint should] equal:bookmarkPoint];
                });
            });
        });
    });
    
    context(@"remote", ^{
        
        NSString *remoteName = @"testremote";
        NSURL *remoteURL = [NSURL URLWithString:@"ssh://test@test.com:21"];
        
        it(@"can be added with valid data and removed", ^{
            [[[project should] have:0] remotes];
            [project addRemoteWithName:remoteName URL:remoteURL];
            [[[project should] have:1] remotes];
            
            id item = [project.remotes objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectRemote class]];
            
            [item remove];
            [[[project should] have:0] remotes];
        });
        
        context(@"when present", ^{
           
            __block ACProjectRemote *remote = nil;

            beforeEach(^{
                [project addRemoteWithName:remoteName URL:remoteURL];
                remote = [project.remotes objectAtIndex:0];
            });
            
            afterEach(^{
                [remote remove];
            });
            
            it(@"has a consistent name", ^{
                [[remote.name should] equal:remoteName];
            });
            
            it(@"has a consistent URL composition", ^{
                [[remote.scheme should] equal:remoteURL.scheme];
                [[remote.host should] equal:remoteURL.host];
                [[remote.port should] equal:remoteURL.port];
                [[remote.user should] equal:remoteURL.user];
                [[remote.password should] beNil];
            });
        });
    });
});

SPEC_END


