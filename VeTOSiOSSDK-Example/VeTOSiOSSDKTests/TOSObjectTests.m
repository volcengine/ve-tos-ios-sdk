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

#import <XCTest/XCTest.h>
#import "TOSTestConstants.h"
#import "TOSTestUtil.h"

@interface TOSObjectTests : XCTestCase <NSURLSessionDelegate, NSURLSessionDataDelegate>
{
    TOSClient *_client;
    NSArray<NSNumber *> *_fileSizes;
    NSArray<NSString *> *_fileNames;
    NSString *_privateBucket;
}

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation TOSObjectTests

- (void)setUp {
    [super setUp];
    
    _privateBucket = TOS_BUCKET;
    
    [self initTOSClient];
    [self initTestFiles];
    [self initSession];
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
    createPrivateInput.tosBucket = _privateBucket;
    [[_client createBucket:createPrivateInput] waitUntilFinished];
    
}



- (void)initTestFiles {
    _fileNames = @[@"file-1k", @"file-10k", @"file-100k", @"file-1m", @"file-5m", @"file-10m", @"fileDirA/", @"fileDirB/", @"file.///", @"file.../././", @"a    b", @" a   b"];
    _fileSizes = @[@1024, @10240, @102400, @(1024 * 1024 * 1), @(1024 * 1024 * 5), @(1024 * 1024 * 10), @1024, @1024, @0, @0, @1024, @1024];
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

- (void)initSession {
    if (_session == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue: [[NSOperationQueue alloc] init]];
    }
}

// 对象名字符集测试
// 1. >=32且<=127的ASCII码单字符对象，上传以及下载
- (void)testAPI_ObjectNameCharacterSet01 {
    NSMutableString *object = [NSMutableString string];
    for (int i = 32; i <= 127; i++) {
        [object appendFormat:@"%c", i];
    }
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = object;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    putInput.tosContent = [readFile readDataToEndOfFile];
    
    // PutObject
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
        TOSPutObjectOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    // GetObject
    TOSGetObjectInput *getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = object;
    task = [_client getObject:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectOutput class]]);
        TOSGetObjectOutput *getOutput = t.result;
        XCTAssertEqual(200, getOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    // DeleteObject
    TOSDeleteObjectInput *deleteInput = [TOSDeleteObjectInput new];
    deleteInput.tosBucket = _privateBucket;
    deleteInput.tosKey = object;
    task = [_client deleteObject:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSDeleteObjectOutput class]]);
        TOSGetObjectOutput *deleteOutput = t.result;
        XCTAssertEqual(204, deleteOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

// 2. 上传包含0-31或128~255的ASCII码单字符且不为UTF8，客户端校验错误
// Objective C's NSASCIIEncoding only supports upto 127 , the character set you are looking for are beyond 127 in ASCII table.
// NSASCIIStringEncoding Strict 7-bit ASCII encoding within 8-bit chars; ASCII values 0…127 only. Available in Mac OS X v10.0 and later. Declared in NSString.h.
- (void)testAPI_ObjectNameCharacterSet02 {
    NSString *nullObject = [NSString stringWithFormat:@"%c", 0];
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = nullObject;
    // PutObject
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.result);
        XCTAssertNotNil(t.error);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid object name, the length must be [1, 696]"]);
        return nil;
    }] waitUntilFinished];
    
    for (int i = 1; i <= 31; i++) {
        NSString *object = [NSString stringWithFormat:@"%c", i];
        TOSPutObjectInput *putInput = [TOSPutObjectInput new];
        putInput.tosBucket = _privateBucket;
        putInput.tosKey = object;
        // PutObject
        TOSTask *task = [_client putObject:putInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.result);
            XCTAssertNotNil(t.error);
            XCTAssertEqual(400, t.error.code);
            XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
            XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: object key is not allowed to contain invisible characters except space"]);
            return nil;
        }] waitUntilFinished];
    }
}

// 3. 对象名长度大于696个字符，客户端校验错误
- (void)testAPI_ObjectNameCharacterSet03 {
    NSMutableString *validObject = [NSMutableString string];
    for (int i = 1; i <= 696; i++) {
        [validObject appendString:@"x"];
    }
    XCTAssertEqual(696, validObject.length);
    
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = validObject;
    // PutObject
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
        TOSPutObjectOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    NSMutableString *invalidObject = [NSMutableString string];
    for (int i = 1; i <= 697; i++) {
        [invalidObject appendString:@"x"];
    }
    XCTAssertEqual(697, invalidObject.length);
    
    putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = invalidObject;
    // PutObject
    task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.result);
        XCTAssertNotNil(t.error);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid object name, the length must be [1, 696]"]);
        return nil;
    }] waitUntilFinished];
}

