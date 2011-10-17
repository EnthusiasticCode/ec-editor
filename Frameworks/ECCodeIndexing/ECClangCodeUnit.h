//
//  ECClangTranslationUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import <ECFoundation/ECItemObserver.h>

@interface ECClangCodeUnit : NSObject <ECCodeCompleter, ECCodeDiagnoser, ECCodeParser, ECItemObserverDelegate>

- (id)initWithIndex:(ECCodeIndex *)index fileURL:(NSURL *)fileURL language:(NSString *)language;

@end
