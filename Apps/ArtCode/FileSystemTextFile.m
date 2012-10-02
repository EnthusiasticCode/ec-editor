//
//  FileSystemTextFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemTextFile.h"

static NSStringEncoding _defaultEncoding = NSUTF8StringEncoding;

@implementation FileSystemTextFile

- (id<RACSubscribable>)content {
  return [self contentWithEncoding:_defaultEncoding];
}

- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable {
  return [self bindContentTo:contentSubscribable withEncoding:_defaultEncoding];
}

- (id<RACSubscribable>)contentWithEncoding:(NSStringEncoding)encoding {
  return [[super content] select:^NSString *(NSData *content) {
    return [[NSString alloc] initWithData:content encoding:encoding];
  }];
}

- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable withEncoding:(NSStringEncoding)encoding {
  return [[super bindContentTo:[contentSubscribable select:^NSData *(NSString *content) {
    return [content dataUsingEncoding:encoding];
  }]] select:^NSString *(NSData *content) {
    return [[NSString alloc] initWithData:content encoding:encoding];
  }];
}

@end