// 4. 以'/'或'\‘开头的对象，客户端校验错误
- (void)testAPI_ObjectNameCharacterSet04 {
    NSString *beginWithSlash = @"/slash_object";
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = beginWithSlash;
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.result);
        XCTAssertNotNil(t.error);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid object name, the object name can not start with '/' or '\\'"]);
        return nil;
    }] waitUntilFinished];
    
    beginWithSlash = [NSString stringWithFormat:@"%c", 47];
    putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = beginWithSlash;
    task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.result);
        XCTAssertNotNil(t.error);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid object name, the object name can not start with '/' or '\\'"]);
        return nil;
    }] waitUntilFinished];
    
    NSString *beginWithBaskslash = @"\\baskslash_object";
    putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = beginWithBaskslash;
    task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.result);
        XCTAssertNotNil(t.error);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid object name, the object name can not start with '/' or '\\'"]);
        return nil;
    }] waitUntilFinished];
    
    beginWithBaskslash = [NSString stringWithFormat:@"%c", 92];
    putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = beginWithBaskslash;
    task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.result);
        XCTAssertNotNil(t.error);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid object name, the object name can not start with '/' or '\\'"]);
        return nil;
    }] waitUntilFinished];
}

// 5. 上传对象名包含中文，以及其他典型语言（日文、希腊文），正常上传下载
- (void)testAPI_ObjectNameCharacterSet05 {
    NSArray *objectArray = @[@"简体中文", @"繁體中文", @"テスト", @"δοκιμή"];
    
    for (NSString *object in objectArray) {
        TOSPutObjectInput *putInput = [TOSPutObjectInput new];
        putInput.tosBucket = _privateBucket;
        putInput.tosKey = object;
        
        NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSError *readError;
        NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
        XCTAssertNil(readError);
        putInput.tosContent = [readFile readDataToEndOfFile];
        
        // PutObject
        TOSTask *task = [_client putObject:putInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
            TOSPutObjectOutput *putOutput = t.result;
            XCTAssertEqual(200, putOutput.tosStatusCode);
            return nil;
        }] waitUntilFinished];
        
        // GetObject
        TOSGetObjectInput *getInput = [TOSGetObjectInput new];
        getInput.tosBucket = _privateBucket;
        getInput.tosKey = object;
        task = [_client getObject:getInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectOutput class]]);
            TOSGetObjectOutput *getOutput = t.result;
            XCTAssertEqual(200, getOutput.tosStatusCode);
            XCTAssertEqual([self->_fileSizes[0] longLongValue], getOutput.tosContent.length);
            return nil;
        }] waitUntilFinished];
        
        // DeleteObject
        TOSDeleteObjectInput *deleteInput = [TOSDeleteObjectInput new];
        deleteInput.tosBucket = _privateBucket;
        deleteInput.tosKey = object;
        task = [_client deleteObject:deleteInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSDeleteObjectOutput class]]);
            TOSGetObjectOutput *deleteOutput = t.result;
            XCTAssertEqual(204, deleteOutput.tosStatusCode);
            return nil;
        }] waitUntilFinished];
    }
}

// 6. 上传对象名包含特殊字符
- (void)testAPI_ObjectNameCharacterSet06 {
    NSString *specialObject = @"!-_.*()/&$@=;:+ ,?\\{^}%`]>[~<#|'\"";
    
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = specialObject;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    putInput.tosContent = [readFile readDataToEndOfFile];
    
    // PutObject
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
        TOSPutObjectOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    // GetObject
    TOSGetObjectInput *getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = specialObject;
    task = [_client getObject:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectOutput class]]);
        TOSGetObjectOutput *getOutput = t.result;
        XCTAssertEqual(200, getOutput.tosStatusCode);
        XCTAssertEqual([self->_fileSizes[0] longLongValue], getOutput.tosContent.length);
        return nil;
    }] waitUntilFinished];
    
    // DeleteObject
    TOSDeleteObjectInput *deleteInput = [TOSDeleteObjectInput new];
    deleteInput.tosBucket = _privateBucket;
    deleteInput.tosKey = specialObject;
    task = [_client deleteObject:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSDeleteObjectOutput class]]);
        TOSGetObjectOutput *deleteOutput = t.result;
        XCTAssertEqual(204, deleteOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

// Object Test
// 1. 上传对象不包含可选参数
- (void)testAPI_putObject01 {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    putInput.tosContentDisposition = @"中文测试";
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    
    putInput.tosContent = [readFile readDataToEndOfFile];
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = _fileNames[0];
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual([self->_fileSizes[0] longLongValue], headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires);
        return nil;
    }] waitUntilFinished];
}

// 2. 上传对象包含所有参数 TODO: 所有参数
- (void)testAPI_putObject02 {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    
    NSData *tmpData = [@"Hello" dataUsingEncoding:kCFStringEncodingUTF8];
    NSLog(@"Hello    md5: %@", [TOSUtil dataMD5String:tmpData]);
    NSLog(@"Hello base64: %@", [tmpData base64EncodedStringWithOptions:0]);
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
//    NSString *fileMD5 = [[TOSUtil fileMD5String:filePath] lowercaseString];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    
    putInput.tosContent = [readFile readDataToEndOfFile];
    putInput.tosContentLength = [_fileSizes[0] longLongValue];
    putInput.tosACL = TOSACLPublicReadWrite;
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = _fileNames[0];
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual([self->_fileSizes[0] longLongValue], headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires);
        return nil;
    }] waitUntilFinished];
}

// 3. 上传大小为0的对象
- (void)testAPI_putObject03 {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = _fileNames[0];
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual(0, headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires);
        return nil;
    }] waitUntilFinished];
}
// 4. 使用错误的对象访问权限/存储类型上传对象（正交用例）
- (void)testAPI_putObject04 {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    
    putInput.tosACL = TOSACLPublicReadWrite;
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = _fileNames[0];
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual(0, headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires);
        return nil;
    }] waitUntilFinished];
}

