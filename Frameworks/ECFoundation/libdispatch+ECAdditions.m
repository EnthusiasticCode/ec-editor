//
//  libdispatch+ECAdditions.m
//  ECFoundation
//
//  Created by Uri Baghin on 12/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "libdispatch+ECAdditions.h"

typedef void dispatch_block_func_t(dispatch_queue_t, dispatch_block_t);

void call_dispatch_block_rethrow_exceptions(dispatch_block_func_t function, dispatch_queue_t queue, dispatch_block_t block);

void call_dispatch_block_rethrow_exceptions(dispatch_block_func_t function, dispatch_queue_t queue, dispatch_block_t block)
{
    __block id thrownObject = nil;
    function(queue, ^{
        @try
        {
            block();
        }
        @catch (id exception)
        {
            thrownObject = exception;
        }
    });
    if (thrownObject)
        @throw thrownObject;
}

void dispatch_sync_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block)
{
    call_dispatch_block_rethrow_exceptions(dispatch_sync, queue, block);
}

void dispatch_barrier_sync_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block)
{
    call_dispatch_block_rethrow_exceptions(dispatch_barrier_sync, queue, block);
}

void dispatch_async_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block)
{
    call_dispatch_block_rethrow_exceptions(dispatch_async, queue, block);
}

void dispatch_barrier_async_rethrow_exceptions(dispatch_queue_t queue, dispatch_block_t block)
{
    call_dispatch_block_rethrow_exceptions(dispatch_barrier_async, queue, block);
}
