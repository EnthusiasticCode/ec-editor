//
// From http://www.cocoadev.com/index.pl?NSDataCategory
//

#import <Foundation/Foundation.h>

@interface NSData (NSDataExtension)

// ZLIB
- (NSData *) zlibInflate;
- (NSData *) zlibDeflate;

// GZIP
- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

@end