// 断点续传
// 1. 断点续传上传
- (void)testAPI_uploadFile01 {
    TOSUploadFileInput *uploadInput = [TOSUploadFileInput new];
    uploadInput.tosBucket = _privateBucket;
    uploadInput.tosKey = _fileNames[0];
    
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
    uploadInput.tosKey = _fileNames[0];
    uploadInput.tosEnableCheckpoint = YES;
    
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
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey = _fileNames[0];
    
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


- (void)testAPI_setObjectMeta {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    
    putInput.tosACL = TOSACLPublicReadWrite;
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSSetObjectMetaInput *setInput = [TOSSetObjectMetaInput new];
    setInput.tosBucket = _privateBucket;
    setInput.tosKey = _fileNames[0];
    setInput.tosMeta = @{@"key":@"value", @"键":@"值"};
    
    task = [_client setObjectMeta:setInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSSetObjectMetaOutput class]]);
        TOSSetObjectMetaOutput *setOutput = t.result;
        XCTAssertEqual(200, setOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = _fileNames[0];
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual(0, headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_copyObject {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    
    putInput.tosACL = TOSACLPublicReadWrite;
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSCopyObjectInput *copyInput = [TOSCopyObjectInput new];
    copyInput.tosBucket = _privateBucket;
    copyInput.tosSrcBucket = _privateBucket;
    copyInput.tosKey = @"copy-object";
    copyInput.tosSrcKey = _fileNames[0];
    
    task = [_client copyObject:copyInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCopyObjectOutput class]]);
        TOSCopyObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = @"copy-object";
    
    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual(0, headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires);
        return nil;
    }] waitUntilFinished];
}

// 携带所有可选参数
- (void)testAPI_putObject {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    putInput.tosACL = TOSACLPublicReadWrite;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    NSData *data = [readFile readDataToEndOfFile];
    putInput.tosContent = data;
    
    
    putInput.tosContentLength = [_fileSizes[0] longLongValue];
    putInput.tosContentMD5 = [TOSUtil base64Md5FromData:data];
    putInput.tosContentType = @"binary/octet-stream";
    putInput.tosCacheControl = @"no-cache";
    
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
    NSDate *date = [formater dateFromString:@"Mon, 04 Jul 2023 02:57:31 GMT"];
    
    putInput.tosExpires = date;
    putInput.tosContentDisposition = @"attachment;filename=中文.txt";
    putInput.tosContentEncoding = @"gzip";
    putInput.tosContentLanguage = @"en-US";
    putInput.tosACL = TOSACLAuthenticatedRead;
//    putInput.tosGrantFullControl = @"id=123";
//    putInput.tosGrantRead = @"id=123";
//    putInput.tosGrantReadAcp = @"id=123";
//    putInput.tosGrantWriteAcp = @"id=123";
    putInput.tosSSECAlgorithm = @"AES256";

    putInput.tosSSECKey = [[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8] base64EncodedStringWithOptions:0];
    putInput.tosSSECKeyMD5 = [TOSUtil base64Md5FromData:[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8]];
    NSLog(@"%@", putInput.tosSSECKey);
    NSLog(@"%@", putInput.tosSSECKeyMD5);
    putInput.tosStorageClass = TOSStorageClassStandard;
    
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSPutObjectOutput class]]);
    TOSPutObjectOutput *putOutput = task.result;
    XCTAssertEqual(200, putOutput.tosStatusCode);
    NSLog(@"ssec-algorithm: %@", putOutput.tosSSECAlgorithm);
    NSLog(@"ssec-key-md5: %@", putOutput.tosSSECKeyMD5);
    NSLog(@"version-id: %@", putOutput.tosVersionID);
    NSLog(@"hash-crc64ecma: %llu", putOutput.tosHashCrc64ecma);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = _fileNames[0];
    headInput.tosSSECAlgorithm = @"AES256";
    headInput.tosSSECKey = [[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8] base64EncodedStringWithOptions:0];
    headInput.tosSSECKeyMD5 = [TOSUtil base64Md5FromData:[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8]];

    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        NSLog(@"%@", t.error);
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual([self->_fileSizes[0] longLongValue], headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires); // TODO: 确认返回值
        return nil;
    }] waitUntilFinished];
}

// 携带所有可选参数
- (void)testAPI_putAndCopyObject {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    putInput.tosACL = TOSACLPublicReadWrite;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    NSData *data = [readFile readDataToEndOfFile];
    putInput.tosContent = data;
    
    
    putInput.tosContentLength = [_fileSizes[0] longLongValue];
    putInput.tosContentMD5 = [TOSUtil base64Md5FromData:data];
    putInput.tosContentType = @"binary/octet-stream";
    putInput.tosCacheControl = @"no-cache";
    
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"EEE, dd MM yyyy HH:mm:ss 'GMT'"];
    NSDate *date = [formater dateFromString:@"Mon, 04 Jul 2023 02:57:31 GMT"];
    
    putInput.tosExpires = date;
    putInput.tosContentDisposition = @"attachment;filename=中文.txt";
    putInput.tosContentEncoding = @"gzip";
    putInput.tosContentLanguage = @"en-US";
    putInput.tosACL = TOSACLAuthenticatedRead;
