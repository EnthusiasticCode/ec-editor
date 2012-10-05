//
//  FileSystemFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem.h"
@class RACPropertySyncSubject;

@interface FileSystemItem (File)

/// Returns a RACPropertySyncSubject for NSData properties
- (RACPropertySyncSubject *)content;

/// Returns a RACPropertySyncSubject for NSString properties with the default encoding
- (RACPropertySyncSubject *)contentWithDefaultEncoding;

/// Returns a RACPropertySyncSubject for NSString properties with the given encoding
- (RACPropertySyncSubject *)contentWithEncoding:(NSStringEncoding)encoding;

@end
