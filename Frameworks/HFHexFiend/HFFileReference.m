//
//  HFFileReference.m
//  HexFiend_2
//
//  Created by Peter Ammon on 1/23/08.
//  Copyright 2008 ridiculous_fish. All rights reserved.
//

#import "HFFileReference.h"
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#import "HexFiend_Private.h"

#define USE_STAT64 0

static BOOL returnReadError(NSError **error) {
    if (error) {
        int posixCode = errno;
        NSInteger cocoaCode = 0;
        switch (posixCode) {
            case ENOENT:	cocoaCode = NSFileReadNoSuchFileError; break;
            case EPERM:
            case EACCES:	cocoaCode = NSFileReadNoPermissionError; break;
            case ENAMETOOLONG:  cocoaCode = NSFileReadInvalidFileNameError; break;
        }
        if (cocoaCode != 0) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:cocoaCode userInfo:nil];	
        }
        else {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:posixCode userInfo:nil];
        }
        return YES;
    }
    return NO;
}

static BOOL returnFTruncateError(NSError **error) {
    if (error) {
        int posixCode = errno;
        NSInteger cocoaCode = 0;
        switch (posixCode) {
            case ENOSPC:	cocoaCode = NSFileWriteOutOfSpaceError; break;
            case EROFS:		cocoaCode = NSFileWriteVolumeReadOnlyError; break;
        }
        if (cocoaCode != 0) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:cocoaCode userInfo:nil];	
        }
        else {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:posixCode userInfo:nil];
        }
        return YES;
    }
    return NO;
}

@implementation HFFileReference

- (id)initInternalWithPath:(NSString *)path error:(NSError **)error {
    int result;
    REQUIRE_NOT_NULL(path);
    const char* p = [path fileSystemRepresentation];
    if (isWritable) {
        fileDescriptor = open(p, O_RDWR | O_CREAT, 0744);
    }
    else {
        fileDescriptor = open(p, O_RDONLY, 0);
    }
    if (fileDescriptor < 0) {
        returnReadError(error);
        return nil;
    }
#if USE_STAT64
    struct stat64 sb;
    result = fstat64(fileDescriptor, &sb);
#else
    struct stat sb;
    result = fstat(fileDescriptor, &sb);
#endif
    if (result != 0) {
        int err = errno;
        returnReadError(error);
        close(fileDescriptor);
        NSLog(@"Unable to fstat64 file %@. %s.", path, strerror(err));
        return nil;
    }
    fileLength = sb.st_size;
    inode = sb.st_ino;
    HFSetFDShouldCache(fileDescriptor, NO);
    return self;
}

- (id)initWithPath:(NSString *)path error:(NSError **)error {
    if((self = [super init])) {
        isWritable = NO;
        self = [self initInternalWithPath:path error:error];
    }
    return self;
}

- (id)initWritableWithPath:(NSString *)path error:(NSError **)error{
    if((self = [super init])) {
        isWritable = YES;
        self = [self initInternalWithPath:path error:error];
    }
    return self;
}

- (id)initWithPath:(NSString *)path {
    return [self initWithPath:path error:NULL];
}

- (id)initWritableWithPath:(NSString *)path {
    return [self initWritableWithPath:path error:NULL];
}

- (void)readBytes:(unsigned char*)buff length:(NSUInteger)length from:(unsigned long long)pos {
    if (! length) return;
    REQUIRE_NOT_NULL(buff);
    HFASSERT(length <= LONG_MAX);
    HFASSERT(pos <= fileLength);
    HFASSERT(length <= fileLength - pos);
    if (fileDescriptor < 0) [NSException raise:NSInvalidArgumentException format:@"File has already been closed."];
    ssize_t result = pread(fileDescriptor, buff, length, pos);
    if (result != (long)length) {
        [NSException raise:NSGenericException format:@"Read result: %d expected: %u error: %s", result, length, strerror(errno)];
    }    
}

- (int)writeBytes:(const unsigned char *)buff length:(NSUInteger)length to:(unsigned long long)offset {
    HFASSERT(isWritable);
    HFASSERT(fileDescriptor >= 0);
    if (! length) return 0;
    REQUIRE_NOT_NULL(buff);
    HFASSERT(offset <= fileLength);
    HFASSERT(length <= LONG_MAX);
    HFASSERT(offset <= LLONG_MAX);
    int err = 0;
    ssize_t result = pwrite(fileDescriptor, buff, (size_t)length, (off_t)offset);
    HFASSERT(result == -1 || result == (ssize_t)length);
    if (result < 0) err = errno;
    if (result == 0) fileLength = MAX(fileLength, HFSum(length, offset));
    return err;
}

- (void)close {
    if (fileDescriptor >= 0) {
        close(fileDescriptor);
        fileDescriptor = -1;
    }
}

- (void)dealloc {
    [self close];
}

- (unsigned long long)length {
    return fileLength;
}

- (BOOL)setLength:(unsigned long long)length error:(NSError **)error {
    HFASSERT(isWritable);
    HFASSERT(fileDescriptor >= 0);
    HFASSERT(length <= LLONG_MAX);
    int result = ftruncate(fileDescriptor, (off_t)length);
    HFASSERT(result <= 0);
    if (result < 0) {
        returnFTruncateError(error);
    }
    else {
        fileLength = length;
    }
    return result == 0;
}

- (NSUInteger)hash {
    return (NSUInteger)inode;
}

- (BOOL)isEqual:(id)val {
    if (! [val isKindOfClass:[HFFileReference class]]) return NO;
    HFFileReference *ref = (HFFileReference *)val;
    return ref->device == device && ref->inode == inode;
}

@end
