//
//  OnigRegexp+FileBuffer.h
//  ArtCode
//
//  Created by Uri Baghin on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CocoaOniguruma/OnigRegexp.h>
@class FileBuffer;

@interface OnigRegexp (FileBuffer)

- (NSUInteger)numberOfMatchesInFileBuffer:(FileBuffer *)fileBuffer;
- (NSUInteger)numberOfMatchesInFileBuffer:(FileBuffer *)fileBuffer range:(NSRange)range;
- (NSArray *)matchesInFileBuffer:(FileBuffer *)fileBuffer;
- (NSArray *)matchesInFileBuffer:(FileBuffer *)fileBuffer range:(NSRange)range;

- (NSUInteger)replaceMatchesInFileBuffer:(FileBuffer *)fileBuffer withTemplate:(NSString *)replacementTemplate;
- (NSUInteger)replaceMatchesInFileBuffer:(FileBuffer *)fileBuffer range:(NSRange *)range withTemplate:(NSString *)replacementTemplate;

@end
