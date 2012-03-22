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

#import "NSURL+Utilities.h"

static void clearProjectsDirectory(void);

// Redefine the default timeout because my iMac is so slow
#undef kKW_DEFAULT_PROBE_TIMEOUT
#define kKW_DEFAULT_PROBE_TIMEOUT 10

SPEC_BEGIN(ACProjectSpec)

#pragma mark - ACProject

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
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject, NSError *error) {
            [error shouldBeNil];
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventually] beNonNil];
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
    
    it(@"can be duplicated", ^{
        __block ACProject *project = nil;
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject, NSError *error) {
            [error shouldBeNil];
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventually] beNonNil];
        __block ACProject *duplicateProject = nil;
        [project duplicateWithCompletionHandler:^(ACProject *duplicate, NSError *error) {
            [error shouldBeNil];
            duplicateProject = duplicate;
        }];
        [[expectFutureValue(project) shouldEventually] beNonNil];
        [[duplicateProject shouldNot] equal:project];
        [[duplicateProject.name shouldNot] equal:project.name];
    });
});

#pragma mark - ACProject new instance 

describe(@"An newly created ACProject", ^{
    NSString *projectName = @"Test Project";
    NSString *newProjectName = @"Renamed Test Project";
    __block ACProject *project = nil;
    __block id projectUUID = nil;
    
    beforeEach(^{
        clearProjectsDirectory();
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject, NSError *error) {
            [error shouldBeNil];
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventually] beNonNil];
        projectUUID = project.UUID;
    });
    
    afterEach(^{
        project = nil;
        projectUUID = nil;
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
        [[expectFutureValue(theValue(closed)) shouldEventually] beYes];
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
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject, NSError *error) {
            [error shouldBeNil];
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventually] beNonNil];
    });
    
    afterEach(^{
        project = nil;
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
            __block ACProjectFolder *subfolder = nil;
            [project.contentsFolder addNewFolderWithName:subfolderName originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                [error shouldBeNil];
                subfolder = newFolder;
            }];
            [[expectFutureValue(subfolder) shouldEventually] beNonNil];
        });
        
        it(@"can be retrieved with no error", ^{
            __block ACProjectFolder *subfolder = nil;
            [project.contentsFolder addNewFolderWithName:subfolderName originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                [error shouldBeNil];
                subfolder = newFolder;
            }];
            [[expectFutureValue(subfolder) shouldEventually] beNonNil];
            
            // Retrieve
            [[[project.contentsFolder should] have:1] children];
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFolder class]];
            [[item should] equal:subfolder];
        });
        
        context(@"given a URL", ^{
            
            NSURL *temporaryDirectory = [NSURL temporaryDirectory];
            NSURL *temporaryDirectory2 = [NSURL temporaryDirectory];
            NSURL *temporarySubfolder = [temporaryDirectory URLByAppendingPathComponent:@"Temporary subfolder"];
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            __block ACProjectFolder *subfolder = nil;
            
            beforeEach(^{
                // Create the temporary folder
                [[theValue([fileManager createDirectoryAtURL:[temporarySubfolder URLByAppendingPathComponent:@"test"] withIntermediateDirectories:YES attributes:nil error:NULL]) should] beYes];
            });
            
            afterEach(^{
                subfolder = nil;
                [fileManager removeItemAtURL:temporaryDirectory error:NULL];
                [fileManager removeItemAtURL:temporaryDirectory2 error:NULL];
            });
            
            it(@"can be created with the contents of that URL", ^{
                [project.contentsFolder addNewFolderWithName:subfolderName originalURL:temporarySubfolder completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                    [error shouldBeNil];
                    subfolder = newFolder;
                }];
                [[expectFutureValue(subfolder) shouldEventually] beNonNil];
                [[[subfolder should] have:1] children];
            });
            
            it(@"can be updated with the contents of that URL", ^{
                [project.contentsFolder addNewFolderWithName:subfolderName originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                    [error shouldBeNil];
                    subfolder = newFolder;
                }];
                [[expectFutureValue(subfolder) shouldEventually] beNonNil];
                
                [[[subfolder should] have:0] children];
                
                __block BOOL updateComplete = NO;
                [subfolder updateWithContentsOfURL:temporarySubfolder completionHandler:^(NSError *error) {
                    [error shouldBeNil];
                    updateComplete = YES;
                }];
                [[expectFutureValue(theValue(updateComplete)) shouldEventually] beYes];
                [[[subfolder should] have:1] children];
            });
            
            it(@"can publish it's contents to that URL", ^{                
                [project.contentsFolder addNewFolderWithName:subfolderName originalURL:temporarySubfolder completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                    [error shouldBeNil];
                    subfolder = newFolder;
                }];
                [[expectFutureValue(subfolder) shouldEventually] beNonNil];
                [[[subfolder should] have:1] children];
                
                __block BOOL publishComplete = NO;
                [subfolder publishContentsToURL:temporaryDirectory2 completionHandler:^(NSError *error) {
                    [error shouldBeNil];
                    publishComplete = YES;
                }];
                [[expectFutureValue(theValue(publishComplete)) shouldEventually] beYes];
                [[theValue([fileManager fileExistsAtPath:[[temporaryDirectory2 URLByAppendingPathComponent:@"test"] path]]) should] beYes];
            });
        });
                
        context(@"after being created", ^{
            
            __block ACProjectFolder *subfolder = nil;
            __block id subfolderUUID = nil;
            NSString *subfolder2Name = @"subfolder2";
            __block ACProjectFolder *subfolder2 = nil;
            __block id subfolder2UUID = nil;
            NSString *newSubfolderName = @"newsubfoldername";
            
            beforeEach(^{
                [project.contentsFolder addNewFolderWithName:subfolderName originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                    [error shouldBeNil];
                    subfolder = newFolder;
                }];
                [[expectFutureValue(subfolder) shouldEventually] beNonNil];
                subfolderUUID = subfolder.UUID;
                [project.contentsFolder addNewFolderWithName:subfolder2Name originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                    [error shouldBeNil];
                    subfolder2 = newFolder;
                }];
                [[expectFutureValue(subfolder2) shouldEventually] beNonNil];
                subfolder2UUID = subfolder2.UUID;
            });
            
            afterEach(^{
                subfolder = nil;
                subfolderUUID = nil;
                subfolder2 = nil;
                subfolder2UUID = nil;
            });

            it(@"can be deleted with no error", ^{
                // Remove
                [subfolder removeWithCompletionHandler:^(NSError *error) {
                    [error shouldBeNil];
                }];
                [[expectFutureValue(project.contentsFolder.children) shouldEventually] haveCountOf:1] ;
                [subfolder2 removeWithCompletionHandler:^(NSError *error) {
                    [error shouldBeNil];
                }];
                [[expectFutureValue(project.contentsFolder.children) shouldEventually] haveCountOf:0];
            });
            
            it(@"can be renamed", ^{
                [subfolder setName:newSubfolderName withCompletionHandler:^(NSError *error) {
                    [error shouldBeNil];
                }];
                [[expectFutureValue(subfolder.name) shouldEventually] equal:newSubfolderName];
            });
            
            it(@"can be moved", ^{
                __block BOOL moveComplete = NO;
                [subfolder2 moveToFolder:subfolder completionHandler:^(NSError *error) {
                    [error shouldBeNil];
                    moveComplete = YES;
                }];
                [[expectFutureValue(theValue(moveComplete)) shouldEventually] beYes];
                [[[subfolder should] have:1] children];
                [[[project.contentsFolder should] have:1] children];
            });
            
            it(@"can be copied", ^{
                __block ACProjectFolder *subfolder2Copy = nil;
                [subfolder2 copyToFolder:subfolder completionHandler:^(ACProjectFileSystemItem *copy, NSError *error) {
                    [error shouldBeNil];
                    subfolder2Copy = (ACProjectFolder *)copy;
                }];
                [[expectFutureValue(subfolder2Copy) shouldEventually] beNonNil];
                [[[subfolder should] have:1] children];
                [[[project.contentsFolder should] have:2] children];
            });
            
            it(@"can be retrieved by UUID", ^{
                [[[project itemWithUUID:subfolderUUID] should] equal:subfolder];
            });
            
            it(@"can be retrieved by UUID after being moved", ^{
                __block BOOL moveComplete = NO;
                [subfolder2 moveToFolder:subfolder completionHandler:^(NSError *error) {
                    [error shouldBeNil];
                    moveComplete = YES;
                }];
                [[expectFutureValue(theValue(moveComplete)) shouldEventually] beYes];
                [[[project itemWithUUID:subfolder2UUID] should] equal:[subfolder.children objectAtIndex:0]];
            });
            
            it(@"cannot be retrieved by UUID after being deleted", ^{
                [subfolder2 removeWithCompletionHandler:^(NSError *error) {
                    [error shouldBeNil];
                }];
                [[expectFutureValue([project itemWithUUID:subfolder2UUID]) shouldEventually] beNil];
            });
            
            it(@"has a last modified date", ^{
                [[[subfolder contentModificationDate] should] beNonNil];
            });
            
        });
                
        context(@"when created", ^{
            
            __block ACProjectFolder *subfolder = nil;
            
            beforeEach(^{
                [project.contentsFolder addNewFolderWithName:subfolderName originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
                    [error shouldBeNil];
                    subfolder = newFolder;
                }];
                [[expectFutureValue(subfolder) shouldEventually] beNonNil];
            });
            
            afterEach(^{
                subfolder = nil;
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
        
        it(@"can be created with no error", ^{
            __block ACProjectFile *file = nil;
            [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
                [error shouldBeNil];
                file = newFile;
            }];
            [[expectFutureValue(file) shouldEventually] beNonNil];
        });
        
        it(@"can be created and retrieved with no error", ^{
            __block ACProjectFile *file = nil;
            [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
                [error shouldBeNil];
                file = newFile;
            }];
            [[expectFutureValue(file) shouldEventually] beNonNil];

            // Retrieve
            [[[project.contentsFolder should] have:1] children];
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFile class]];
        });

        it(@"can be created, retrieved and deleted with no error", ^{
            __block ACProjectFile *file = nil;
            [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
                [error shouldBeNil];
                file = newFile;
            }];
            [[expectFutureValue(file) shouldEventually] beNonNil];
            
            // Retrieve
            [[[project.contentsFolder should] have:1] children];
            id item = [project.contentsFolder.children objectAtIndex:0];
            [[item should] beMemberOfClass:[ACProjectFile class]];
            
            // Delete
            [item removeWithCompletionHandler:^(NSError *error) {
                [error shouldBeNil];
            }];
            [[expectFutureValue(project.contentsFolder.children) shouldEventually] haveCountOf:0];
        });
        
        context(@"given a URL", ^{
            
            NSURL *temporaryDirectory = [NSURL temporaryDirectory];
            NSURL *temporaryDirectory2 = [NSURL temporaryDirectory];
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSURL *temporaryFile = [temporaryDirectory URLByAppendingPathComponent:@"temporaryFile"];
            NSString *testContents = @"test contents";
            __block NSNumber *temporaryFileSize = nil;
            __block ACProjectFile *file = nil;
            
            beforeEach(^{
                // Create temporary directory
                [[theValue([fileManager createDirectoryAtURL:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:NULL]) should] beYes];
                
                // Create temporary file
                [[theValue([testContents writeToURL:temporaryFile atomically:YES encoding:NSUTF8StringEncoding error:NULL]) should] beYes];
                
                // Get temporary file size
                [[theValue([temporaryFile getResourceValue:&temporaryFileSize forKey:NSURLFileSizeKey error:NULL]) should] beYes];
                [[temporaryFileSize should] beNonNil];
            });
            
            afterEach(^{
                temporaryFileSize = nil;
                file = nil;
                [fileManager removeItemAtURL:temporaryDirectory error:NULL];
                [fileManager removeItemAtURL:temporaryDirectory2 error:NULL];
            });
            
            it(@"can be created with the contents of that URL", ^{
                [project.contentsFolder addNewFileWithName:fileName originalURL:temporaryFile completionHandler:^(ACProjectFile *newFile, NSError *error) {
                    [error shouldBeNil];
                    file = newFile;
                }];
                [[expectFutureValue(file) shouldEventually] beNonNil];
                [[theValue(file.fileSize) should] equal:temporaryFileSize];
            });

            it(@"can be updated with the contents of that URL", ^{
                [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
                    [error shouldBeNil];
                    file = newFile;
                }];
                [[expectFutureValue(file) shouldEventually] beNonNil];
                [[theValue(file.fileSize) should] beZero];
                
                __block BOOL updateComplete = NO;
                [file updateWithContentsOfURL:temporaryFile completionHandler:^(NSError *error) {
                    [error shouldBeNil];
                    updateComplete = YES;
                }];
                [[expectFutureValue(theValue(updateComplete)) should] beYes];
                [[theValue(file.fileSize) should] equal:temporaryFileSize];
            });
            
            it(@"can publish it's contents to that URL", ^{
                [project.contentsFolder addNewFileWithName:fileName originalURL:temporaryFile completionHandler:^(ACProjectFile *newFile, NSError *error) {
                    [error shouldBeNil];
                    file = newFile;
                }];
                [[expectFutureValue(file) shouldEventually] beNonNil];
                [[theValue(file.fileSize) should] equal:temporaryFileSize];
                
                __block BOOL publishComplete = NO;
                [file publishContentsToURL:[temporaryDirectory2 URLByAppendingPathComponent:file.name] completionHandler:^(NSError *error) {
                    [error shouldBeNil];
                    publishComplete = YES;
                }];
                [[expectFutureValue(theValue(publishComplete)) shouldEventually] beYes];
                [[theValue([fileManager fileExistsAtPath:[[temporaryDirectory2 URLByAppendingPathComponent:file.name] path]]) should] beYes];
            });
        });
        
        context(@"when created", ^{
            
            __block ACProjectFile *file = nil;
            
            beforeEach(^{
                [project.contentsFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
                    [error shouldBeNil];
                    file = newFile;
                }];
                [[expectFutureValue(file) shouldEventually] beNonNil];
            });
            
            afterEach(^{
                file = nil;
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
        
        __block ACProjectFolder *testFolder = nil;
        [project.contentsFolder addNewFolderWithName:@"test folder" originalURL:nil completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
            [error shouldBeNil];
            testFolder = newFolder;
        }];
        [[expectFutureValue(testFolder) shouldEventually] beNonNil];
        [[[project should] have:1] files];
        
        __block ACProjectFile *testFile1 = nil;
        [testFolder addNewFileWithName:@"test file 1" originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
            [error shouldBeNil];
            testFile1 = newFile;
        }];
        [[expectFutureValue(testFile1) shouldEventually] beNonNil];
        [[[project should] have:2] files];
        
        __block ACProjectFile *testFile2 = nil;
        [testFolder addNewFileWithName:@"test file 2" originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
            [error shouldBeNil];
            testFile2 = newFile;
        }];
        [[expectFutureValue(testFile2) shouldEventually] beNonNil];
        
        [[[project should] have:3] files];
        [testFile2 removeWithCompletionHandler:^(NSError *error) {
            [error shouldBeNil];
        }];
        [[expectFutureValue(project.files) shouldEventually] haveCountOf:2];
        [testFolder removeWithCompletionHandler:^(NSError *error) {
            [error shouldBeNil];
        }];
        [[expectFutureValue(project.files) shouldEventually] haveCountOf:0];
    });
    
    it(@"has a list of bookmarks", ^{
        [[[project should] have:0] bookmarks];
        
        __block ACProjectFile *testFile = nil;
        [project.contentsFolder addNewFileWithName:@"test file" originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
            [error shouldBeNil];
            testFile = newFile;
        }];
        [[expectFutureValue(testFile) shouldEventually] beNonNil];
        
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
    NSURL *temporaryDirectory = [NSURL temporaryDirectory];
    NSURL *originalURL = [temporaryDirectory URLByAppendingPathComponent:@"originaltestfile.txt"];
    NSNumber *bookmarkPoint = [NSNumber numberWithInt:1];
    
    beforeAll(^{
        clearProjectsDirectory();
        
        [ACProject createProjectWithName:projectName importArchiveURL:nil completionHandler:^(ACProject *createdProject, NSError *error) {
            [error shouldBeNil];
            project = createdProject;
        }];
        [[expectFutureValue(project) shouldEventually] beNonNil];
        
        projectUUID = project.UUID;
        project.labelColor = projectLabelColor;

        [[theValue([[[NSFileManager alloc] init] createDirectoryAtURL:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:NULL]) should] beYes];
        
        __block ACProjectFolder *subfolder = nil;
        [project.contentsFolder addNewFolderWithName:subfolderName originalURL:temporaryDirectory completionHandler:^(ACProjectFolder *newFolder, NSError *error) {
            [error shouldBeNil];
            subfolder = newFolder;
        }];
        [[expectFutureValue(subfolder) shouldEventually] beNonNil];
        
        [[theValue([[@"test\nfile" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:originalURL atomically:YES]) should] beYes];
        
        __block ACProjectFile *file = nil;
        [subfolder addNewFileWithName:fileName originalURL:originalURL completionHandler:^(ACProjectFile *newFile, NSError *error) {
            [error shouldBeNil];
            file = newFile;
        }];
        [[expectFutureValue(file) shouldEventually] beNonNil];
        
        [file addBookmarkWithPoint:bookmarkPoint];
        
        __block BOOL didClose = NO;
        [project closeWithCompletionHandler:^(BOOL success) {
            didClose = success;
        }];
        [[expectFutureValue(theValue(didClose)) shouldEventually] beYes];
        
        project = [ACProject projectWithUUID:projectUUID];
        __block BOOL didOpen = NO;
        [project openWithCompletionHandler:^(BOOL success) {
            didOpen = success;
        }];
        [[expectFutureValue(theValue(didOpen)) shouldEventually] beYes];
    });
    
    afterAll(^{
        clearProjectsDirectory();
        [[[NSFileManager alloc] init] removeItemAtURL:temporaryDirectory error:NULL];
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

// this is just debug code so ignore the warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
void clearProjectsDirectory(void) {
    [ACProject performSelector:@selector(_removeAllProjects)];
}
#pragma clang diagnostic pop