//    putInput.tosGrantFullControl = @"id=123";
//    putInput.tosGrantRead = @"id=123";
//    putInput.tosGrantReadAcp = @"id=123";
//    putInput.tosGrantWriteAcp = @"id=123";
    putInput.tosSSECAlgorithm = @"AES256";

    putInput.tosSSECKey = [[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8] base64EncodedStringWithOptions:0];
    putInput.tosSSECKeyMD5 = [TOSUtil base64Md5FromData:[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8]];
    NSLog(@"%@", putInput.tosSSECKey);
    NSLog(@"%@", putInput.tosSSECKeyMD5);
    putInput.tosStorageClass = TOSStorageClassStandard;
    
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSPutObjectOutput class]]);
    TOSPutObjectOutput *putOutput = task.result;
    XCTAssertEqual(200, putOutput.tosStatusCode);
    NSLog(@"ssec-algorithm: %@", putOutput.tosSSECAlgorithm);
    NSLog(@"ssec-key-md5: %@", putOutput.tosSSECKeyMD5);
    NSLog(@"version-id: %@", putOutput.tosVersionID);
    NSLog(@"hash-crc64ecma: %llu", putOutput.tosHashCrc64ecma);
    
    NSString *copyKey = [NSString stringWithFormat:@"%@-%@", _fileNames[0], @"copy"];
    TOSCopyObjectInput *copyInput = [TOSCopyObjectInput new];
    copyInput.tosBucket = _privateBucket;
    copyInput.tosSrcBucket = _privateBucket;
    copyInput.tosKey = copyKey;
    copyInput.tosSrcKey = _fileNames[0];
    copyInput.tosACL = TOSACLAuthenticatedRead;
    copyInput.tosExpires = date;
    copyInput.tosContentType = @"binary/octet-stream";
    copyInput.tosCacheControl = @"no-cache";
    copyInput.tosStorageClass = TOSStorageClassStandard;
    copyInput.tosContentEncoding = @"gzip";
    copyInput.tosContentLanguage = @"en-US";
    copyInput.tosContentDisposition = @"attachment;filename=中文.txt";
    copyInput.tosCopySourceSSECKey = [[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8] base64EncodedStringWithOptions:0];;
    copyInput.tosCopySourceSSECAlgorithm = @"AES256";
    copyInput.tosCopySourceSSECKeyMD5 = [TOSUtil base64Md5FromData:[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8]];
//    copyInput.tosServerSideEncryption = @"AES256";

    task = [_client copyObject:copyInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCopyObjectOutput class]]);
        TOSCopyObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];

    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey  = copyKey;
//    headInput.tosSSECAlgorithm = @"AES256";
//    headInput.tosSSECKey = [[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8] base64EncodedStringWithOptions:0];
//    headInput.tosSSECKeyMD5 = [TOSUtil base64Md5FromData:[@"t8e7t9xuyb2hm0747aea3uzxrvla1hm9" dataUsingEncoding:kCFStringEncodingUTF8]];

    task = [_client headObject:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertEqual([self->_fileSizes[0] longLongValue], headOutput.tosContentLength);
        NSLog(@"tosETag: %@", headOutput.tosETag);
        NSLog(@"tosLastModified: %@", headOutput.tosLastModified);
        NSLog(@"tosDeleteMarker: %d", headOutput.tosDeleteMarker);
        NSLog(@"tosSSECAlgorithm: %@", headOutput.tosSSECAlgorithm);
        NSLog(@"tosSSECKeyMD5: %@", headOutput.tosSSECKeyMD5);
        NSLog(@"tosVersionID: %@", headOutput.tosVersionID);
        NSLog(@"tosWebsiteRedirectLocation: %@", headOutput.tosWebsiteRedirectLocation);
        NSLog(@"tosObjectType: %@", headOutput.tosObjectType);
        NSLog(@"tosHashCrc64ecma: %llu", headOutput.tosHashCrc64ecma);
        NSLog(@"tosStorageClass: %@", headOutput.tosStorageClass);
        for (id m in headOutput.tosMeta) {
            NSLog(@"tosMeta, key: %@ - value: %@", m, headOutput.tosMeta[m]);
        }
        NSLog(@"tosContentLength: %lld", headOutput.tosContentLength);
        NSLog(@"tosContentType: %@", headOutput.tosContentType);
        NSLog(@"tosCacheControl: %@", headOutput.tosCacheControl);
        NSLog(@"tosContentDisposition: %@", headOutput.tosContentDisposition);
        NSLog(@"tosContentEncoding: %@", headOutput.tosContentEncoding);
        NSLog(@"tosContentLanguage: %@", headOutput.tosContentLanguage);
        NSLog(@"tosExpire: %@", headOutput.tosExpires); // TODO: 确认返回值
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_appendObject {
    TOSAppendObjectInput *appendInput = [[TOSAppendObjectInput alloc] init];
    appendInput.tosBucket = _privateBucket;
    appendInput.tosKey = _fileNames[3];
    appendInput.tosOffset = 0;
    appendInput.tosACL = TOSACLPublicReadWrite;
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[3]];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    NSData *data = [readFile readDataToEndOfFile];
    
    appendInput.tosContent = data;
    appendInput.tosContentLength = [data length];
    
    TOSTask *task = [_client appendObject:appendInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSAppendObjectOutput class]]);
        TOSAppendObjectOutput *appendOutput = t.result;
        XCTAssertEqual(200, appendOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_listObjectVersions {
    TOSListObjectVersionsInput *listInput = [TOSListObjectVersionsInput new];
    listInput.tosBucket = _privateBucket;
    listInput.tosMaxKeys = 100;
    
    TOSTask *task = [_client listObjectVersions:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListObjectVersionsOutput class]]);
        TOSListObjectVersionsOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_putObjectFromNSData {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *readError;
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    XCTAssertNil(readError);
    
    putInput.tosContent = [readFile readDataToEndOfFile];
    putInput.tosMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"customer-value", @"customer-name", nil];
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
        TOSPutObjectOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
}

