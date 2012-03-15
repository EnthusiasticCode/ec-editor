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

void clearProjectsDirectory(void) {
    [ACProject performSelector:@selector(_removeAllProjects)];
}

SPEC_BEGIN(ACProjectSpec)

describe(@"An ACProject", ^{
    
    NSString *projectName = @"Test Project";
    
    beforeAll(^{
        clearProjectsDirectory();
    });
    
    afterAll(^{
        clearProjectsDirectory();
    });
    
    it(@"can be created", ^{
        __block ACProject *project = nil;
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject) {
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
        [[[ACProject projects] should] haveCountOf:1];
    });
    
    it(@"can be retrieved", ^{
        ACProject *project = nil;
        for (project in [ACProject projects]) {
            if ([project.name isEqualToString:projectName]) {
                break;
            }
        }
        [[project should] beNonNil];
    });
    
    it(@"can be deleted", ^{
        ACProject *project = nil;
        for (project in [ACProject projects]) {
            if ([project.name isEqualToString:projectName]) {
                break;
            }
        }
        [[project should] beNonNil];
        [project remove];
        [[[ACProject projects] should] haveCountOf:0];
    });
    
});

describe(@"An newly created ACProject", ^{
    NSString *projectName = @"Test Project";
    NSString *newProjectName = @"Renamed Test Project";
    __block ACProject *project = nil;
    __block id projectUUID = nil;
    
    beforeEach(^{
        clearProjectsDirectory();
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject) {
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
        projectUUID = project.UUID;
    });
    
    afterAll(^{
        clearProjectsDirectory();
    });
    
    it(@"is open", ^{
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateNormal)];
    });

    it(@"can be closed", ^{
        __block BOOL closed = NO;
        [project closeWithCompletionHandler:^(BOOL success) {
            closed = success;
        }];
        [[expectFutureValue(theValue(closed)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        [[theValue([project documentState]) should] equal:theValue(UIDocumentStateClosed)];
    });
    
    it(@"has a UUID", ^{
        [[project.UUID should] beNonNil];
    });
    
    it(@"can be retrieved by UUID", ^{
        ACProject *projectByUUID = [ACProject projectWithUUID:projectUUID];
        [[projectByUUID.name should] equal:project.name];
    });
    
    it(@"can be renamed and still be retrieved by UUID", ^{
        project.name = newProjectName;
        ACProject *projectByUUID = [ACProject projectWithUUID:projectUUID];
        [[projectByUUID.name should] equal:project.name];
    });
    
    it(@"can be deleted and not retrieved by UUID", ^{
        [project remove];
        [[ACProject projectWithUUID:projectUUID] shouldBeNil];
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
    
});

describe(@"A new opened ACProject", ^{
    
    NSString *projectName = @"Test Project";
    __block ACProject *project = nil;
    
    beforeEach(^{
        clearProjectsDirectory();
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject) {
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
        __block BOOL isOpened = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventuallyBeforeTimingOutAfter(2)] beYes];
    });
    
    afterAll(^{
        clearProjectsDirectory();
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
        
        it(@"can be created with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFolderWithName:subfolderName contents:nil plist:nil error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            [[[[project.contentsFolder.children objectAtIndex:0] name] should] equal:subfolderName];
        });
        
        it(@"can be retrieved with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFolderWithName:subfolderName contents:nil plist:nil error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            
            // Retrieve
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFolder class]];
        });
        
        context(@"after being created", ^{
            
            __block ACProjectFolder *subfolder = nil;
            NSString *subfolder2Name = @"subfolder2";
            __block ACProjectFolder *subfolder2 = nil;
            __block id subfolderUUID = nil;
            __block id subfolder2UUID = nil;
            NSString *newSubfolderName = @"newsubfoldername";
            
            beforeEach(^{
                NSError *err = nil;
                [[theValue([project.contentsFolder addNewFolderWithName:subfolderName contents:nil plist:nil error:&err]) should] beYes];
                [err shouldBeNil];
                [[[project.contentsFolder should] have:1] children];
                [[theValue([project.contentsFolder addNewFolderWithName:subfolder2Name contents:nil plist:nil error:&err]) should] beYes];
                [err shouldBeNil];
                [[[project.contentsFolder should] have:2] children];
                
                // Retrieve
                id item = [project.contentsFolder.children objectAtIndex:1];
                [[item should] beMemberOfClass:[ACProjectFolder class]];
                
                subfolder = (ACProjectFolder *)item;
                subfolderUUID = subfolder.UUID;
                [[subfolder.name should] equal:subfolderName];
                
                item = [project.contentsFolder.children objectAtIndex:0];
                [[item should] beMemberOfClass:[ACProjectFolder class]];
                
                subfolder2 = (ACProjectFolder *)item;
                subfolder2UUID = subfolder2.UUID;
                [[subfolder2.name should] equal:subfolder2Name];
            });

            it(@"can be deleted with no error", ^{
                // Remove
                [subfolder remove];
                [[[project.contentsFolder should] have:1] children];
                [subfolder2 remove];
                [[[project.contentsFolder should] have:0] children];
            });
            
            it(@"can be renamed", ^{
                subfolder.name = newSubfolderName;
                [[subfolder.name should] equal:newSubfolderName];
            });
            
            it(@"can be moved", ^{
                NSError *error = nil;
                [subfolder2 moveToFolder:subfolder error:&error];
                [error shouldBeNil];
                [[[subfolder should] have:1] children];
                [[[project.contentsFolder should] have:1] children];
            });
            
            it(@"can be copied", ^{
                NSError *error = nil;
                [subfolder2 copyToFolder:subfolder2 error:&error];
                [error shouldBeNil];
                [[[subfolder should] have:1] children];
                [[[project.contentsFolder should] have:2] children];
            });
            
            it(@"can be retrieved by UUID", ^{
                [[[project itemWithUUID:subfolderUUID] should] equal:subfolder];
            });
            
            it(@"can be retrieved by UUID after being moved", ^{
                NSError *error = nil;
                [subfolder2 moveToFolder:subfolder error:&error];
                [error shouldBeNil];
                [[[project itemWithUUID:subfolder2UUID] should] equal:[subfolder.children objectAtIndex:0]];
            });
            
            it(@"cannot be retrieved by UUID after being deleted", ^{
                [subfolder2 remove];
                [[project itemWithUUID:subfolder2UUID] shouldBeNil];
            });
            
            it(@"has a last modified date", ^{
                [[[subfolder contentModificationDate] should] beNonNil];
            });
            
        });
                
        context(@"when created", ^{
            
            __block ACProjectFolder *subfolder = nil;
            
            beforeEach(^{
                [project.contentsFolder addNewFolderWithName:subfolderName contents:nil plist:nil error:nil];
                subfolder = [project.contentsFolder.children objectAtIndex:0];
            });
            
            afterEach(^{
                [subfolder remove];
            });
            
            it(@"is of correct type", ^{
                [[theValue(subfolder.type) should] equal:theValue(ACPFolder)];
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
        NSFileWrapper *fileContents = [[NSFileWrapper alloc] initRegularFileWithContents:[@"test" dataUsingEncoding:NSUTF8StringEncoding]];
        
        it(@"can be created with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFileWithName:fileName contents:fileContents plist:nil error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
        });

        it(@"can be created and retrieved with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFileWithName:fileName contents:fileContents plist:nil error:&err]) should] beYes];
            [err shouldBeNil];
            [[[project.contentsFolder should] have:1] children];
            
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFile class]];
        });

        it(@"can be created, retrieved and deleted with no error", ^{
            NSError *err = nil;
            [[theValue([project.contentsFolder addNewFileWithName:fileName contents:fileContents plist:nil error:&err]) should] beYes];
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
                [project.contentsFolder addNewFileWithName:fileName contents:fileContents plist:nil error:nil];
                file = [project.contentsFolder.children objectAtIndex:0];
            });
            
            afterEach(^{
                [file remove];
            });
            
            it(@"is of correct type", ^{
                [[theValue(file.type) should] equal:theValue(ACPFile)];
            });
            
            it(@"has an UUID", ^{
                [[[file UUID] should] beNonNil];
            });
            
            it(@"can be retrieved with its UUID", ^{
                [[[project itemWithUUID:file.UUID] should] equal:file];
            });
            
            it(@"has a consistent name", ^{
                [[[file name] should] equal:fileName];
            });
            
            it(@"has a last modified date", ^{
                [[[file contentModificationDate] should] beNonNil];
            });
            
            it(@"has a size", ^{
                [[theValue(file.fileSize) should] equal:theValue(0)];
            });
            
            it(@"has UTF8 encoding by default", ^{
                [[theValue(file.fileEncoding) should] equal:theValue(NSUTF8StringEncoding)];
            });
            
            it(@"has no bookmarks", ^{
                [[[file should] have:0] bookmarks];
            });
            
            it(@"can create a bookmark", ^{
                [file addBookmarkWithPoint:[NSNumber numberWithInt:0]];
                [[[file should] have:1] bookmarks];
            });
            
            it(@"can retrieve a bookmark", ^{
                [file addBookmarkWithPoint:[NSNumber numberWithInt:0]];
                [[[file should] have:1] bookmarks];
                
                id item = [file.bookmarks objectAtIndex:0];
                [[item should] beMemberOfClass:[ACProjectFileBookmark class]];                
            });
            
            it(@"can remove a bookmark", ^{
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
                
                it(@"is of correct type", ^{
                    [[theValue(bookmark.type) should] equal:theValue(ACPFileBookmark)];
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
        
        it(@"can be added with valid data", ^{
            [[[project should] have:0] remotes];
            [project addRemoteWithName:remoteName URL:remoteURL];
            [[[project should] have:1] remotes];
        });
        
        it(@"can be retrieved", ^{
            [[[project should] have:0] remotes];
            [project addRemoteWithName:remoteName URL:remoteURL];
            [[[project should] have:1] remotes];
            
            id item = [project.remotes objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectRemote class]];            
        });
        
        it(@"can be removed", ^{
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
            
            it(@"is of correct type", ^{
                [[theValue(remote.type) should] equal:theValue(ACPRemote)];
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
    
    it(@"has a list of files", ^{
        [[[project should] have:0] files];
        [project.contentsFolder addNewFolderWithName:@"test folder" contents:nil plist:nil error:NULL];
        [[[project should] have:1] files];
        [[project.contentsFolder.children objectAtIndex:0] addNewFileWithName:@"test file 1" contents:nil plist:nil error:NULL];
        [[[project should] have:2] files];
        [[project.contentsFolder.children objectAtIndex:0] addNewFileWithName:@"test file 2" contents:nil plist:nil error:NULL];
        [[[project should] have:3] files];
        [[[[project.contentsFolder.children objectAtIndex:0] children] objectAtIndex:0] remove];
        [[[project should] have:2] files];
        [[project.contentsFolder.children objectAtIndex:0] remove];
        [[[project should] have:0] files];
    });
    
    it(@"has a list of bookmarks", ^{
        [[[project should] have:0] bookmarks];
        [project.contentsFolder addNewFileWithName:@"test file" contents:nil plist:nil error:NULL];
        ACProjectFile *testFile = [project.contentsFolder.children objectAtIndex:0];
        [testFile addBookmarkWithPoint:[NSNumber numberWithUnsignedInteger:0]];
        [[[project should] have:1] bookmarks];
        [testFile addBookmarkWithPoint:[NSNumber numberWithUnsignedInteger:1]];
        [[[project should] have:2] bookmarks];
        [[[testFile bookmarks] objectAtIndex:0] remove];
        [[[project should] have:1] bookmarks];
        [testFile remove];
        [[[project should] have:0] bookmarks];
    });

});

describe(@"An existing ACProject", ^{
    
    NSString *projectName = @"Test Project";
    __block ACProject *project = nil;
    __block id projectUUID = nil;
    UIColor *projectLabelColor = [UIColor redColor];
    NSString *subfolderName = @"testfolder";
    NSString *fileName = @"testfile.txt";
    NSFileWrapper *fileContents = [[NSFileWrapper alloc] initRegularFileWithContents:[@"test\nfile" dataUsingEncoding:NSUTF8StringEncoding]];
    NSNumber *bookmarkPoint = [NSNumber numberWithInt:1];
    
    beforeAll(^{
        clearProjectsDirectory();
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject) {
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventuallyBeforeTimingOutAfter(5)] beNonNil];
        __block BOOL isOpened = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventuallyBeforeTimingOutAfter(2)] beYes];
        
        projectUUID = project.UUID;
        project.labelColor = projectLabelColor;
        [project.contentsFolder addNewFolderWithName:subfolderName contents:nil plist:nil error:NULL];
        ACProjectFolder *subfolder = [project.contentsFolder.children objectAtIndex:0];
        [subfolder addNewFileWithName:fileName contents:fileContents plist:nil error:NULL];
        ACProjectFile *file = [subfolder.children objectAtIndex:0];
        [file addBookmarkWithPoint:bookmarkPoint];
        
        [project closeWithCompletionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventuallyBeforeTimingOutAfter(2)] beYes];
        project = [ACProject projectWithUUID:projectUUID];
        [project openWithCompletionHandler:^(BOOL success) {
            isOpened = success;
        }];
        [[expectFutureValue(theValue(isOpened)) shouldEventuallyBeforeTimingOutAfter(2)] beYes];
    });
    
    afterAll(^{
        clearProjectsDirectory();
    });
    
    it(@"saved its UUID", ^{
        [[project.UUID should] equal:projectUUID];
    });
    
    it(@"saved its labelColor", ^{
        [[project.labelColor should] equal:projectLabelColor];
    });
    
    it(@"has 2 files", ^{
        [[[project should] have:2] files];
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


