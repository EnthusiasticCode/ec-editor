//
//  ACFileDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 10/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileDocument.h"
#import <ECFoundation/ECFileBuffer.h>
#import "ACSyntaxColorer.h"

@interface ACFileDocument ()
{
    ECFileBuffer *_fileBuffer;
}
@end

@implementation ACFileDocument

#pragma mark - Properties

- (ECFileBuffer *)fileBuffer
{
    if (!_fileBuffer)
        _fileBuffer = [[ECFileBuffer alloc] initWithFileURL:self.fileURL];
    return _fileBuffer;
}

#pragma mark - UIDocument methods

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    [[self fileBuffer] replaceCharactersInRange:NSMakeRange(0, [[self fileBuffer] length]) withString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding]];
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [[[self fileBuffer] stringInRange:NSMakeRange(0, [[self fileBuffer] length])] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
