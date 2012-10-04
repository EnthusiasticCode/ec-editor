//
//  FileSystemFile.m
//  ArtCode
//
//  Created by Uri Baghin on 9/26/12.
//
//

#import "FileSystemItem+File.h"
#import "FileSystemItem_Internal.h"
#import "RACEchoSubject.h"


static NSStringEncoding _defaultEncoding = NSUTF8StringEncoding;


@interface FileSystemItem (File_Internal)

// Must be called and delivers on fileSystemScheduler
// The returned subscribable is sent tuples where the first element is the new content, and the second element is the subscribable that sent it originally if applicable
- (id<RACSubscribable>)internalContent;

// Must be called and delivers on fileSystemScheduler
- (id<RACSubscribable>)internalBindContentTo:(id<RACSubscribable>)internalContentSubscribable;

@end

@implementation FileSystemItem (File)

- (id<RACSubscribable>)internalContent {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    return self.contentEcho;
  }];
}

- (id<RACSubscribable>)internalBindContentTo:(id<RACSubscribable>)internalContentSubscribable {
  return [RACSubscribable defer:^id<RACSubscribable>{
    ASSERT_NOT_MAIN_QUEUE();
    return [self.contentEcho echoSubscribable:internalContentSubscribable];
  }];
}

- (id<RACSubscribable>)content {
  return [[self class] coordinateSubscribable:[self internalContent]];
}

- (id<RACSubscribable>)bindContentTo:(id<RACSubscribable>)contentSubscribable {
  return [[self class] coordinateSubscribable:[self internalBindContentTo:[contentSubscribable deliverOn:[[self class] fileSystemScheduler]]]];
}

- (id<RACSubscribable>)contentWithDefaultEncoding {
  return [self contentWithEncoding:_defaultEncoding];
}

- (id<RACSubscribable>)bindContentWithDefaultEncodingTo:(id<RACSubscribable>)contentSubscribable {
  return [self bindContentWithEncoding:_defaultEncoding to:contentSubscribable];
}

- (id<RACSubscribable>)contentWithEncoding:(NSStringEncoding)encoding {
  return [[self content] select:^NSString *(NSData *content) {
    return [[NSString alloc] initWithData:content encoding:encoding];
  }];
}

- (id<RACSubscribable>)bindContentWithEncoding:(NSStringEncoding)encoding to:(id<RACSubscribable>)contentSubscribable {
  return [[self bindContentTo:[contentSubscribable select:^NSData *(NSString *content) {
    return [content dataUsingEncoding:encoding];
  }]] select:^NSString *(NSData *content) {
    return [[NSString alloc] initWithData:content encoding:encoding];
  }];
}

@end
