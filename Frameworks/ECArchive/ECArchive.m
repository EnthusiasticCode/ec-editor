//
//  ECArchive.m
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECArchive.h"
#import "archive.h"

@interface ECArchive ()
{
    struct archive *_archive;
}
@end

@implementation ECArchive

- (id)initWithFileURL:(NSURL *)URL
{
    ECASSERT([URL isFileURL]);
    self = [super init];
    if (!self)
        return nil;
    _archive = archive_read_new();
    archive_read_support_compression_all(_archive);
    archive_read_support_format_all(_archive);
    if (archive_read_open_filename(_archive, [[URL path] fileSystemRepresentation], 10240) != ARCHIVE_OK)
    {
        archive_read_finish(_archive);
        return nil;
    }
    return self;
}

- (void)dealloc
{
    archive_read_finish(_archive);
}

- (void)extractToDirectory:(NSURL *)URL
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    __block int returnCode = -1;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    __block NSURL *workingDirectory = nil;
    __block BOOL workingDirectoryAlreadyExists = YES;
    do
    {
        CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
        CFStringRef uuidString = CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
        workingDirectory = [URL URLByAppendingPathComponent:[@"." stringByAppendingString:(__bridge NSString *)uuidString]];
        CFRelease(uuidString);
        CFRelease(uuid);
        [fileCoordinator coordinateWritingItemAtURL:workingDirectory options:0 error:NULL byAccessor:^(NSURL *newURL) {
            workingDirectoryAlreadyExists = [fileManager fileExistsAtPath:[newURL path]];
            workingDirectory = newURL;
        }];
    }
    while (workingDirectoryAlreadyExists);
    [fileCoordinator coordinateWritingItemAtURL:workingDirectory options:0 error:NULL byAccessor:^(NSURL *newURL) {
        returnCode = ![fileManager createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
        workingDirectory = newURL;
    }];
    if (returnCode)
        return;
    NSString *currentDirectoryPath = [fileManager currentDirectoryPath];
    [fileManager changeCurrentDirectoryPath:[workingDirectory path]];
    [fileCoordinator coordinateWritingItemAtURL:workingDirectory options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
        workingDirectory = newURL;
        struct archive *output = archive_write_disk_new();
        int flags = ARCHIVE_EXTRACT_TIME;
        archive_write_disk_set_options(output, flags);
        archive_write_disk_set_standard_lookup(output);
        struct archive_entry *entry;
        for (;;)
        {
            returnCode = archive_read_next_header(_archive, &entry);
            if (returnCode == ARCHIVE_EOF)
            {
                returnCode = ARCHIVE_OK;
                break;
            }
            if (returnCode != ARCHIVE_OK)
                break;
            returnCode = archive_write_header(output, entry);
            if (returnCode != ARCHIVE_OK)
                break;
            const void *buff;
            size_t size;
            off_t offset;
            for (;;)
            {
                returnCode = archive_read_data_block(_archive, &buff, &size, &offset);
                if (returnCode == ARCHIVE_EOF)
                {
                    returnCode = ARCHIVE_OK;
                    break;
                }
                if (returnCode != ARCHIVE_OK)
                    break;
                returnCode = archive_write_data_block(output, buff, size, offset);
                if (returnCode != ARCHIVE_OK)
                    break;
            }
            if (returnCode != ARCHIVE_OK)
                break;
            returnCode = archive_write_finish_entry(output);
            if (returnCode != ARCHIVE_OK)
                break;
        }
        archive_write_finish(output);
        if (returnCode == ARCHIVE_OK)
        {
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:workingDirectory includingPropertiesForKeys:nil options:0 error:NULL])
            {
                NSURL *destinationURL = [URL URLByAppendingPathComponent:[fileURL lastPathComponent]];
                [fileCoordinator coordinateWritingItemAtURL:destinationURL options:NSFileCoordinatorReadingResolvesSymbolicLink | NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
                    [fileManager moveItemAtURL:fileURL toURL:newURL error:NULL];
                }];
            }
        }
        [fileManager removeItemAtURL:workingDirectory error:NULL];
    }];
    [fileManager changeCurrentDirectoryPath:currentDirectoryPath];
}

@end
