//
//  libdispatch+ECAdditions.h
//  ECFoundation
//
//  Created by Uri Baghin on 12/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

/// These functions call the equivalent dispatch functions capturing exceptions and rethrowing them
void dispatch_sync_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block);
void dispatch_barrier_sync_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block);
void dispatch_async_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block);
void dispatch_barrier_async_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block);
