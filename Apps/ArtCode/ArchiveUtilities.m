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

+ (BOOL)extractArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL
{
  ASSERT(archiveURL && directoryURL);
  
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSURL *workingDirectory = [NSURL uniqueDirectoryInDirectory:directoryURL];
  if (![fileManager createDirectoryAtURL:workingDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
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
  for (NSURL *fileURL in [fileManager contentsOfDirectoryAtURL:workingDirectory includingPropertiesForKeys:nil options:0 error:NULL])
  {
    NSURL *destinationURL = [directoryURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
    [fileManager moveItemAtURL:fileURL toURL:destinationURL error:NULL];
  }
  archive_write_close(output);
  archive_write_free(output);
  archive_read_close(archive);
  archive_read_free(archive);
  
  [fileManager removeItemAtURL:workingDirectory error:NULL];
  [fileManager changeCurrentDirectoryPath:previousWorkingDirectory];
  
  return returnCode >= 0 ? YES : NO;
}

+ (BOOL)compressDirectoryAtURL:(NSURL *)directoryURL toArchive:(NSURL *)archiveURL
{
  ASSERT(directoryURL && archiveURL);
  
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  ASSERT([[fileManager attributesOfItemAtPath:[directoryURL path] error:NULL] fileType] == NSFileTypeDirectory);
  NSString *previousWorkingDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:[directoryURL path]];
  
  struct archive *archive = archive_write_new();
  archive_write_set_compression_lzma(archive);
  archive_write_set_format_zip(archive);
  if (archive_write_open_filename(archive, [[archiveURL path] fileSystemRepresentation]) < 0)
  {
    archive_write_free(archive);
    return NO;
  }
  
  int returnCode = ARCHIVE_FATAL;
  for (NSString *relativeFilePath in [fileManager contentsOfDirectoryAtPath:[directoryURL path] error:NULL])
  {
    struct archive *disk = archive_read_disk_new();
    archive_read_disk_set_standard_lookup(disk);
    if (archive_read_disk_open(disk, [relativeFilePath fileSystemRepresentation]) < 0)
    {
      archive_write_free(archive);
      archive_read_free(disk);
      return NO;
    }
    for (;;)
    {
      struct archive_entry *entry = archive_entry_new();
      returnCode = archive_read_next_header2(disk, entry);
      if (returnCode == ARCHIVE_EOF)
        break;
      archive_read_disk_descend(disk);
      returnCode = archive_write_header(archive, entry);
      if (returnCode == ARCHIVE_FATAL)
      {
        archive_entry_free(entry);
        break;
      }
      if (returnCode >= 0)
      {
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
  archive_write_close(archive);
  archive_write_free(archive);
  
  if (returnCode == ARCHIVE_FATAL)
    [fileManager removeItemAtURL:archiveURL error:NULL];
  [fileManager changeCurrentDirectoryPath:previousWorkingDirectory];
  
  return returnCode != ARCHIVE_FATAL ? YES : NO;
}

@end


//for (NSString *relativeFilePath in [fileManager subpathsOfDirectoryAtPath:[directoryURL path] error:NULL])
//{
//    NSString *fileType = [[fileManager attributesOfItemAtPath:relativeFilePath error:NULL] fileType];
//    if (!fileType || (fileType != NSFileTypeDirectory && fileType != NSFileTypeRegular))
//        continue;
//    
//    struct stat st;        
//    stat([relativeFilePath fileSystemRepresentation], &st);
//    struct archive_entry *entry = archive_entry_new();
//    archive_entry_set_pathname(entry, [relativeFilePath fileSystemRepresentation]);
//    archive_entry_set_size(entry, st.st_size);
//    archive_entry_set_filetype(entry, fileType == NSFileTypeDirectory ? AE_IFDIR : AE_IFREG);
//    archive_entry_set_perm(entry, 0644);
//    archive_write_header(archive, entry);
//    FILE *file = fopen([relativeFilePath fileSystemRepresentation], "rb");
//    char buff[8192];
//    int fileSize = fread(buff, sizeof(char), sizeof(buff), file);
//    while ( fileSize > 0 ) {
//        archive_write_data(archive, buff, fileSize);
//        fileSize = fread(buff, sizeof(char), sizeof(buff), file);
//    }
//    fclose(file);
//    archive_entry_free(entry);
//}
