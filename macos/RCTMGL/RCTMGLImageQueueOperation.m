//
//  RCTMGLImageQueueOperation.m
//  RCTMGL
//
//  Created by Nick Italiano on 2/28/18.
//  Copyright © 2018 Mapbox Inc. All rights reserved.
//

#import "RCTMGLImageQueueOperation.h"


typedef NS_ENUM(NSInteger, RCTMGLImageQueueOperationState) {
    macostate_Initial,
    macostate_CancelledDoNotExecute,
    macostate_Executing, // cancellationBlock is set
    macostate_Finished,

    /* Not sates, just selectors for only and except params */
    macostate_Filter_None,
    macostate_Filter_All,
};

@interface RCTMGLImageQueueOperation()
@property (nonatomic) RCTMGLImageQueueOperationState state;
@end

@implementation RCTMGLImageQueueOperation
{
    RCTImageLoaderCancellationBlock _cancellationBlock;
    BOOL _cancelled;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = macostate_Initial;
        _cancelled = false;
    }
    return self;
}

- (BOOL)isExecuting {
    @synchronized (self) {
        return self.state == macostate_Executing;
    }
}

- (BOOL)isFinished {
    @synchronized (self) {
        return (self.state == macostate_Finished || self.state == macostate_CancelledDoNotExecute);
    }
}

- (BOOL)isCancelled {
    @synchronized (self) {
        return self.state == macostate_CancelledDoNotExecute;
    }
}

- (void)setCancellationBlock:(dispatch_block_t) block {
    _cancellationBlock = block;
}

-(void)callCancellationBlock {
    if (_cancellationBlock) {
        _cancellationBlock();
    }
}

- (RCTMGLImageQueueOperationState)setState:(RCTMGLImageQueueOperationState)newState only:(RCTMGLImageQueueOperationState)only except:(RCTMGLImageQueueOperationState) except
{
    RCTMGLImageQueueOperationState prevState = macostate_Filter_None;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isCancelled"];

    @synchronized (self) {
        BOOL allowed = YES;
        prevState = self.state;
        if (! (only == macostate_Filter_All || prevState == only)) {
            allowed = NO;
        }
        if (prevState == except) {
            allowed = NO;
        }
        if (allowed) {
            self.state = newState;
        }
    }
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isCancelled"];
    return prevState;
}

- (RCTMGLImageQueueOperationState)setState:(RCTMGLImageQueueOperationState)newState only:(RCTMGLImageQueueOperationState)only
{
    return [self setState: newState only:only except:macostate_Filter_None];
}

- (RCTMGLImageQueueOperationState)setState:(RCTMGLImageQueueOperationState)newState except:(RCTMGLImageQueueOperationState)except
{
    return [self setState: newState only:macostate_Filter_All except:except];
}

- (void)start
{
    if (self.state == macostate_CancelledDoNotExecute) {
        return;
    }
    __weak RCTMGLImageQueueOperation *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf setCancellationBlock: [[weakSelf.bridge moduleForName:@"ImageLoader" lazilyLoadIfNecessary:YES]
                             loadImageWithURLRequest:weakSelf.urlRequest
                             size:CGSizeZero
                             scale:weakSelf.scale
                             clipped:YES
                             resizeMode:RCTResizeModeStretch
                             progressBlock:nil
                             partialLoadBlock:nil
                             completionBlock:^void (NSError *error, UIImage *image){
                                weakSelf.completionHandler(error, image);
                                [weakSelf setState:macostate_Finished except:macostate_Finished];
                             }]];
        if ([weakSelf setState:macostate_Executing only:macostate_Initial] == macostate_CancelledDoNotExecute) {
            [weakSelf callCancellationBlock];
        }
    });
}

- (void)cancel
{
    if ([self setState:macostate_CancelledDoNotExecute except:macostate_Finished] == macostate_Executing) {
        [self callCancellationBlock];
    }
}

@end