- (void)testAPI_putObjectFromDataWithSpecialKey {
    NSArray *specialKeys = @[@"   ", @"a   b", @"a....b", @"a////b", @"\x20\x20", @"  \x22  \x23  ", @"\x7f\x7f", @"!-_.*()/&$@=;:+ ,?\{^}%`]>[~<#|'\"", @"http://unmi.cc?p1=%+&sd &p2=中文", @"dirA/dirB/dirC/dirD"];
    
    for (NSString *key in specialKeys) {
        NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSError *readError;
        NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
        XCTAssertNil(readError);
        
        TOSPutObjectInput *putInput = [TOSPutObjectInput new];
        putInput.tosBucket = _privateBucket;
        putInput.tosKey = key;
        putInput.tosContent = [readFile readDataToEndOfFile];
        
        TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
        
        TOSTask *task = [_client putObject:putInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
            TOSPutObjectOutput *putOutput = t.result;
            XCTAssertEqual(200, putOutput.tosStatusCode);
            return nil;
        }] waitUntilFinished];
        
        XCTAssertTrue([progressTest completeValidateProgress]);
    }
}

- (void)testAPI_putObjectFromFile {
    for (NSInteger idx = 0; idx < _fileNames.count; idx++) {
        NSString *key = _fileNames[idx];
        NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:key];
        
        TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
        putInput.tosBucket = _privateBucket;
        putInput.tosKey = key;
        putInput.tosFilePath = filePath;
        putInput.tosMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"customer-value", @"customer-name", nil];
        
        TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
        
        TOSTask *task = [_client putObjectFromFile:putInput];

        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            NSLog(@"error: %@", t.error);
            XCTAssertNil(t.error);
            XCTAssertNotNil(t.result);
            XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectFromFileOutput class]]);
            TOSPutObjectFromFileOutput *putOutput = t.result;
            XCTAssertEqual(200, putOutput.tosStatusCode);
            return nil;
        }] waitUntilFinished];
        
        XCTAssertTrue([progressTest completeValidateProgress]);
    }
}

- (void)testAPI_putObjectFromFileWithCRC {
    NSString *key = @"put-object-file";
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"zero"];
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = key;
    putInput.tosFilePath = filePath;
    
    TOSTask *task = [_client putObjectFromFile:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);

        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectFromFileOutput class]]);
        TOSPutObjectFromFileOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        
        BOOL isMD5Equal = [self checkMd5WithBucketName:self->_privateBucket objectKey:key localFilePath:filePath];
        XCTAssertTrue(isMD5Equal);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_putObjectWithCustomerMeta {
    NSString *fileName = _fileNames[0];
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:fileName];
    
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = fileName;
    putInput.tosMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"中文", @"        ", @"中  文 Chinese", @"中文 -- Chinese", @"中文 .. -- .. Chinese", @"  hello   ** .  world  ", @"  hello ++ -- === *. world ",
                        @"中文", @"        ", @"中  文 Chinese", @"中文 -- Chinese", @"中文 .. -- .. Chinese", @"with-star", @"special 中文-+=",nil];
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:nil];
    
    putInput.tosContent = [readFile readDataToEndOfFile];
    putInput.tosContentType = @"application/special";
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
        TOSPutObjectOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey = fileName;
    
    [[[_client headObject:headInput] continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertTrue([headOutput.tosContentType isEqualToString:@"application/special"]);
        return nil;
    }] waitUntilFinished];
    
    BOOL isMD5Equal = [self checkMd5WithBucketName:self->_privateBucket objectKey:fileName localFilePath:filePath];
    XCTAssertTrue(isMD5Equal);
}

- (void)testAPI_putObjectWithContentType {
    NSString *fileName = _fileNames[0];
    NSString *filePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:fileName];
    
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = fileName;
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSFileHandle *readFile = [NSFileHandle fileHandleForReadingFromURL:fileURL error:nil];
    
    putInput.tosContent = [readFile readDataToEndOfFile];
    putInput.tosContentType = @"application/special";
    putInput.tosMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"customer-value", @"customer-name", nil];
    
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutObjectOutput class]]);
        TOSPutObjectOutput *putOutput = t.result;
        XCTAssertEqual(200, putOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey = fileName;
    
    [[[_client headObject:headInput] continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadObjectOutput class]]);
        TOSHeadObjectOutput *headOutput = t.result;
        XCTAssertTrue([headOutput.tosContentType isEqualToString:@"application/special"]);
        return nil;
    }] waitUntilFinished];
    
    BOOL isMD5Equal = [self checkMd5WithBucketName:self->_privateBucket objectKey:fileName localFilePath:filePath];
    XCTAssertTrue(isMD5Equal);
}

