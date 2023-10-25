/**
 * Copyright 2023 Beijing Volcano Engine Technology Ltd.
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

#import <XCTest/XCTest.h>
#import "TOSTestConstants.h"
#import <VeTOSiOSSDK/TOSClient.h>
#import <VeTOSiOSSDK/TOSUtil.h>
#import "TOSTestUtil.h"

@interface TOSUploadFileTests : XCTestCase

{
    TOSClient *_client;
    NSString *_privateBucket;
    NSArray<NSNumber *> *_fileSizes;
    NSArray<NSString *> *_fileNames;
}

@end

@implementation TOSUploadFileTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _privateBucket = TOS_BUCKET;
    [self initTOSClient];
    [self initTestFiles];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [TOSTestUtil cleanBucket:_privateBucket withClient:_client];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)initTOSClient {
    NSString *accessKey = TOS_ACCESSKEY;
    NSString *secretKey = TOS_SECRETKEY;
    TOSCredential *credential = [[TOSCredential alloc] initWithAccessKey:accessKey secretKey:secretKey];
    TOSEndpoint *tosEndpoint = [[TOSEndpoint alloc] initWithURLString:TOS_ENDPOINT withRegion:TOS_REGION];
    TOSClientConfiguration *config = [[TOSClientConfiguration alloc] initWithEndpoint:tosEndpoint credential:credential];
    _client = [[TOSClient alloc] initWithConfiguration:config];
    
    TOSCreateBucketInput *createPrivateInput = [TOSCreateBucketInput new];
    createPrivateInput.tosBucket = _privateBucket;
    [[_client createBucket:createPrivateInput] waitUntilFinished];
    
//    TOSCreateBucketInput *createPublicInput = [TOSCreateBucketInput new];
//    createPublicInput.bucket = _publicBucket;
//    createPublicInput.acl = TOSACLPublicReadWrite;
//    [[_client createBucket:createPublicInput] waitUntilFinished];
}

- (void)initTestFiles {
    _fileNames = @[@"upload-file-1k", @"upload-file-5m", @"upload-file-10m"];
    _fileSizes = @[@1024, @(1024 * 1024 * 5), @(1024 * 1024 * 10)];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *documentDirectory = [TOSUtil documentDirectory];
    for (int i = 0; i < [_fileNames count]; i++) {
        NSMutableData *basePart = [NSMutableData dataWithCapacity:1024];
        for (int j = 0; j < 1024/4; j++) {
            u_int32_t randomBit = arc4random();
            [basePart appendBytes:(void*)&randomBit length:4];
        }
        NSString *name = [_fileNames objectAtIndex:i];
        long size = [[_fileSizes objectAtIndex:i] longLongValue];
        NSString * newFilePath = [documentDirectory stringByAppendingPathComponent:name];
        
        if ([fm fileExistsAtPath:newFilePath]) {
            [fm removeItemAtPath:newFilePath error:nil];
        }
        [fm createFileAtPath:newFilePath contents:nil attributes:nil];
        NSFileHandle *f = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
        for (int k = 0; k < size/1024; k++) {
            [f writeData:basePart];
        }
        [f closeFile];
    }
}

- (void)removeTestFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *documentDirectory = [TOSUtil documentDirectory];
    NSArray *directoryContents = [fm contentsOfDirectoryAtPath:documentDirectory error:NULL];
    for (NSString *e in directoryContents) {
        NSString *tmpPath = [documentDirectory stringByAppendingPathComponent:e];
        [fm removeItemAtPath:tmpPath error:NULL];
    }
}

// 断点续传
// 1. 断点续传上传
- (void)testAPI_uploadFile01 {
    TOSUploadFileInput *uploadInput = [TOSUploadFileInput new];
    uploadInput.tosBucket = _privateBucket;
    uploadInput.tosKey = _fileNames[0];
    uploadInput.tosEnableCheckpoint = NO;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    uploadInput.tosFilePath = filePath;
    
    TOSTask *task = [_client uploadFile:uploadInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSUploadFileOutput class]]);
        TOSUploadFileOutput *uploadOutput = t.result;
        XCTAssertEqual(200, uploadOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_uploadFile02 {
    TOSUploadFileInput *uploadInput = [TOSUploadFileInput new];
    uploadInput.tosBucket = _privateBucket;
    uploadInput.tosKey = _fileNames[2];
    uploadInput.tosEnableCheckpoint = YES;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[2]];
    uploadInput.tosFilePath = filePath;
    
    TOSTask *task = [_client uploadFile:uploadInput];
    
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSUploadFileOutput class]]);
        TOSUploadFileOutput *uploadOutput = t.result;
        XCTAssertEqual(200, uploadOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey = _fileNames[2];
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_uploadFile03 {
    TOSUploadFileInput *uploadInput = [TOSUploadFileInput new];
    uploadInput.tosBucket = _privateBucket;
    uploadInput.tosKey = _fileNames[0];
    
    uploadInput.tosFilePath = @"";
    
    TOSTask *task = [_client uploadFile:uploadInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        return nil;
    }] waitUntilFinished];
}

@end
