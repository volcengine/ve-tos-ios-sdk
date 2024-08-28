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
#import <VeTOSiOSSDK/VeTOSiOSSDK.h>
#import <VeTOSiOSSDK/TOSUtil.h>
#import "TOSTestConstants.h"
#import "TOSTestUtil.h"


@interface TOSPutStreamTests : XCTestCase

{
    TOSClient *_client;
    NSArray<NSNumber *> *_fileSizes;
    NSArray<NSString *> *_fileNames;
    NSString *_privateBucket;
}

@end

@implementation TOSPutStreamTests

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

- (void)initTOSClient {
    NSString *accessKey = TOS_ACCESSKEY;
    NSString *secretKey = TOS_SECRETKEY;
    TOSCredential *credential = [[TOSCredential alloc] initWithAccessKey:accessKey secretKey:secretKey];
    TOSEndpoint *tosEndpoint = [[TOSEndpoint alloc] initWithURLString:TOS_ENDPOINT withRegion:TOS_REGION];
    TOSClientConfiguration *config = [[TOSClientConfiguration alloc] initWithEndpoint:tosEndpoint credential:credential];
    _client = [[TOSClient alloc] initWithConfiguration:config];
    
    TOSCreateBucketInput *createPrivateInput = [TOSCreateBucketInput new];
    createPrivateInput.tosBucket = TOS_BUCKET;
    [[_client createBucket:createPrivateInput] waitUntilFinished];
}

- (void)initTestFiles {
    _fileNames = @[@"file-1k", @"file-10k", @"file-100k", @"file-1m", @"file-5m", @"file-10m", @"empty-file"];
    _fileSizes = @[@1024, @10240, @102400, @(1024 * 1024 * 1), @(1024 * 1024 * 5), @(1024 * 1024 * 10), @0];
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

- (void)testAPI_invalidStream {
    // nil input stream
    NSInputStream *nilStream = nil;
    TOSPutObjectFromStreamInput *putInput = [TOSPutObjectFromStreamInput new];
    putInput.tosBucket = @"test";
    putInput.tosKey = @"test";
    putInput.tosInputStream = nilStream;
    TOSTask *task = [_client putObjectFromStream:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        NSLog(@"error: %@", t.error);
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"input stream is nil"]);
        return nil;
    }] waitUntilFinished];
    
    // opened stream
    NSInputStream *openedStream = [NSInputStream inputStreamWithData: [@"" dataUsingEncoding:NSUTF8StringEncoding]];
    [openedStream open];
    TOSPutObjectFromStreamInput *putInput2 = [TOSPutObjectFromStreamInput new];
    putInput2.tosBucket = @"test";
    putInput2.tosKey = @"test";
    putInput2.tosInputStream = openedStream;
    
    TOSTask *task2 = [_client putObjectFromStream:putInput2];
    [[task2 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        NSLog(@"error: %@", t.error);
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"input stream status is invalid (2)"]);
        return nil;
    }] waitUntilFinished];
}

// 文件流
- (void)testAPI_FromFile {
    for (NSInteger idx = 0; idx < _fileNames.count; idx++) {
        NSString *key = _fileNames[idx];
        NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:key];
        
        NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        
        TOSPutObjectFromStreamInput *putInput = [TOSPutObjectFromStreamInput new];
        putInput.tosBucket = _privateBucket;
        putInput.tosKey = key;
        putInput.tosInputStream = inputStream;
        
        putInput.tosUploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            NSLog(@"%lld, %lld, %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
        };
        
        TOSTask *task = [_client putObjectFromStream:putInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            NSLog(@"error: %@", t.error);
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectFromStreamOutput class]]);
            TOSPutObjectFromStreamOutput *putOutput = t.result;
            XCTAssertEqual(200, putOutput.tosStatusCode);
            return nil;
        }] waitUntilFinished];
        
        TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
        headInput.tosBucket = _privateBucket;
        headInput.tosKey = key;
        TOSTask *headTask = [_client headObject:headInput];
        [[headTask continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
            TOSHeadObjectOutput *headOutput = t.result;
            XCTAssertEqual(200, headOutput.tosStatusCode);
            XCTAssertEqual([self->_fileSizes[idx] longLongValue], headOutput.tosContentLength);
            return nil;
        }] waitUntilFinished];
    }
}

// 内存数据流
- (void)testAPI_FromNSData {
    for (NSInteger idx = 0; idx < _fileNames.count; idx++) {
        // 构建NSInputStreams
        NSString *key = _fileNames[idx];
        NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:key];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSError *readError;
        NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
        XCTAssertNil(readError);
        NSData *fileData = [readFile readDataToEndOfFile];
        
        NSInputStream *inputStream = [NSInputStream inputStreamWithData:fileData];
        
        // putObjectFromStream
        NSString *newKey = [key stringByAppendingString:@"-nsdata"];
        TOSPutObjectFromStreamInput *putInput = [TOSPutObjectFromStreamInput new];
        putInput.tosBucket = _privateBucket;
        putInput.tosKey = newKey;
        putInput.tosInputStream = inputStream;
        putInput.tosUploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            NSLog(@"%lld, %lld, %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
        };
        TOSTask *task = [_client putObjectFromStream:putInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            NSLog(@"error: %@", t.error);
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectFromStreamOutput class]]);
            TOSPutObjectFromStreamOutput *putOutput = t.result;
            XCTAssertEqual(200, putOutput.tosStatusCode);
            return nil;
        }] waitUntilFinished];
        
        TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
        headInput.tosBucket = _privateBucket;
        headInput.tosKey = newKey;
        TOSTask *headTask = [_client headObject:headInput];
        [[headTask continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
            TOSHeadObjectOutput *headOutput = t.result;
            XCTAssertEqual(200, headOutput.tosStatusCode);
            XCTAssertEqual([self->_fileSizes[idx] longLongValue], headOutput.tosContentLength);
            return nil;
        }] waitUntilFinished];
    }
}

// http网络流
- (void)testAPI_InputStreamFromHTTPURL {
    // 构建http输入流
    CFStringRef httpMethod = (__bridge CFStringRef)@"GET";
    CFStringRef urlString = (__bridge CFStringRef)TOS_STREAM_URL;
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, urlString, NULL);
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, httpMethod, url, kCFHTTPVersion1_1);
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    NSInputStream *inputStream = (__bridge_transfer NSInputStream *) readStream;

    NSLog(@"inputStream status: %ld", inputStream.streamStatus);
    NSLog(@"inputStream error: %@", inputStream.streamError);
    
    NSString *key = @"custom-stream-obj.png";
    TOSPutObjectFromStreamInput *putInput = [TOSPutObjectFromStreamInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = key;
    putInput.tosInputStream = inputStream;
    putInput.tosUploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    };
    TOSTask *task = [_client putObjectFromStream:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        NSLog(@"error: %@", t.error);
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectFromStreamOutput class]]);
        TOSPutObjectFromStreamOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey = key;
    TOSTask *headTask = [_client headObject:headInput];
    [[headTask continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

@end
