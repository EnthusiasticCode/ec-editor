//
//  FileSystemTextFile.h
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemFile.h"

@interface FileSystemTextFile : FileSystemFile

- (id<RACSubscribable>)contentWithEncoding:(NSStringEncoding)encoding;
- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable withEncoding:(NSStringEncoding)encoding;

@end
