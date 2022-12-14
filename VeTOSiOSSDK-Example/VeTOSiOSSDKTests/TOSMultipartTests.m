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
#import <VeTOSiOSSDK/VeTOSiOSSDK.h>
#import <VeTOSiOSSDK/TOSUtil.h>
#import "TOSTestConstants.h"
#import "TOSTestUtil.h"

@interface TOSMultipartTests : XCTestCase

{
    TOSClient *_client;
    NSString *_filePath;
}

@end

@implementation TOSMultipartTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [self initTOSClient];
    [self initTestFile];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self clearTestFile];
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

- (void)initTestFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *documentDirectory = [TOSUtil documentDirectory];
    NSMutableData *basePart = [NSMutableData dataWithCapacity:1024];
    for (int j = 0; j < 1024/4; j++) {
        u_int32_t randomBit = arc4random();
        [basePart appendBytes:(void*)&randomBit length:4];
    }
    NSString *name = @"file-6m";
    long size = [@(1024 * 1024 * 6) longLongValue];
    _filePath = [documentDirectory stringByAppendingPathComponent:name];
    if ([fm fileExistsAtPath:_filePath]) {
        [fm removeItemAtPath:_filePath error:nil];
    }
    [fm createFileAtPath:_filePath contents:nil attributes:nil];
    NSFileHandle *f = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    for (int k = 0; k < size/1024; k++) {
        [f writeData:basePart];
    }
    [f closeFile];
}

- (void)clearTestFile {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:_filePath error:nil];
}

// ????????????
// 1. ??????100???????????????????????????10???????????????????????????????????????10?????????????????????
// 2. ??????????????????3???????????????????????????????????????Delimiter??????????????????????????????????????????
// 3. ???????????????????????????????????????
// 4. ??????????????????????????????????????????
// 5. ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
// 6. ??????????????????????????????????????????/???????????????????????????/??????????????????UploadID
// 7. ???????????????????????????????????????????????????????????????????????????UploadPart/UploadPartFromFile??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
// 8. ????????????????????????????????????????????????????????????????????????UploadPart/UploadPartFromFile??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
// 9. ???????????????????????????/?????????????????????????????????/????????????????????????UploadID
// 10. ???????????????????????????/????????????????????????????????????/???????????????????????????UploadID
// 11. ???????????????????????????/????????????????????????????????????/???????????????????????????UploadID
// 12. ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
// 13. ????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
// 14. ???????????????????????????/????????????????????????????????????/???????????????????????????UploadID/???????????????????????????????????????/??????????????????????????????????????????/??????????????????????????????VersionID


