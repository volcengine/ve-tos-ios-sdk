/**
 * Copyright (2022) Beijing Volcano Engine Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "TOSTestUtil.h"
#import <XCTest/XCTest.h>

@implementation TOSTestUtil

+ (void)cleanBucket:(NSString *)bucket withClient:(TOSClient *)client {
    TOSListObjectsInput *listObjectsInput = [TOSListObjectsInput new];
    listObjectsInput.tosBucket = bucket;
    listObjectsInput.tosMaxKeys = 1000;
    TOSTask *task = [client listObjects:listObjectsInput];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull task) {
        TOSListObjectsOutput *listObjectsOutput = task.result;
        for (TOSListedObject *o in listObjectsOutput.tosContents) {
            NSString *key = o.tosKey;
            TOSDeleteObjectInput *deleteInput = [TOSDeleteObjectInput new];
            deleteInput.tosBucket = bucket;
            deleteInput.tosKey = key;
            [[client deleteObject:deleteInput] waitUntilFinished];
        }
        dispatch_semaphore_signal(semaphore);
        return nil;
    }] waitUntilFinished];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    TOSListMultipartUploadsInput *listMultipartUploadsInput = [TOSListMultipartUploadsInput new];
    listMultipartUploadsInput.tosBucket = bucket;
    listMultipartUploadsInput.tosMaxUploads = 1000;
    task = [client listMultipartUploads:listMultipartUploadsInput];
    
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull task) {
        TOSListMultipartUploadsOutput *listMultipartUploadsOutput = task.result;
        for (TOSListedUpload *upload in listMultipartUploadsOutput.tosUploads) {
            NSString *uploadId = upload.tosUploadID;
            NSString *key = upload.tosKey;
            TOSAbortMultipartUploadInput *abortInput = [TOSAbortMultipartUploadInput new];
            abortInput.tosBucket = bucket;
            abortInput.tosKey = key;
            abortInput.tosUploadID = uploadId;
            [[client abortMultipartUpload:abortInput] waitUntilFinished];
        }
        return nil;
    }] waitUntilFinished];
    
    TOSDeleteBucketInput *deleteBucketInput = [TOSDeleteBucketInput new];
    deleteBucketInput.tosBucket = bucket;
    [[client deleteBucket:deleteBucketInput] waitUntilFinished];
}

+ (NSString *)randomString:(int) n {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: n];
    for (int i=0; i < n; i++) {
         [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((uint32_t)[letters length])]];
    }
    return randomString;
}

@end

@interface TOSProgressTestUtil ()

@property (nonatomic, assign) int64_t totalBytesSent;
@property (nonatomic, assign) int64_t totalBytesExpectedToSend;

@end

@implementation TOSProgressTestUtil

- (void)updateTotalBytes:(int64_t)totalBytesSent totalBytesExpected:(int64_t)totalBytesExpectedToSend {
    XCTAssertTrue(totalBytesSent <= totalBytesExpectedToSend);
    self.totalBytesSent = totalBytesSent;
    self.totalBytesExpectedToSend = totalBytesExpectedToSend;
}


- (BOOL)completeValidateProgress {
    return self.totalBytesSent == self.totalBytesExpectedToSend;
}
@end