- (void)testAPI_putObjectACL {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    NSHTTPURLResponse *resp = [self getObjectWithoutAuthentication:[NSString stringWithFormat:@"https://%@.%@/%@", _privateBucket, TOS_ENDPOINT, _fileNames[0]]];
    XCTAssertNotNil(resp);
    XCTAssertEqual(403, resp.statusCode);
    

    TOSPutObjectACLInput *putACLInput = [TOSPutObjectACLInput new];
    putACLInput.tosBucket = _privateBucket;
    putACLInput.tosKey = _fileNames[0];
    putACLInput.tosACL = TOSACLPublicReadWrite;
    task = [_client putObjectAcl:putACLInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    resp = [self getObjectWithoutAuthentication:[NSString stringWithFormat:@"https://%@.%@/%@", _privateBucket, TOS_ENDPOINT, _fileNames[0]]];
    XCTAssertNotNil(resp);
    XCTAssertEqual(200, resp.statusCode);
}


- (void)testAPI_appendObjectFromData {
    NSString *bucket = TOS_BUCKET;
    NSString *object = @"append-object";

    TOSDeleteObjectInput *deleteInput = [TOSDeleteObjectInput new];
    deleteInput.tosBucket = bucket;
    deleteInput.tosKey = object;
    TOSTask *task = [_client deleteObject:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        TOSDeleteObjectOutput *output = t.result;
        XCTAssertEqual(204, output.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    // 创建大文件
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *documentDirectory = [TOSUtil documentDirectory];
    NSMutableData *basePart = [NSMutableData dataWithCapacity:1024];
    for (int j = 0; j < 1024/4; j++) {
        u_int32_t randomBit = arc4random();
        [basePart appendBytes:(void*)&randomBit length:4];
    }
    NSString *name = @"file-10m";
    long size = [@(1024 * 1024 * 10) longLongValue];
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
    
    // append第一次
    TOSAppendObjectInput *appendInput = [TOSAppendObjectInput new];
    appendInput.tosBucket = bucket;
    appendInput.tosKey = object;
    appendInput.tosOffset = 0;
    appendInput.tosContent = [NSData dataWithContentsOfFile:newFilePath];
    appendInput.tosContentLength = size;
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    __block int64_t nextAppendOffset = 0;
    __block uint64_t hashCrc64ecma = 0;
    task = [_client appendObject:appendInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSAppendObjectOutput class]]);
        TOSAppendObjectOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        nextAppendOffset = output.tosNextAppendOffset;
        hashCrc64ecma = output.tosHashCrc64ecma;
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    // append第二次
    appendInput.tosBucket = bucket;
    appendInput.tosKey = object;
    appendInput.tosOffset = nextAppendOffset;
    appendInput.tosContent = [NSData dataWithContentsOfFile:newFilePath];
    appendInput.tosContentLength = size;
    progressTest = [TOSProgressTestUtil new];

    task = [_client appendObject:appendInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSAppendObjectOutput class]]);
        TOSAppendObjectOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    XCTAssertTrue([progressTest completeValidateProgress]);
}

- (void)testAPI_getObejct {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    
    TOSGetObjectInput *getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[0];
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    task = [_client getObject:getInput];
    [task waitUntilFinished];
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSGetObjectOutput class]]);
    TOSGetObjectOutput *getOutput = task.result;
    XCTAssertEqual(200, getOutput.tosStatusCode);
    XCTAssertEqual([_fileSizes[0] intValue], [getOutput.tosContent length]);
}


- (void)testAPI_getObejctACL {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[0];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[0]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    
    TOSGetObjectACLInput *getACLInput = [TOSGetObjectACLInput new];
    getACLInput.tosBucket = _privateBucket;
    getACLInput.tosKey = _fileNames[0];
    
    task = [_client getObjectAcl:getACLInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectACLOutput class]]);
        TOSGetObjectACLOutput *getACLOutput = t.result;
        XCTAssertEqual(200, getACLOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}


- (void)testAPI_getObejctWithReceiveDataBlock {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[3];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[3]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    
    TOSGetObjectInput *getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[3];
    
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    getInput.tosOnReceiveData = ^(NSData *data) {
        NSLog(@"tosOnReceiveData: %lu", [data length]);
    };
    
    task = [_client getObject:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectOutput class]]);
        TOSGetObjectOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        XCTAssertEqual(0, [output.tosContent length]);
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
}

