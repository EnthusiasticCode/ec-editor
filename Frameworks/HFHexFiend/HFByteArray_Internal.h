#import "HFByteArray.h"

@interface HFByteArray (HFInternal)

- (unsigned long long)_byteSearchBoyerMoore:(HFByteArray *)findBytes inRange:(const HFRange)range forwards:(BOOL)forwards trackingProgress:(HFProgressTracker *)progressTracker;
- (unsigned long long)_byteSearchRollingHash:(HFByteArray *)findBytes inRange:(const HFRange)range forwards:(BOOL)forwards trackingProgress:(HFProgressTracker *)progressTracker;
- (unsigned long long)_byteSearchNaive:(HFByteArray *)findBytes inRange:(const HFRange)range forwards:(BOOL)forwards trackingProgress:(HFProgressTracker *)progressTracker;

- (unsigned long long)_byteSearchSingle:(unsigned char)byte inRange:(const HFRange)range forwards:(BOOL)forwards trackingProgress:(HFProgressTracker *)progressTracker;

@end
