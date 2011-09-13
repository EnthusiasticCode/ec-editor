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

/// Returns a queue shared between ECArchive objects
+ (NSOperationQueue *)sharedQueue;

@end

@implementation ECArchive

+ (NSOperationQueue *)sharedQueue
{
    static NSOperationQueue *sharedQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [[NSOperationQueue alloc] init];
        sharedQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
    return sharedQueue;
}

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

- (void)extractToDirectory:(NSURL *)URL completionHandler:(void (^)(BOOL))completionHandler
{
    __block int returnCode;
    NSBlockOperation *extractOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSURL *workingDirectory;
        do
        {
            CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
            CFStringRef uuidString = CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
            workingDirectory = [URL URLByAppendingPathComponent:[@"." stringByAppendingString:(__bridge NSString *)uuidString]];
            CFRelease(uuidString);
            CFRelease(uuid);
        }
        while ([fileManager fileExistsAtPath:[workingDirectory path]]);
        returnCode = ![fileManager createDirectoryAtURL:workingDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        if (returnCode)
            return;
        NSString *currentDirectoryPath = [fileManager currentDirectoryPath];
        [fileManager changeCurrentDirectoryPath:[workingDirectory path]];
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
            for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:workingDirectory includingPropertiesForKeys:nil options:0 error:NULL])
                [fileManager moveItemAtURL:fileURL toURL:[URL URLByAppendingPathComponent:[fileURL lastPathComponent]] error:NULL];
        [fileManager removeItemAtURL:workingDirectory error:NULL];
        [fileManager changeCurrentDirectoryPath:currentDirectoryPath];
    }];
    if (completionHandler)
        [extractOperation setCompletionBlock:^{
            completionHandler(returnCode == ARCHIVE_OK ? YES : NO);
        }];
    [[[self class] sharedQueue] addOperation:extractOperation];
}

@end