- (void)testAPI_multipartUpload {
    TOSTask *task = nil;
    // 1. ????????????????????????
    TOSCreateMultipartUploadInput *createInput = [TOSCreateMultipartUploadInput new];
//    create.bucket = TOS_BUCKET;
    createInput.tosBucket = TOS_BUCKET;
    createInput.tosKey = [NSString stringWithFormat:@"copy-src-file"];
    task = [_client createMultipartUpload:createInput];
    [task waitUntilFinished];

    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSCreateMultipartUploadOutput *createOutput = task.result;
    XCTAssertEqual(200, createOutput.tosStatusCode);
    
    // 2. ????????????
    const int partSize = 3;
    NSMutableArray *parts = [NSMutableArray array];
    for (int i = 1; i <= partSize; i++) {
        TOSUploadPartInput *upload = [TOSUploadPartInput new];
        upload.tosKey = createOutput.tosKey;
        upload.tosBucket = createOutput.tosBucket;
        upload.tosUploadID = createOutput.tosUploadID;
        upload.tosPartNumber = i;
        upload.tosContent = [NSData dataWithContentsOfFile:_filePath];
        task = [_client uploadPart:upload];
        [task waitUntilFinished];
        
        XCTAssertNil(task.error);
        XCTAssertNotNil(task.result);
        TOSUploadPartOutput *upOutput = task.result;
        
        NSString *mString = upOutput.tosETag;
        mString = [mString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        upOutput.tosETag = mString;
        
        TOSUploadedPart *uploadedPart = [TOSUploadedPart new];
        uploadedPart.tosETag = mString;
        uploadedPart.tosPartNumber = upOutput.tosPartNumber;
                         
        XCTAssertEqual(200, upOutput.tosStatusCode);
        [parts addObject:upOutput];
    }
    XCTAssertEqual(partSize, [parts count]);
    
    // 3. ????????????
    TOSCompleteMultipartUploadInput *complete = [TOSCompleteMultipartUploadInput new];
    complete.tosBucket = createOutput.tosBucket;
    complete.tosKey = createOutput.tosKey;
    complete.tosUploadID = createOutput.tosUploadID;
    NSMutableArray *comArray = [NSMutableArray array];
    for (TOSUploadPartOutput *p in parts) {
        TOSUploadedPart *comPart = [TOSUploadedPart new];
        comPart.tosPartNumber = p.tosPartNumber;
        comPart.tosETag = p.tosETag;
        [comArray addObject:comPart];
    }
    XCTAssertEqual(partSize, [comArray count]);
    complete.tosParts = comArray;
    task = [_client completeMultipartUpload:complete];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSCompleteMultipartUploadOutput *comOutput = task.result;
    XCTAssertLessThanOrEqual(200, comOutput.tosStatusCode);
    
    // 4. HeadObject????????????
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = createInput.tosBucket;
    headInput.tosKey = createInput.tosKey;
    task = [_client headObject:headInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSHeadObjectOutput *headOutput = task.result;
    XCTAssertEqual(headOutput.tosVersionID, comOutput.tosVersionID);
}

- (void)testAPI_uploadPartFromFile {
    TOSTask *task = nil;
    // 1. ????????????????????????
    TOSCreateMultipartUploadInput *create = [TOSCreateMultipartUploadInput new];
    create.tosBucket = TOS_BUCKET;
    create.tosKey = [NSString stringWithFormat:@"upload-file"];
    task = [_client createMultipartUpload:create];
    [task waitUntilFinished];

    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSCreateMultipartUploadOutput *createOutput = task.result;
    XCTAssertEqual(200, createOutput.tosStatusCode);
    
    // 2. ????????????
    const int partSize = 1;
    NSMutableArray *parts = [NSMutableArray array];
    for (int i = 1; i <= partSize; i++) {
        TOSUploadPartFromFileInput *uploadInput = [TOSUploadPartFromFileInput new];
        uploadInput.tosKey = createOutput.tosKey;
        uploadInput.tosBucket = createOutput.tosBucket;
        uploadInput.tosUploadID = createOutput.tosUploadID;
        uploadInput.tosPartNumber = i;
        uploadInput.tosFilePath = _filePath;
        
        
        task = [_client uploadPartFromFile:uploadInput];
        [task waitUntilFinished];
        
        XCTAssertNil(task.error);
        XCTAssertNotNil(task.result);
        TOSUploadPartOutput *upOutput = task.result;
        
        NSString *mString = upOutput.tosETag;
        mString = [mString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        upOutput.tosETag = mString;
        
        TOSUploadedPart *uploadedPart = [TOSUploadedPart new];
        uploadedPart.tosETag = mString;
        uploadedPart.tosPartNumber = upOutput.tosPartNumber;
                         
        XCTAssertEqual(200, upOutput.tosStatusCode);
        [parts addObject:upOutput];
    }
    XCTAssertEqual(partSize, [parts count]);
    
    // 3. ????????????
    TOSCompleteMultipartUploadInput *complete = [TOSCompleteMultipartUploadInput new];
    complete.tosBucket = createOutput.tosBucket;
    complete.tosKey = createOutput.tosKey;
    complete.tosUploadID = createOutput.tosUploadID;
    NSMutableArray *comArray = [NSMutableArray array];
    for (TOSUploadPartOutput *p in parts) {
        TOSUploadedPart *comPart = [TOSUploadedPart new];
        comPart.tosPartNumber = p.tosPartNumber;
        comPart.tosETag = p.tosETag;
        [comArray addObject:comPart];
    }
    XCTAssertEqual(partSize, [comArray count]);
    complete.tosParts = comArray;
    task = [_client completeMultipartUpload:complete];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSCompleteMultipartUploadOutput *comOutput = task.result;
    XCTAssertLessThanOrEqual(200, comOutput.tosStatusCode);
    
    // 4. HeadObject????????????
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = create.tosBucket;
    headInput.tosKey = create.tosKey;
    task = [_client headObject:headInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSHeadObjectOutput *headOutput = task.result;
    XCTAssertEqual(headOutput.tosVersionID, comOutput.tosVersionID);
}

- (void)testAPI_uploadPartCopy {
    TOSPutObjectInput *putInput = [TOSPutObjectInput new];
    putInput.tosBucket = TOS_BUCKET;
    putInput.tosKey = @"src-file";
    NSMutableData *basePart = [NSMutableData dataWithCapacity:1024];
    for (int j = 0; j < 1024/4; j++) {
        u_int32_t randomBit = arc4random();
        [basePart appendBytes:(void*)&randomBit length:4];
    }
    putInput.tosContent = basePart;
    
    TOSTask *task = [_client putObject:putInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    
    // 1. CreateMultipartUpload
    TOSCreateMultipartUploadInput *createInput = [TOSCreateMultipartUploadInput new];
    createInput.tosBucket = TOS_BUCKET;
    createInput.tosKey = @"dst-file";
    task = [_client createMultipartUpload:createInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSCreateMultipartUploadOutput class]]);
    TOSCreateMultipartUploadOutput *createOutput = task.result;
    
    // 2. uploadPartCopy
    TOSUploadPartCopyInput *partInput = [TOSUploadPartCopyInput new];
    partInput.tosBucket = TOS_BUCKET;
    partInput.tosKey = @"dst-file";
    partInput.tosSrcBucket = TOS_BUCKET;
    partInput.tosSrcKey = @"src-file";
    partInput.tosUploadID = createOutput.tosUploadID;
    partInput.tosPartNumber = 1;
    partInput.tosCopySourceRangeStart = 0;
    
    task = [_client uploadPartCopy:partInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSUploadPartCopyOutput class]]);
    TOSUploadPartCopyOutput *partOutput = task.result;
    
    // 3. completeMultipartUpload
    TOSCompleteMultipartUploadInput *completeInput = [TOSCompleteMultipartUploadInput new];
    completeInput.tosBucket = TOS_BUCKET;
    completeInput.tosKey = @"dst-file";
    completeInput.tosUploadID = createOutput.tosUploadID;
    
    NSMutableArray *array = [NSMutableArray array];
    TOSUploadedPart *p = [TOSUploadedPart new];
    p.tosPartNumber = partOutput.tosPartNumber;
    p.tosETag = partOutput.tosETag;
    [array addObject:p];
    
    completeInput.tosParts = array;
    
    task = [_client completeMultipartUpload:completeInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSCompleteMultipartUploadOutput class]]);
    TOSCompleteMultipartUploadOutput *completeOutput = task.result;
    XCTAssertEqual(200, completeOutput.tosStatusCode);
    
    // 4. headObject
    TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
    headInput.tosBucket = TOS_BUCKET;
    headInput.tosKey = @"dst-file";
    task = [_client headObject:headInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    XCTAssertTrue([task.result isKindOfClass:[TOSHeadObjectOutput class]]);
    TOSHeadObjectOutput *headOutput = task.result;
    XCTAssertEqual(200, headOutput.tosStatusCode);
    XCTAssertEqual(1024, headOutput.tosContentLength);
}