- (void)testAPI_getObjectWithRange {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[3];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[3]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    

    TOSGetObjectInput *getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[3];
    getInput.tosRangeStart = 0;
    getInput.tosRangeEnd = 999;
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];

    task = [_client getObject:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectOutput class]]);
        TOSGetObjectOutput *output = t.result;
        XCTAssertEqual(206, output.tosStatusCode);
        XCTAssertEqual(1000, [output.tosContent length]);
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[3];
    getInput.tosRangeStart = 100;
    getInput.tosRangeEnd = 9;
    task = [_client getObject:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_getObjectByPartiallyReceiveData {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[3];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[3]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSGetObjectInput *getInput = [TOSGetObjectInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[3];
    
    NSMutableData *receiveData = [NSMutableData data];
    getInput.tosOnReceiveData = ^(NSData * _Nonnull data) {
        [receiveData appendData:data];
        NSLog(@"tosOnReceiveData: %lu", [data length]);
    };
    
    task = [_client getObject:getInput];
    
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectOutput class]]);
        TOSGetObjectOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        XCTAssertEqual([self->_fileSizes[3] intValue], [receiveData length]);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_getObjectToFile {
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[3];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[3]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    NSString *tmpFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:@"tmpfile"];
    TOSGetObjectToFileInput *getInput = [[TOSGetObjectToFileInput alloc] init];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[3];
    getInput.tosFilePath = tmpFilePath;
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    task = [_client getObjectToFile:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectToFileOutput class]]);
        TOSGetObjectToFileOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        NSFileManager * fm = [NSFileManager defaultManager];
        XCTAssertTrue([fm fileExistsAtPath:getInput.tosFilePath]);
        int64_t fileLength = [[[fm attributesOfItemAtPath:getInput.tosFilePath
                                                    error:nil] objectForKey:NSFileSize] longLongValue];
        XCTAssertEqual([self->_fileSizes[3] longValue], fileLength);
        [fm removeItemAtPath:tmpFilePath error:nil];
        return nil;
    }] waitUntilFinished];
    
    XCTAssertTrue([progressTest completeValidateProgress]);
}

- (void)testAPI_getObjectOverwriteOldFile {
    // put file
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[3];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[3]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    // put file
    putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[2];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[2]];
    task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    // get file
    NSString *tmpFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:@"tmpfile"];
    TOSGetObjectToFileInput *getInput = [TOSGetObjectToFileInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[3];
    getInput.tosFilePath = tmpFilePath;
    TOSProgressTestUtil *progressTest = [TOSProgressTestUtil new];
    
    task = [_client getObjectToFile:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectToFileOutput class]]);
        TOSGetObjectToFileOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        
        return nil;
    }] waitUntilFinished];
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:tmpFilePath error:nil] fileSize];
    XCTAssertEqual([_fileSizes[3] unsignedLongValue], fileSize);
    
    
    // get file
    getInput = [TOSGetObjectToFileInput new];
    getInput.tosBucket = _privateBucket;
    getInput.tosKey = _fileNames[2];
    getInput.tosFilePath = tmpFilePath;
    progressTest = [TOSProgressTestUtil new];
    task = [_client getObjectToFile:getInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectToFileOutput class]]);
        TOSGetObjectToFileOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        
        return nil;
    }] waitUntilFinished];
    XCTAssertTrue([progressTest completeValidateProgress]);
    
    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:tmpFilePath error:nil] fileSize];
    XCTAssertEqual([_fileSizes[2] unsignedLongValue], fileSize);
    

    BOOL isOk = [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:nil];
    XCTAssertTrue(isOk);
}

- (void)testAPI_listObjects {
    // put file
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[1];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[1]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);

    // put file
    putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[2];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[2]];
    task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);


    // list objects
    TOSListObjectsInput *listInput = [TOSListObjectsInput new];
    listInput.tosBucket = _privateBucket;
    listInput.tosDelimiter = @"";
    listInput.tosMarker = @"";
    listInput.tosMaxKeys = 1000;
    listInput.tosPrefix = @"";

    task = [_client listObjects:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListObjectsOutput class]]);
        TOSListObjectsOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];

    listInput = [TOSListObjectsInput new];
    listInput.tosBucket = _privateBucket;
    listInput.tosDelimiter = @"";
    listInput.tosMarker = @"";
    listInput.tosMaxKeys = 2;
    listInput.tosPrefix = @"";

    task = [_client listObjects:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListObjectsOutput class]]);
        TOSListObjectsOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        return nil;
    }]waitUntilFinished];
    
    listInput = [TOSListObjectsInput new];
    listInput.tosBucket = _privateBucket;
    listInput.tosDelimiter = @"/";
    listInput.tosPrefix = @"fileDir";
    
    task = [_client listObjects:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListObjectsOutput class]]);
        TOSListObjectsOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        return nil;
    }]waitUntilFinished];
}

- (void)testAPI_headObject {
    // put file
    TOSPutObjectFromFileInput *putInput = [TOSPutObjectFromFileInput new];
    putInput.tosBucket = _privateBucket;
    putInput.tosKey = _fileNames[1];
    putInput.tosACL = TOSACLAuthenticatedRead;
    putInput.tosFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:_fileNames[1]];
    TOSTask *task = [_client putObjectFromFile:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = _privateBucket;
    headInput.tosKey = _fileNames[1];
    
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

- (void)testAPI_putObjectWithChinese {
    NSString *bucket = TOS_BUCKET;
    NSString *object = @"中文测试-ChineseTest";
    
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = bucket;
    putInput.tosKey = object;
    putInput.tosMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"meta-value", @"x-tos-meta-key", nil];
    
    NSMutableString *str = [NSMutableString string];
    [str appendString:@"Hello world."];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    putInput.tosContent = data;
    
    TOSTask *task = [_client putObject:putInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            return nil;
    }] waitUntilFinished];
}


