/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "TOSCancellationTokenRegistration.h"

#import "TOSCancellationToken.h"

NS_ASSUME_NONNULL_BEGIN

@interface TOSCancellationTokenRegistration ()

@property (nonatomic, weak) TOSCancellationToken *token;
@property (nullable, nonatomic, strong) TOSCancellationBlock cancellationObserverBlock;
@property (nonatomic, strong) NSObject *lock;
@property (nonatomic) BOOL disposed;

@end

@interface TOSCancellationToken (TOSCancellationTokenRegistration)

- (void)unregisterRegistration:(TOSCancellationTokenRegistration *)registration;

@end

@implementation TOSCancellationTokenRegistration

+ (instancetype)registrationWithToken:(TOSCancellationToken *)token delegate:(TOSCancellationBlock)delegate {
    TOSCancellationTokenRegistration *registration = [TOSCancellationTokenRegistration new];
    registration.token = token;
    registration.cancellationObserverBlock = delegate;
    return registration;
}

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    _lock = [NSObject new];
    
    return self;
}

- (void)dispose {
    @synchronized(self.lock) {
        if (self.disposed) {
            return;
        }
        self.disposed = YES;
    }

    TOSCancellationToken *token = self.token;
    if (token != nil) {
        [token unregisterRegistration:self];
        self.token = nil;
    }
    self.cancellationObserverBlock = nil;
}

- (void)notifyDelegate {
    @synchronized(self.lock) {
        [self throwIfDisposed];
        self.cancellationObserverBlock();
    }
}

- (void)throwIfDisposed {
    NSAssert(!self.disposed, @"Object already disposed");
}

@end

NS_ASSUME_NONNULL_END
