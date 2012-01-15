//
//  ECArchive.m
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECArchive.h"
#import "archive.h"
#import "archive_entry.h"

@implementation ECArchive

+ (BOOL)extractArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL
{
    ECASSERT(archiveURL);
    struct archive *archive = archive_read_new();
    archive_read_support_compression_all(archive);
    archive_read_support_format_all(archive);
    if (archive_read_open_filename(archive, [[archiveURL path] fileSystemRepresentation], 10240) != ARCHIVE_OK)
    {
        archive_read_finish(archive);
        return NO;
    }
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    __block int returnCode = -1;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    __block NSURL *workingDirectory = nil;
    __block BOOL workingDirectoryAlreadyExists = YES;
    do
    {
        CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
        CFStringRef uuidString = CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
        workingDirectory = [directoryURL URLByAppendingPathComponent:[@"." stringByAppendingString:(__bridge NSString *)uuidString]];
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
    {
        archive_read_finish(archive);
        return NO;
    }
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
            returnCode = archive_read_next_header(archive, &entry);
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
                returnCode = archive_read_data_block(archive, &buff, &size, &offset);
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
            ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
            for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:workingDirectory includingPropertiesForKeys:nil options:0 error:NULL])
            {
                NSURL *destinationURL = [directoryURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
                [fileCoordinator coordinateWritingItemAtURL:destinationURL options:NSFileCoordinatorReadingResolvesSymbolicLink | NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
                    [fileManager moveItemAtURL:fileURL toURL:newURL error:NULL];
                }];
            }
        }
        [fileManager removeItemAtURL:workingDirectory error:NULL];
    }];
    [fileManager changeCurrentDirectoryPath:currentDirectoryPath];
    archive_read_finish(archive);
    return returnCode == ARCHIVE_OK ? YES : NO;
}

+ (BOOL)compressDirectoryAtURL:(NSURL *)directoryURL toArchive:(NSURL *)archiveURL
{
    ECASSERT(directoryURL);
    
    struct archive *archive;
    archive = archive_write_new();
    archive_write_set_compression_lzma(archive);
    archive_write_set_format_zip(archive);
    archive_write_open_filename(archive, [[archiveURL path] fileSystemRepresentation]);
    
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateReadingItemAtURL:directoryURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for (NSURL *fileURL in [fileManager enumeratorAtURL:directoryURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLIsReadableKey, nil] options:0 errorHandler:nil])
        {
            NSNumber *isRegular;
            NSNumber *isReadable;
            [fileURL getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:NULL];
            [fileURL getResourceValue:&isReadable forKey:NSURLIsReadableKey error:NULL];
            if (![isRegular boolValue] || ![isReadable boolValue])
                continue;
            struct archive_entry *entry;
            struct stat st;
            char buff[8192];
            int len;
            FILE *file;            
            const char *filename = [[fileURL path] fileSystemRepresentation];
            
            stat(filename, &st);
            entry = archive_entry_new();
            archive_entry_set_pathname(entry, filename);
            archive_entry_set_size(entry, st.st_size);
            archive_entry_set_filetype(entry, AE_IFREG);
            archive_entry_set_perm(entry, 0644);
            archive_write_header(archive, entry);
            file = fopen(filename, "rb");
            len = fread(buff, sizeof(char), sizeof(buff), file);
            while ( len > 0 ) {
                archive_write_data(archive, buff, len);
                len = fread(buff, sizeof(char), sizeof(buff), file);
            }
            fclose(file);
            archive_entry_free(entry);
        }
    }];
    archive_write_close(archive);
    archive_write_finish(archive);
    return YES;
}

@end