- (void)testAPI_deleteMultiObjects {
    NSString *bucket = TOS_BUCKET;
    NSString *object = @"中文测试-ChineseTest";
    NSMutableArray *objs = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        TOSObjectTobeDeleted *obj = [TOSObjectTobeDeleted new];
        obj.tosKey = [NSString stringWithFormat:@"filename-%u", arc4random()];
        obj.tosVersionID = [NSString stringWithFormat:@"version-%u", arc4random()];
        [objs addObject:obj];
    }
    TOSObjectTobeDeleted *obj = [TOSObjectTobeDeleted new];
    obj.tosKey = object;
    [objs addObject: obj];
    
    TOSDeleteMultiObjectsInput *deleteInput = [TOSDeleteMultiObjectsInput new];
    deleteInput.tosBucket = bucket;
    deleteInput.tosObjects = objs;
    deleteInput.tosQuiet = false;
    
    TOSTask *task = [_client deleteMultiObjects:deleteInput];
    
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            if (!t.error) {
                NSLog(@"Delete Object Success.");
                TOSDeleteMultiObjectsOutput *output = t.result;
                NSLog(@"==> Request Header: %@", output.tosHeader);
                NSLog(@"==>      RequestId: %@", output.tosRequestID);
                NSLog(@"==>            id2: %@", output.tosID2);
                NSLog(@"==>     statusCode: %ld", output.tosStatusCode);
                
                NSLog(@"==> Delete Objects: ");
                for (id d in output.tosDeleted) {
                    TOSDeleted *deleted = (TOSDeleted *)d;
                    NSLog(@"  ==>");
                    NSLog(@"    ====>                   key: %@", deleted.tosKey);
                    NSLog(@"    ====>             versionId: %@", deleted.tosVersionID);
                    NSLog(@"    ====>          deleteMarker: %@", deleted.tosDeleteMarker ? @"true" : @"false");
                    NSLog(@"    ====> deleteMarkerVersionId: %@", deleted.tosDeleteMarkerVersionID);
                }
                
                NSLog(@"==> Delete Errors: ");
                for (id e in output.tosError) {
                    TOSDeleteError *delErr = (TOSDeleteError *)e;
                    NSLog(@"  ==>");
                    NSLog(@"    ====>       key: %@", delErr.tosKey);
                    NSLog(@"    ====> versionId: %@", delErr.tosVersionID);
                    NSLog(@"    ====>      code: %@", delErr.tosCode);
                    NSLog(@"    ====>   message: %@", delErr.tosMessage);
                }
            } else {
                NSLog(@"Delete Object Failed.");
            }
            return nil;
        }] waitUntilFinished];
}

- (void)testAPI_invalidObjectKey {
    NSArray *invalidNames = @[@"", @"/key", @"\\key", [TOSTestUtil randomString:697]];
    
    for (NSString *key in invalidNames) {
        NSError *err = nil;
        BOOL isValid =  [TOSUtil isValidObjectName:key withError:&err];
        XCTAssertFalse(isValid);
        XCTAssertNotNil(err);
    }
    
}

- (void)testAPI_validObjectKey {
    NSArray *validNames = @[@"     ",@"a    b", @"k", @".", @"..", @"中文字符", @"中文字符-English", @"!-_.*()/&$@=;:+ ,?\{^}%`]>[~<#|'\"", [TOSTestUtil randomString:1], [TOSTestUtil randomString:696]];
    
    for (NSString *key in validNames) {
        NSError *err = nil;
        BOOL isValid =  [TOSUtil isValidObjectName:key withError:&err];
        XCTAssertTrue(isValid);
        XCTAssertNil(err);
    }
}


- (BOOL)checkMd5WithBucketName:(nonnull NSString *)bucketName objectKey:(nonnull NSString *)objectKey localFilePath:(nonnull NSString *)filePath {
    NSString * tempFilePath = [[TOSUtil documentDirectory] stringByAppendingPathComponent:@"tempfile_for_check"];
    
    TOSGetObjectToFileInput *getInput = [TOSGetObjectToFileInput new];
    getInput.tosBucket = bucketName;
    getInput.tosKey = objectKey;
    getInput.tosFilePath = tempFilePath;
    
    [[[_client getObjectToFile:getInput] continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSGetObjectToFileOutput class]]);
        return nil;
    }] waitUntilFinished];
    
    
    NSString *remoteMD5 = [TOSUtil fileMD5String:tempFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath
                                                   error:nil];
    }
    
    NSString *localMD5 = [TOSUtil fileMD5String:filePath];
    return [remoteMD5 isEqualToString:localMD5];
}

- (NSHTTPURLResponse *)getObjectWithoutAuthentication:(NSString *)httpURL {
    NSMutableURLRequest *getRequest = [[NSMutableURLRequest alloc] init];
    [getRequest setHTTPMethod:@"GET"];
    [getRequest setURL:[NSURL URLWithString:httpURL]];
    __block NSData *retData = nil;
    __block NSHTTPURLResponse *retResponse = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [[_session dataTaskWithRequest:getRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            retData = data;
            retResponse = (NSHTTPURLResponse *)response;
            dispatch_semaphore_signal(semaphore);
        }
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return retResponse;
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
