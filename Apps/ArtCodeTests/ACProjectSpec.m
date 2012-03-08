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

describe(@"A new, non-opened ACProject", ^{
        
    context(@"with a valid URL", ^{

        NSURL *projectURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"testproject.acproj"]];
        __block ACProject *project = nil;
        
        beforeEach(^{
            [[[NSFileManager alloc] init] removeItemAtURL:projectURL error:NULL];
            project = [[ACProject alloc] initWithFileURL:projectURL];
        });
        
        afterAll(^{
            [[[NSFileManager alloc] init] removeItemAtURL:projectURL error:NULL];
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
            [[expectFutureValue(theValue(saved)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
            [[theValue([[[NSFileManager alloc] init] fileExistsAtPath:[projectURL path]]) should] beYes];
        });
        
        it(@"should not have a contents folder", ^{
            [project.contentsFolder shouldBeNil];
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
        __block BOOL saved = NO;
        [newProject saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success)
                [newProject closeWithCompletionHandler:^(BOOL success) {
                    if (success)
                        saved = YES;
                }];
        }];
        [[expectFutureValue(theValue(saved)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        project = [[ACProject alloc] initWithFileURL:projectURL];
    });
    
    afterAll(^{
        [[[NSFileManager alloc] init] removeItemAtURL:projectURL error:NULL];
    });
    
    it(@"can be opened", ^{
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateClosed)];
        __block BOOL opened = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            opened = success;
        }];
        [[expectFutureValue(theValue(opened)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
    });

    it(@"can be opened and then closed", ^{
        __block BOOL opened = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            opened = success;
        }];
        [[expectFutureValue(theValue(opened)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
        __block BOOL closed = NO;
        [project closeWithCompletionHandler:^(BOOL success) {
            closed = success;
        }];
        [[expectFutureValue(theValue(closed)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateClosed)];
    });
});

describe(@"The ACProject class", ^{
    
    it(@"define a global projects directory URL", ^{
        [[[ACProject projectsURL] should] beNonNil];
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
            __block ACProject *project = nil;
            [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject) {
                project = createdProject;
            }];
            
            [[expectFutureValue(project) shouldEventually] beNonNil];
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
            isOpened = success;
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
       
        it(@"can be set", ^{
            [project.labelColor shouldBeNil];
            project.labelColor = [UIColor redColor];
        });
        
        it(@"can be set and read", ^{
            project.labelColor = [UIColor redColor];
            [[project.labelColor should] equal:[UIColor redColor]];
        });
    });
    
    context(@"contents folder", ^{
        
        it(@"is not nil", ^{
            [[project.contentsFolder should] beNonNil];
        });
       
        it(@"has no children", ^{
            [[[project.contentsFolder should] have:0] children];
        });
    });
    
    context(@"contents folder's subfolder", ^{
        
        NSString *subfolderName = @"testsubfolder";
        
        it(@"contents folder's subfolder can be created with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFolderWithName:subfolderName error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
        });
        
        it(@"contents folder's subfolder can be created and retrieved with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFolderWithName:subfolderName error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            
            // Retrieve
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFolder class]];
        });
        
        it(@"can be created, retrieved and deleted with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFolderWithName:subfolderName error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            
            // Retrieve
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFolder class]];
            
            // Remove
            [item remove];
            [[[project.contentsFolder should] have:0] children];
        });
        
        context(@"when created", ^{
            
            __block ACProjectFolder *subfolder = nil;
            
            beforeEach(^{
                [project.contentsFolder addNewFolderWithName:subfolderName error:nil];
                subfolder = [project.contentsFolder.children objectAtIndex:0];
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
    
    context(@"contents folder's text file", ^{
       
        NSString *fileName = @"testfile.txt";
        NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
        
        it(@"can be created with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFileWithName:fileName data:fileData error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
        });

        it(@"can be created and retrieved with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFileWithName:fileName data:fileData error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFile class]];
        });

        it(@"can be created, retrieved and deleted with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFileWithName:fileName data:fileData error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFile class]];
            
            [item remove];
            [[[project.contentsFolder should] have:0] children];
        });
        
        context(@"when created", ^{
            
            __block ACProjectFile *file = nil;
            
            beforeEach(^{
                [project.contentsFolder addNewFileWithName:fileName data:fileData error:nil];
                file = [project.contentsFolder.children objectAtIndex:0];
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
            
            it(@"has a file buffer", ^{
                [[[file should] receive] codeFileBuffer];
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
                [remote.password shouldBeNil];
            });
        });
    });
});

describe(@"An existing ACProject", ^{
    
    NSURL *projectURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"testproject.acproj"]];
    __block ACProject *project = nil;
    __block id projectUUID = nil;
    UIColor *projectLabelColor = [UIColor redColor];
    NSString *subfolderName = @"testfolder";
    NSString *fileName = @"testfile.txt";
    NSData *fileData = [@"test\nfile" dataUsingEncoding:NSUTF8StringEncoding];
    NSNumber *bookmarkPoint = [NSNumber numberWithInt:1];
    
    beforeAll(^{
        __block BOOL isOpened = NO;
        [[NSFileManager new] removeItemAtURL:projectURL error:NULL];
        project = [[ACProject alloc] initWithFileURL:projectURL];
        [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventually] beYes];
        
        projectUUID = project.UUID;
        project.labelColor = projectLabelColor;
        [project.contentsFolder addNewFolderWithName:subfolderName error:NULL];
        ACProjectFolder *subfolder = [project.contentsFolder.children objectAtIndex:0];
        [subfolder addNewFileWithName:fileName data:fileData error:NULL];
        ACProjectFile *file = [subfolder.children objectAtIndex:1];
        [file addBookmarkWithPoint:bookmarkPoint];
        
        [project closeWithCompletionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventually] beYes];
        [project openWithCompletionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventually] beYes];
    });
    
    afterAll(^{
        [project closeWithCompletionHandler:^(BOOL success) {
            [[NSFileManager new] removeItemAtURL:projectURL error:NULL];
        }];
    });
    
    it(@"saved its UUID", ^{
        [[project.UUID should] equal:projectUUID];
    });
    
    it(@"saved its labelColor", ^{
        [[project.labelColor should] equal:projectLabelColor];
    });
    
    it(@"has a valid content", ^{
        [[[project.contentsFolder should] have:1] children];
        
        id item = [project.contentsFolder.children objectAtIndex:0];
        [[item should] beMemberOfClass:[ACProjectFolder class]];
        
        ACProjectFolder *subfolder = (ACProjectFolder *)item;
        [[subfolder.name should] equal:subfolderName];
        [[[subfolder should] have:1] children];
        
        item = [subfolder.children objectAtIndex:0];
        [[item should] beMemberOfClass:[ACProjectFile class]];
        
        ACProjectFile *file = (ACProjectFile *)item;
        [[file.name should] equal:fileName];
        [[[file should] have:1] bookmarks];
        
        ACProjectFileBookmark *bookmark = [file.bookmarks objectAtIndex:0];
        [[bookmark.bookmarkPoint should] equal:bookmarkPoint];
    });
});

SPEC_END


