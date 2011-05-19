//
//  HFPasteboardOwner.h
//  HexFiend_2
//
//  Created by Peter Ammon on 1/12/08.
//  Copyright 2008 ridiculous_fish. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HFByteArray, HFProgressTracker;

extern NSString *const HFPrivateByteArrayPboardType;

@interface HFPasteboardOwner : NSObject {
    @private
    HFByteArray *byteArray;
    UIPasteboard *pasteboard; //not retained
    NSUInteger bytesPerLine;
    IBOutlet UIView *progressTrackingWindow;
    IBOutlet UIProgressView *progressTrackingIndicator;
    IBOutlet UITextField *progressTrackingDescriptionTextField;
    HFProgressTracker *progressTracker;
    unsigned long long dataAmountToCopy;
    BOOL retainedSelfOnBehalfOfPboard;
    BOOL backgroundCopyOperationFinished;
    BOOL didStartModalSessionForBackgroundCopyOperation;
}

/* Creates an HFPasteboardOwner to own the given pasteboard with the given types.  Note that the UIPasteboard retains its owner. */
+ ownPasteboard:(UIPasteboard *)pboard forByteArray:(HFByteArray *)array;
- (HFByteArray *)byteArray;

/* Performs a copy to pasteboard with progress reporting. This must be overridden if you support types other than the private pboard type. */
- (void)writeDataInBackgroundToPasteboard:(UIPasteboard *)pboard ofLength:(unsigned long long)length forType:(NSString *)type trackingProgress:(HFProgressTracker *)tracker;

/* UIPasteboard delegate methods, declared here to indicate that subclasses should call super */
- (void)pasteboard:(UIPasteboard *)sender provideDataForType:(NSString *)type;
- (void)pasteboardChangedOwner:(UIPasteboard *)pboard;

/* Useful property that several pasteboard types want to know */
- (void)setBytesPerLine:(NSUInteger)bytesPerLine;
- (NSUInteger)bytesPerLine;

/* For efficiency, Hex Fiend writes pointers to HFByteArrays into pasteboards.  In the case that the user quits and relaunches Hex Fiend, we don't want to read a pointer from the old process, so each process we generate a UUID.  This is constant for the lifetime of the process. */
+ (NSString *)uuid;

/* Unpacks a byte array from a pasteboard, preferring HFPrivateByteArrayPboardType */
+ (HFByteArray *)unpackByteArrayFromPasteboard:(UIPasteboard *)pasteboard;

/* Used to handle the case where copying data will require a lot of memory and give the user a chance to confirm. */
- (unsigned long long)amountToCopyForDataLength:(unsigned long long)numBytes stringLength:(unsigned long long)stringLength;

/* Must be overridden to return the length of a string containing this number of bytes. */
- (unsigned long long)stringLengthForDataLength:(unsigned long long)dataLength;

@end
