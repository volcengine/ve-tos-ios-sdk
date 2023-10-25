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
#import "TOSTestConstants.h"
#import "TOSTestUtil.h"


@interface PreSignTests : XCTestCase <NSURLSessionDelegate>

{
    TOSClient *_client;
}

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation PreSignTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [self initTOSClient];
    [self initSession];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [TOSTestUtil cleanBucket:TOS_BUCKET withClient:_client];
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

- (void)initSession {
    if (_session == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue: [[NSOperationQueue alloc] init]];
    }
}

// 预签名
// 1. 使用预签名URL完成上传对象、复制对象、查询对象元数据、设置对象元数据、下载对象、列举对象、删除对象的HTTP请求
// 2. 使用预签名URL完成创建分段上传任务、上传段、复制段、列举段、合并段、列举分段上传任务、取消分段上传任务的HTTP
// 3. 使用预签名URL，实际HTTP请求时指定不匹配的参数

- (void)testAPI_preSignGetObject {
    // put file
    TOSPutObjectInput *putInput = [[TOSPutObjectInput alloc] init];
    putInput.tosBucket = TOS_BUCKET;
    putInput.tosKey = TOS_FILE;
    
    NSMutableString *str = [NSMutableString string];
    [str appendString:@"Hello world. Hello Tos."];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    putInput.tosContent = data;
    
    TOSTask *task = [_client putObject:putInput];
    [task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        if (!t.error) {
            NSLog(@"Put Object Success.");
            TOSPutObjectOutput *output = (TOSPutObjectOutput *)t.result;
            NSLog(@"etag: %@", output.tosETag);
            NSLog(@"ssealgorithm: %@", output.tosSSECAlgorithm);
            NSLog(@"ssekeymd5: %@", output.tosSSECKeyMD5);
            NSLog(@"hashcrc64ecma: %lld", output.tosHashCrc64ecma);
        } else {
            NSLog(@"Put Object Failed, error: %@", t.error);
        }
        return nil;
    }];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSPreSignedURLInput *input = [TOSPreSignedURLInput new];
    input.tosBucket = TOS_BUCKET;
    input.tosKey = TOS_FILE;
    input.tosHttpMethod = TOSHTTPMethodTypeGet;
    
    task = [_client preSignedURL:input];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSPreSignedURLOutput *output = task.result;
    
    XCTAssertTrue([output.tosSignedUrl containsString:input.tosBucket]);
    XCTAssertTrue([output.tosSignedUrl containsString:input.tosKey]);

    NSMutableURLRequest *getRequest = [[NSMutableURLRequest alloc] init];
    [getRequest setHTTPMethod:@"GET"];
    [getRequest setURL:[NSURL URLWithString:output.tosSignedUrl]];
    
    __block NSData *retData = nil;
    __block NSHTTPURLResponse *retResponse = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [[_session dataTaskWithRequest:getRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertNil(error);
        retData = data;
        retResponse = (NSHTTPURLResponse *)response;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    XCTAssertEqual(200, retResponse.statusCode);
    XCTAssertNotNil(retData);
}

- (void)testAPI_preSignGetRangeObject {
    // put file
    TOSPutObjectInput *putInput = [[TOSPutObjectInput alloc] init];
    putInput.tosBucket = TOS_BUCKET;
    putInput.tosKey = TOS_FILE;
    
    NSMutableString *str = [NSMutableString string];
    [str appendString:@"Hello world. Hello Tos."];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    putInput.tosContent = data;
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSPreSignedURLInput *input = [TOSPreSignedURLInput new];
    input.tosBucket = TOS_BUCKET;
    input.tosKey = TOS_FILE;
    input.tosHeader = @{@"Range" : @"bytes=1-10"};
    input.tosHttpMethod = TOSHTTPMethodTypeGet;
    
    task = [_client preSignedURL:input];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSPreSignedURLOutput *output = task.result;
    XCTAssertTrue([output.tosSignedUrl containsString:input.tosBucket]);
    XCTAssertTrue([output.tosSignedUrl containsString:input.tosKey]);

    NSMutableURLRequest *getRequest = [[NSMutableURLRequest alloc] init];
    [getRequest setHTTPMethod:@"GET"];
    [getRequest setURL:[NSURL URLWithString:output.tosSignedUrl]];
    [getRequest setValue:@"bytes=1-10" forHTTPHeaderField:@"Range"];
    
    __block NSData *retData = nil;
    __block NSHTTPURLResponse *retResponse = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [[_session dataTaskWithRequest:getRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertNil(error);
        retData = data;
        retResponse = (NSHTTPURLResponse *)response;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    XCTAssertEqual(206, retResponse.statusCode);
    XCTAssertNotNil(retData);
    XCTAssertEqual(10, [retData length]);
}

- (void)testAPI_preSignPutObjectFromNSData {
    TOSPreSignedURLInput *input = [TOSPreSignedURLInput new];
    input.tosBucket = TOS_BUCKET;
    input.tosKey = @"pre-sign-put-file-from-data";
    input.tosHttpMethod = TOSHTTPMethodTypePut;
    input.tosHeader = @{@"x-tos-meta-key-1" : @"meta-value-1", @"x-tos-meta-key-2" : @"meta-value-2"};
    
    TOSTask *task = [_client preSignedURL:input];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSPreSignedURLOutput *output = task.result;
    XCTAssertTrue([output.tosSignedUrl containsString:input.tosBucket]);
    XCTAssertTrue([output.tosSignedUrl containsString:input.tosKey]);

    NSString *tmpStr = @"Presign url to put object from NSData.";
    NSData *tmpData = [tmpStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *putRequest = [[NSMutableURLRequest alloc] init];
    [putRequest setHTTPBody:tmpData];
    [putRequest setHTTPMethod:@"PUT"];
    [putRequest setURL:[NSURL URLWithString:output.tosSignedUrl]];
    [putRequest setValue:@"meta-value-1" forHTTPHeaderField:@"x-tos-meta-key-1"];
    [putRequest setValue:@"meta-value-2" forHTTPHeaderField:@"x-tos-meta-key-2"];
    
    __block NSData *retData = nil;
    __block NSHTTPURLResponse *retResponse = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [[_session dataTaskWithRequest:putRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        XCTAssertNil(error);
        retData = data;
        retResponse = (NSHTTPURLResponse *)response;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    XCTAssertEqual(200, retResponse.statusCode);
    
    TOSPutObjectOutput *putOutput = [TOSPutObjectOutput new];

    [[retResponse allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *kk = [(NSString *)key lowercaseString];
        if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-algorithm"]) {
            putOutput.tosSSECAlgorithm = obj;
        } else if ([kk isEqualToString:@"x-tos-server-side-encryption-customer-key-md5"]) {
            putOutput.tosSSECKeyMD5 = obj;
        } else if ([kk isEqualToString:@"x-tos-version-id"]) {
            putOutput.tosVersionID = obj;
        } else if ([kk isEqualToString:@"x-tos-hash-crc64ecma"]) {
            putOutput.tosHashCrc64ecma = strtoull([obj UTF8String], NULL, 0);
        } else if ([kk isEqualToString:@"etag"]) {
            putOutput.tosETag = obj;
        }
    }];

    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = TOS_BUCKET;
    headInput.tosKey = @"pre-sign-put-file-from-data";
    task = [_client headObject:headInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSHeadObjectOutput *headOutput = task.result;
    XCTAssertEqual(2, [headOutput.tosMeta count]);
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    if (!challenge) {
        return;
    }
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    /*
     * Gets the host name
     */
    
    NSString * host = [[task.currentRequest allHTTPHeaderFields] objectForKey:@"Host"];
    if (!host) {
        host = task.currentRequest.URL.host;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *crediential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (completionHandler) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, crediential);
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    // Uses the default evaluation for other challenges.
    completionHandler(disposition,credential);
}

@end