- (void)testAPI_listParts {
    TOSTask *task = nil;
    // 1. ????????????????????????
    TOSCreateMultipartUploadInput *createInput = [TOSCreateMultipartUploadInput new];
    createInput.tosBucket = TOS_BUCKET;
    createInput.tosKey = [NSString stringWithFormat:@"test-file"];
    task = [_client createMultipartUpload:createInput];
    [task waitUntilFinished];

    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSCreateMultipartUploadOutput *createOutput = task.result;
    XCTAssertEqual(200, createOutput.tosStatusCode);
    
    // 2. ????????????
    const int partSize = 3;
    NSMutableArray *parts = [NSMutableArray array];
    for (int i = 1; i <= partSize; i++) {
        TOSUploadPartInput *upload = [TOSUploadPartInput new];
        upload.tosKey = createOutput.tosKey;
        upload.tosBucket = createOutput.tosBucket;
        upload.tosUploadID = createOutput.tosUploadID;
        upload.tosPartNumber = i;
        upload.tosContent = [NSData dataWithContentsOfFile:_filePath];
        task = [_client uploadPart:upload];
        [task waitUntilFinished];
        
        XCTAssertNil(task.error);
        XCTAssertNotNil(task.result);
        TOSUploadPartOutput *upOutput = task.result;
        
        NSString *mString = upOutput.tosETag;
        mString = [mString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        upOutput.tosETag = mString;
        
        TOSUploadedPart *uploadedPart = [TOSUploadedPart new];
        uploadedPart.tosETag = mString;
        uploadedPart.tosPartNumber = upOutput.tosPartNumber;
                         
        XCTAssertEqual(200, upOutput.tosStatusCode);
        [parts addObject:upOutput];
    }
    XCTAssertEqual(partSize, [parts count]);
    
    TOSListPartsInput *listInput = [TOSListPartsInput new];
    listInput.tosBucket = createOutput.tosBucket;
    listInput.tosKey = createOutput.tosKey;
    listInput.tosUploadID = createOutput.tosUploadID;
    task = [_client listParts:listInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSListPartsOutput *listOutput = task.result;
    XCTAssertLessThanOrEqual(200, listOutput.tosStatusCode);
    
    for (TOSUploadedPart *p in listOutput.tosParts) {
        NSLog(@"partNumber: %d", p.tosPartNumber);
        NSLog(@"size: %lld", p.tosSize);
        NSLog(@"etat: %@", p.tosETag);
    }
    
    TOSAbortMultipartUploadInput *abortInput = [TOSAbortMultipartUploadInput new];
    abortInput.tosBucket = createOutput.tosBucket;
    abortInput.tosKey = createOutput.tosKey;
    abortInput.tosUploadID = createOutput.tosUploadID;
    task = [_client abortMultipartUpload:abortInput];
    [task waitUntilFinished];
    XCTAssertNil(task.error);
    XCTAssertNotNil(task.result);
    TOSAbortMultipartUploadOutput *abortOutput = task.result;
    XCTAssertLessThanOrEqual(200, abortOutput.tosStatusCode);
}

- (void)testAPI_multipart {
    // 1. ??????100?????????????????????
    TOSTask *task = nil;
    for (int i = 1; i <= 100; i++) {
        TOSCreateMultipartUploadInput *createInput = [TOSCreateMultipartUploadInput new];
        createInput.tosBucket = TOS_BUCKET;
        createInput.tosKey = [NSString stringWithFormat:@"multipart-file-%d", i];

        task = [_client createMultipartUpload:createInput];
        [task waitUntilFinished];

        XCTAssertNotNil(task.result);
        TOSCreateMultipartUploadOutput *output = task.result;
        XCTAssertEqual(200, output.tosStatusCode);
    }
    
    // 2. ????????????????????????
    NSMutableArray *uploads = [NSMutableArray array];
    TOSListMultipartUploadsInput *listInput;
    TOSListMultipartUploadsOutput *listOutput = nil;
    do {
        listInput = [TOSListMultipartUploadsInput new];
        listInput.tosBucket = TOS_BUCKET;
        listInput.tosMaxUploads = 10;
        listInput.tosKeyMarker = listOutput.tosNextKeyMarker;
                
        task = [_client listMultipartUploads:listInput];
        [task waitUntilFinished];
        XCTAssertNil(task.error);
        XCTAssertNotNil(task.result);
        
        listOutput = task.result;
        [uploads addObjectsFromArray:listOutput.tosUploads];
    } while (listOutput.tosIsTruncated);
    
    // 3. ??????????????????
    for (id upload in uploads) {
        TOSListedUpload *up = (TOSListedUpload *)upload;
        TOSAbortMultipartUploadInput *abortInput = [TOSAbortMultipartUploadInput new];
        abortInput.tosKey = up.tosKey;
        abortInput.tosBucket = TOS_BUCKET;
        abortInput.tosUploadID = up.tosUploadID;
        task = [_client abortMultipartUpload:abortInput];
        [task waitUntilFinished];
        
        XCTAssertNil(task.error);
        XCTAssertNotNil(task.result);
        TOSAbortMultipartUploadOutput *output = task.result;
        XCTAssertEqual(204, output.tosStatusCode);
    }
    
    // 4. ???????????????????????????
    listInput = [TOSListMultipartUploadsInput new];
    listInput.tosBucket = TOS_BUCKET;
    listInput.tosMaxUploads = 1000;
    task = [_client listMultipartUploads:listInput];
    [task waitUntilFinished];
    listOutput = task.result;
    XCTAssertEqual(200, listOutput.tosStatusCode);
    XCTAssertEqual(0, [listOutput.tosUploads count]);
}

- (void)testAPI_multipartUploadToNonexistentObject {
    TOSUploadPartInput *uploadInput = [TOSUploadPartInput new];
    uploadInput.tosBucket = TOS_BUCKET;
    uploadInput.tosKey = @"non-exist-object";
    uploadInput.tosUploadID = [NSString stringWithFormat:@"non-exist-upload-id-%d", arc4random()];
    
    TOSTask *task = [_client uploadPart:uploadInput];
    [task waitUntilFinished];
    XCTAssertNotNil(task.error);
    XCTAssertNil(task.result);
}

- (void)testAPI_listMultipartUploadsFromNonexistentBucket {
    TOSListMultipartUploadsInput *listInput = [TOSListMultipartUploadsInput new];
    listInput.tosBucket = @"non-exist-bucket";
    listInput.tosMaxUploads = 1000;
    TOSTask *task = [_client listMultipartUploads:listInput];
    [task waitUntilFinished];
    XCTAssertNotNil(task.error);
    XCTAssertNil(task.result);
}

@end
