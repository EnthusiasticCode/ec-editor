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

+ (void)coordinatedExtractionOfArchiveAtURL:(NSURL *)archiveURL toURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler {
  NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // Prepare to execute the extracting operation
    __block NSError *error = nil;
    [fileCoordinator coordinateReadingItemAtURL:archiveURL options:0 writingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
      [self extractArchiveAtURL:newReadingURL toDirectory:newWritingURL error:&error];
    }];
    // Call the external completion handler
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(error);
    });
  });
}

+ (void)coordinatedCompressionOfFilesAtURLs:(NSArray *)urls toArchiveAtURL:(NSURL *)archiveURL renameIfNeeded:(BOOL)renameIfNeeded completionHandler:(void (^)(NSError *, NSURL *))completionHandler {
  ASSERT(urls.count);
  ASSERT(archiveURL);
  NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    __block NSError *error = nil;
    NSURL *newArchiveURL = archiveURL;
    // Generate valid archiveURL if needed
    if (renameIfNeeded) {
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      NSUInteger duplicateCount = 0;
      __block BOOL alreadyExisting = NO;
      do {
        // Check for existance
        [fileCoordinator coordinateReadingItemAtURL:newArchiveURL options:0 error:&error byAccessor:^(NSURL *newURL) {
          alreadyExisting = [fileManager fileExistsAtPath:newURL.path];
        }];
        // Create a new destination URL if needed
        if (alreadyExisting) {
          newArchiveURL = [archiveURL URLByAddingDuplicateNumber:++duplicateCount];
        }
      } while (alreadyExisting);
    }
    // Prepare to execute the extracting operation
    __block int returnCode = ARCHIVE_FATAL;
    [fileCoordinator prepareForReadingItemsAtURLs:urls options:0 writingItemsAtURLs:@[ newArchiveURL ] options:0 error:&error byAccessor:^(void (^batchCompletionHandler)(void)) {
      // Start the new archive
      struct archive *archive = archive_write_new();
      archive_write_set_compression_lzma(archive);
      archive_write_set_format_zip(archive);
      if (archive_write_open_filename(archive, newArchiveURL.path.fileSystemRepresentation) < 0) {
        archive_write_free(archive);
        return; // no success
      }
      // Support variables
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      NSString *previousWorkingDirectory = [fileManager currentDirectoryPath];
      NSString *relativeFilePath = nil;
      // Cycle for every requested file to compress
      for (NSURL *fileURL in urls) {
        // Change directory to the current file's one
        [fileManager changeCurrentDirectoryPath:fileURL.path.stringByDeletingLastPathComponent];
        relativeFilePath = fileURL.lastPathComponent;
        // Actuall compress
        [fileCoordinator coordinateReadingItemAtURL:fileURL options:0 error:&error byAccessor:^(NSURL *newURL) {
          struct archive *disk = archive_read_disk_new();
          archive_read_disk_set_standard_lookup(disk);
          if (archive_read_disk_open(disk, [relativeFilePath fileSystemRepresentation]) < 0) {
            archive_write_free(archive);
            archive_read_free(disk);
            return;
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
        }];
      }
      // Write the archive to disk
      [fileCoordinator coordinateWritingItemAtURL:newArchiveURL options:0 error:&error byAccessor:^(NSURL *newURL) {
        archive_write_close(archive);
        archive_write_free(archive);
        
        if (returnCode == ARCHIVE_FATAL) {
          [fileManager removeItemAtURL:newURL error:&error];
        }
      }];
      // Restore previous directory
      [fileManager changeCurrentDirectoryPath:previousWorkingDirectory];
      batchCompletionHandler();
    }];
    // Call the external completion handler
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(error, newArchiveURL);
    });
  });
}

+ (BOOL)extractArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL error:(NSError **)error
{
  ASSERT(archiveURL && directoryURL);
  
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSURL *workingDirectory = [NSURL uniqueDirectoryInDirectory:directoryURL];
  if (![fileManager createDirectoryAtURL:workingDirectory withIntermediateDirectories:YES attributes:nil error:error])
    return NO;
  NSString *previousWorkingDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:[workingDirectory path]];
  
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
    if (returnCode < 0)
      break;
    returnCode = archive_write_header(output, entry);
    if (returnCode < 0)
      break;
    const void *buff;
    size_t size;
    off_t offset;
    for (;;)
    {
      returnCode = archive_read_data_block(archive, (const void **)&buff, &size, &offset);
      if (returnCode != 0)
        break;
      returnCode = archive_write_data_block(output, buff, size, offset);
      if (returnCode < 0)
        break;
    }
    if (returnCode < 0)
      break;
    returnCode = archive_write_finish_entry(output);
    if (returnCode < 0)
      break;
  }
  for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:workingDirectory includingPropertiesForKeys:nil options:0 error:error])
  {
    NSURL *destinationURL = [directoryURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
    [fileManager moveItemAtURL:fileURL toURL:destinationURL error:error];
  }
  archive_write_close(output);
  archive_write_free(output);
  archive_read_close(archive);
  archive_read_free(archive);
  
  [fileManager removeItemAtURL:workingDirectory error:error];
  [fileManager changeCurrentDirectoryPath:previousWorkingDirectory];
  
  return returnCode >= 0 ? YES : NO;
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
