//
//  Archive.m
//  ArtCode
//
//  Created by Uri Baghin on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArchiveUtilities.h"
#import "archive.h"
#import "archive_entry.h"
#import "NSURL+Utilities.h"

@implementation ArchiveUtilities

+ (void)extractArchiveAtURL:(NSURL *)archiveURL completionHandler:(void (^)(NSURL *))completionHandler {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSURL *temporaryDirectory = [NSURL temporaryDirectory];
    if (![self extractArchiveAtURL:archiveURL toDirectory:temporaryDirectory error:NULL]) {
      [[NSFileManager defaultManager] removeItemAtURL:temporaryDirectory error:NULL];
      temporaryDirectory = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(temporaryDirectory);
    });
  });
}

+ (void)compressFileAtURLs:(NSArray *)urls completionHandler:(void (^)(NSURL *))completionHandler {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSURL *temporaryDirectory = [NSURL temporaryDirectory];
    NSURL *archiveURL = [temporaryDirectory URLByAppendingPathComponent:@"Archive.zip"];
    if (![self compressFileAtURLs:urls toArchiveURL:archiveURL error:NULL]) {
      [[NSFileManager defaultManager] removeItemAtURL:temporaryDirectory error:NULL];
      temporaryDirectory = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(temporaryDirectory);
    });
  });
}

+ (BOOL)extractArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL error:(NSError **)error
{
  ASSERT(archiveURL && directoryURL);
  
  NSString *previousWorkingDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
  [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
  if (![[NSFileManager defaultManager] changeCurrentDirectoryPath:[directoryURL path]]) {
    return NO;
  }
  
  struct archive *archive = archive_read_new();
  archive_read_support_compression_all(archive);
  archive_read_support_format_all(archive);
  if (archive_read_open_filename(archive, [[archiveURL path] fileSystemRepresentation], 10240) < 0)
  {
    archive_read_free(archive);
    return NO;
  }
  struct archive *output = archive_write_disk_new();
  int flags = ARCHIVE_EXTRACT_TIME;
  archive_write_disk_set_options(output, flags);
  archive_write_disk_set_standard_lookup(output);
  
  int returnCode = -1;
  for (;;)
  {
    struct archive_entry *entry;
    returnCode = archive_read_next_header(archive, &entry);
    if (returnCode == ARCHIVE_EOF || returnCode < ARCHIVE_OK)
      break;
    returnCode = archive_write_header(output, entry);
    if (returnCode < ARCHIVE_FAILED)
      break;
    if (returnCode < ARCHIVE_OK)
      continue;
    const void *buff;
    size_t size;
    off_t offset;
    for (;;)
    {
      returnCode = archive_read_data_block(archive, (const void **)&buff, &size, &offset);
      if (returnCode == ARCHIVE_EOF || returnCode < ARCHIVE_OK)
        break;
      returnCode = archive_write_data_block(output, buff, size, offset);
      if (returnCode < ARCHIVE_OK)
        break;
    }
    if (returnCode < ARCHIVE_OK)
      break;
    returnCode = archive_write_finish_entry(output);
    if (returnCode < ARCHIVE_OK)
      break;
  }
  archive_write_close(output);
  archive_write_free(output);
  archive_read_close(archive);
  archive_read_free(archive);
  
  [[NSFileManager defaultManager] changeCurrentDirectoryPath:previousWorkingDirectory];
  
  return returnCode >= 0 ? YES : NO;
}

+ (BOOL)compressFileAtURLs:(NSArray *)urls toArchiveURL:(NSURL *)archiveURL error:(NSError **)error {
  __block int returnCode = ARCHIVE_FATAL;
  // Start the new archive
  struct archive *archive = archive_write_new();
  archive_write_set_compression_lzma(archive);
  archive_write_set_format_zip(archive);
  if (archive_write_open_filename(archive, archiveURL.path.fileSystemRepresentation) < 0) {
    archive_write_free(archive);
    return NO; // no success
  }
  // Support variables
  NSString *previousWorkingDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
  NSString *relativeFilePath = nil;
  // Cycle for every requested file to compress
  for (NSURL *fileURL in urls) {
    // Change directory to the current file's one
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:fileURL.path.stringByDeletingLastPathComponent];
    relativeFilePath = fileURL.lastPathComponent;
    // Actuall compress
    struct archive *disk = archive_read_disk_new();
    archive_read_disk_set_standard_lookup(disk);
    if (archive_read_disk_open(disk, [relativeFilePath fileSystemRepresentation]) < 0) {
      archive_write_free(archive);
      archive_read_free(disk);
      return NO;
    }
    for (;;) {
      struct archive_entry *entry = archive_entry_new();
      returnCode = archive_read_next_header2(disk, entry);
      if (returnCode == ARCHIVE_EOF)
        break;
      archive_read_disk_descend(disk);
      returnCode = archive_write_header(archive, entry);
      if (returnCode == ARCHIVE_FATAL) {
        archive_entry_free(entry);
        break;
      }
      if (returnCode >= 0) {
        FILE *file = fopen(archive_entry_sourcepath(entry), "rb");
        // workaround for a bug in libarchive where an entry can have a path relative to the working directory before archive_read_disk_descend was called
        if (!file)
          file = fopen(strstr(archive_entry_sourcepath(entry), "/") + 1, "rb");
        ASSERT(file);
        char buff[8192];
        size_t length = fread(buff, sizeof(char), sizeof(buff), file);
        while (length > 0) {
          archive_write_data(archive, buff, length);
          length = fread(buff, sizeof(char), sizeof(buff), file);
        }
        fclose(file);
      }
      archive_entry_free(entry);
    }
    
    archive_read_close(disk);
    archive_read_free(disk);
  }
  // Write the archive to disk
  archive_write_close(archive);
  archive_write_free(archive);
  
  // Restore previous directory
  [[NSFileManager defaultManager] changeCurrentDirectoryPath:previousWorkingDirectory];
  
  return returnCode != ARCHIVE_FATAL;
}

@end


@implementation NSURL (ArchiveUtitlies)

- (BOOL)isArchiveURL {
  NSString *ext = self.pathExtension;
  return [ext isEqualToString:@"zip"]
  || [ext isEqualToString:@"rar"]
  || [ext isEqualToString:@"tar"]
  || [ext isEqualToString:@"7zip"]
  || [ext isEqualToString:@"cab"];
}

@end
