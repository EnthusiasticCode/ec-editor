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
    ECFileBuffer *__fileBuffer;
    ACSyntaxColorer *_syntaxColorer;
}
- (ECFileBuffer *)_fileBuffer;
@end

@implementation ACFileDocument

#pragma mark - Properties

@synthesize defaultTextAttributes = _defaultTextAttributes;

- (NSDictionary *)defaultTextAttributes
{
    if (!_defaultTextAttributes)
    {
        CTFontRef defaultFont = CTFontCreateWithName((__bridge CFStringRef)@"Inconsolata-dz", 16, NULL);
        _defaultTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)defaultFont, kCTFontAttributeName,
                                  [NSNumber numberWithInt:0], kCTLigatureAttributeName, nil];
        CFRelease(defaultFont);
    }
    return _defaultTextAttributes;
}

- (ECFileBuffer *)_fileBuffer
{
    if (!__fileBuffer)
        __fileBuffer = [[ECFileBuffer alloc] initWithFileURL:self.fileURL];
    return __fileBuffer;
}

- (ACSyntaxColorer *)syntaxColorer
{
    if (!_syntaxColorer)
    {
        _syntaxColorer = [[ACSyntaxColorer alloc] initWithFileBuffer:[self _fileBuffer]];
        _syntaxColorer.defaultTextAttributes = self.defaultTextAttributes;
    }
    return _syntaxColorer;
}

#pragma mark - UIDocument methods

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    [[self _fileBuffer] replaceCharactersInRange:NSMakeRange(0, [[self _fileBuffer] length]) withAttributedString:[[NSAttributedString alloc] initWithString:[[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding] attributes:self.defaultTextAttributes]];
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [[[self _fileBuffer] stringInRange:NSMakeRange(0, [[self _fileBuffer] length])] dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - Code View DataSource Methods

- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender
{
    return [[self _fileBuffer] length];
}

- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange
{
    [[self syntaxColorer] applySyntaxColoringToRange:stringRange];
    return [[self _fileBuffer] attributedStringInRange:stringRange];
}

- (void)codeView:(ECCodeViewBase *)codeView commitString:(NSString *)commitString forTextInRange:(NSRange)range
{
    [[self _fileBuffer] replaceCharactersInRange:range withString:commitString];
}

@end
