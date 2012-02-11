//
//  CodeFile.h
//  ArtCode
//
//  Created by Uri Baghin on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodeView.h"
#import "FileBuffer.h"


@class TMTheme, CodeFileSymbol;

typedef enum {
    CodeFileNormalTextKind,
    CodeFileCommentTextKind,
    CodeFilePreprocessorTextKind,
    CodeFileSymbolTextKind
} CodeFileTextKind;

@interface CodeFile : NSObject <CodeViewDataSource, FileBufferConsumer>

@property (nonatomic, strong, readonly) FileBuffer *fileBuffer;
@property (nonatomic, strong) TMTheme *theme;

- (id)initWithFileURL:(NSURL *)fileURL;

/// Returns a generic kind specification of the text in the given range.
/// This method is used to color minimap lines.
- (CodeFileTextKind)kindOfTextInRange:(NSRange)range;

/// Returns an array of CodeFileSymbol objects representing all the symbols in the file.
- (NSArray *)symbolList;

+ (void)saveFilesToDisk;

@end


/// Represent a symbol returned by the symbolList method in CodeFile.
@interface CodeFileSymbol : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, readonly) NSRange range;

@end