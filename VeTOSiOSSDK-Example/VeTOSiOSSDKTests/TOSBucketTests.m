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
#import "TOSTestUtil.h"
#import "TOSTestConstants.h"

@interface TOSBucketTests : XCTestCase
{
    TOSClient *_client;
}
@end

@implementation TOSBucketTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [super setUp];
    [self initTOSClient];
}

- (void)initTOSClient {
    NSString *accessKey = TOS_ACCESSKEY;
    NSString *secretKey = TOS_SECRETKEY;
    TOSCredential *credential = [[TOSCredential alloc] initWithAccessKey:accessKey secretKey:secretKey];
    TOSEndpoint *tosEndpoint = [[TOSEndpoint alloc] initWithURLString:TOS_ENDPOINT withRegion:TOS_REGION];
    TOSClientConfiguration *config = [[TOSClientConfiguration alloc] initWithEndpoint:tosEndpoint credential:credential];
    _client = [[TOSClient alloc] initWithConfiguration:config];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// 1. 只包含桶名，创建成功，校验桶元数据
- (void)testAPI_createBucket01 {
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    TOSTask *task = [_client createBucket:createInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCreateBucketOutput class]]);
        TOSCreateBucketOutput *createOutput = t.result;
        XCTAssertEqual(200, createOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadBucketInput *headInput = [TOSHeadBucketInput new];
    headInput.tosBucket = TOS_BUCKET;
    task = [_client headBucket:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadBucketOutput class]]);
        TOSHeadBucketOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertTrue([TOS_REGION isEqualToString:headOutput.tosRegion]);
        XCTAssertTrue([TOSStorageClassStandard isEqualToString:headOutput.tosStorageClass]);
        return nil;
    }] waitUntilFinished];
    
    [TOSTestUtil cleanBucket:bucket withClient:_client];
}

// 2. 包含所有参数创桶，创建成功，校验桶元数据
- (void)testAPI_createBucket02 {
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    createInput.tosACL = TOSACLPublicRead;
    createInput.tosStorageClass = TOSStorageClassIa;
    createInput.tosAzRedundancy = TOSAzRedundancySingleAz;
//    createInput.tosGrantFullControl = @"grantFullControl";
//    createInput.tosGrantRead = @"grantRead";
//    createInput.tosGrantReadAcp = @"grantReadAcp";
//    createInput.tosGrantWrite = @"grantWrite";
//    createInput.tosGrantWriteAcp = @"grantWriteAcp";
    TOSTask *task = [_client createBucket:createInput];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCreateBucketOutput class]]);
        TOSCreateBucketOutput *createOutput = t.result;
        XCTAssertEqual(200, createOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadBucketInput *headInput = [TOSHeadBucketInput new];
    headInput.tosBucket = TOS_BUCKET;
    task = [_client headBucket:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadBucketOutput class]]);
        TOSHeadBucketOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        NSLog(@"=====>  %@", headOutput.tosRegion);
        XCTAssertTrue([TOS_REGION isEqualToString:headOutput.tosRegion]);
        XCTAssertTrue([TOSStorageClassIa isEqualToString:headOutput.tosStorageClass]);
        return nil;
    }] waitUntilFinished];

    [TOSTestUtil cleanBucket:bucket withClient:_client];
}

// 3. 查询不存在的桶名，服务端报错404
- (void)testAPI_headNonExistentBucket {
    NSString *bucket = @"non-existent-bucket";
    TOSHeadBucketInput *headInput = [TOSHeadBucketInput new];
    headInput.tosBucket = bucket;
    
    TOSTask *task = [_client headBucket:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(404, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSServerErrorDomain]);
        return nil;
    }] waitUntilFinished];
}

// 4. 使用错误的桶访问权限/存储类型/桶AZ属性创建桶，返回客户端校验错误，构造正交用例
- (void)testAPI_createBucket03 {
    NSString *bucket = TOS_BUCKET;
    
    // 错误的桶访问权限
    TOSCreateBucketInput *createInput01 = [TOSCreateBucketInput new];
    createInput01.tosBucket = bucket;
    createInput01.tosACL = @"known-acl";
    createInput01.tosStorageClass = TOSStorageClassIa;
    createInput01.tosAzRedundancy = TOSAzRedundancySingleAz;
    TOSTask *task = [_client createBucket:createInput01];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid acl type"]);
        return nil;
    }] waitUntilFinished];
    
    // 错误的存储类型
    TOSCreateBucketInput *createInput02 = [TOSCreateBucketInput new];
    createInput02.tosBucket = bucket;
    createInput02.tosACL = TOSACLPublicRead;
    createInput02.tosStorageClass = @"unkown-storage-class";
    createInput02.tosAzRedundancy = TOSAzRedundancySingleAz;
    task = [_client createBucket:createInput02];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid storage class"]);
        return nil;
    }] waitUntilFinished];
    
    // 错误的桶AZ属性
    TOSCreateBucketInput *createInput03 = [TOSCreateBucketInput new];
    createInput03.tosBucket = bucket;
    createInput03.tosACL = TOSACLPublicRead;
    createInput03.tosStorageClass = TOSStorageClassIa;
    createInput03.tosAzRedundancy = @"unknow-az-redundancy";
    task = [_client createBucket:createInput03];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid az redundancy type"]);
        return nil;
    }] waitUntilFinished];
}

// 5. 使用错误的桶名创建桶
// 5.1 使用不允许的字符集
// 5.2 使用错误的字符长度
// 5.3 使用'-'开头或结尾
- (void)testAPI_createBucket04 {
    // 不允许的字符集
    NSString *bucket01 = @"UppercaseBucket";
    TOSCreateBucketInput *createInput01 = [TOSCreateBucketInput new];
    createInput01.tosBucket = bucket01;
    TOSTask *task01 = [_client createBucket:createInput01];
    [[task01 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: bucket name can consist only of lowercase letters, numbers, and '-'"]);
        return nil;
    }] waitUntilFinished];
    
    NSString *bucket02 = @"error-!@#$%^&*-bucket";
    TOSCreateBucketInput *createInput02 = [TOSCreateBucketInput new];
    createInput02.tosBucket = bucket02;
    TOSTask *task02 = [_client createBucket:createInput02];
    [[task02 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: bucket name can consist only of lowercase letters, numbers, and '-'"]);
        return nil;
    }] waitUntilFinished];
    
    // 错误的字符长度
    NSString *bucket03 = @"";
    TOSCreateBucketInput *createInput03 = [TOSCreateBucketInput new];
    createInput03.tosBucket = bucket03;
    TOSTask *task03 = [_client createBucket:createInput03];
    [[task03 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid bucket name, the length must be [3, 63]"]);
        return nil;
    }] waitUntilFinished];
    
    NSString *bucket04 = @"aa";
    TOSCreateBucketInput *createInput04 = [TOSCreateBucketInput new];
    createInput04.tosBucket = bucket04;
    TOSTask *task04 = [_client createBucket:createInput04];
    [[task04 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid bucket name, the length must be [3, 63]"]);
        return nil;
    }] waitUntilFinished];
    
    NSString *bucket05 = @"0123456789-0123456789-0123456789-0123456789-0123456789-0123456789";
    TOSCreateBucketInput *createInput05 = [TOSCreateBucketInput new];
    createInput05.tosBucket = bucket05;
    TOSTask *task05 = [_client createBucket:createInput05];
    [[task05 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid bucket name, the length must be [3, 63]"]);
        return nil;
    }] waitUntilFinished];
    
    // 使用'-'开头或结尾
    NSString *bucket06 = @"-bucket";
    TOSCreateBucketInput *createInput06 = [TOSCreateBucketInput new];
    createInput06.tosBucket = bucket06;
    TOSTask *task06 = [_client createBucket:createInput06];
    [[task06 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid bucket name, the bucket name can be neither starting with '-' nor ending with '-'"]);
        return nil;
    }] waitUntilFinished];
    
    NSString *bucket07 = @"-bucket";
    TOSCreateBucketInput *createInput07 = [TOSCreateBucketInput new];
    createInput07.tosBucket = bucket07;
    TOSTask *task07 = [_client createBucket:createInput07];
    [[task07 continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertEqual(400, t.error.code);
        XCTAssertTrue([t.error.domain isEqualToString:TOSClientErrorDomain]);
        XCTAssertTrue([[t.error.userInfo objectForKey:TOSErrorMessageTOKEN] isEqualToString:@"tos: invalid bucket name, the bucket name can be neither starting with '-' nor ending with '-'"]);
        return nil;
    }] waitUntilFinished];
}

// 删除不存在的桶，服务端报错404
- (void)testAPI_deleteBucket01 {
    NSString *bucket = @"non-existent-bucket";
    TOSDeleteBucketInput *deleteInput = [TOSDeleteBucketInput new];
    deleteInput.tosBucket = bucket;
    TOSTask *task = [_client deleteBucket:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNotNil(t.error);
        XCTAssertNil(t.result);
        XCTAssertTrue([t.error.domain isEqualToString:TOSServerErrorDomain]);
        XCTAssertEqual(404, t.error.code);
        return nil;
    }] waitUntilFinished];
}

// 删除已存在的桶，删除成功
- (void)testAPI_deleteBucket02 {
    // 创建桶
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    createInput.tosACL = TOSACLPublicRead;
    TOSTask *task = [_client createBucket:createInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCreateBucketOutput class]]);
        TOSCreateBucketOutput *createOutput = t.result;
        XCTAssertEqual(200, createOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];

    // 删除桶
    TOSDeleteBucketInput *deleteInput = [TOSDeleteBucketInput new];
    deleteInput.tosBucket = bucket;
    task = [_client deleteBucket:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSDeleteBucketOutput class]]);
        TOSDeleteBucketOutput *deleteOutput = t.result;
        XCTAssertEqual(204, deleteOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

// 列举桶，校验桶信息
- (void)testAPI_listBuckets01 {
    // 创建桶
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    createInput.tosACL = TOSACLPublicRead;
    createInput.tosStorageClass = TOSStorageClassIa;
    createInput.tosAzRedundancy = TOSAzRedundancyMultiAz;
    TOSTask *task = [_client createBucket:createInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCreateBucketOutput class]]);
        TOSCreateBucketOutput *createOutput = t.result;
        XCTAssertEqual(200, createOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    // 列举桶
    TOSListBucketsInput *listInput = [TOSListBucketsInput new];
    task = [_client listBuckets:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListBucketsOutput class]]);
        TOSListBucketsOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        BOOL hasTargetBucket = NO;
        for (TOSListedBucket *bkt in listOutput.tosBuckets) {
            if ([bkt.tosName isEqualToString:TOS_BUCKET]) {
                hasTargetBucket = YES;
            }
        }
        XCTAssertTrue(hasTargetBucket);
        return nil;
    }] waitUntilFinished];
    
    // 删除桶
    TOSDeleteBucketInput *deleteInput = [TOSDeleteBucketInput new];
    deleteInput.tosBucket = bucket;
    task = [_client deleteBucket:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSDeleteBucketOutput class]]);
        TOSDeleteBucketOutput *deleteOutput = t.result;
        XCTAssertEqual(204, deleteOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}



- (void)testAPI_createBucket0000 {
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    createInput.tosACL = TOSACLPublicRead;
    createInput.tosStorageClass = TOSStorageClassStandard;
    createInput.tosAzRedundancy = TOSAzRedundancySingleAz;
    TOSTask *task = [_client createBucket:createInput];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCreateBucketOutput class]]);
        TOSCreateBucketOutput *createOutput = t.result;
        XCTAssertEqual(200, createOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadBucketInput *headInput = [TOSHeadBucketInput new];
    headInput.tosBucket = bucket;
    task = [_client headBucket:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadBucketOutput class]]);
        TOSHeadBucketOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertTrue([headOutput.tosStorageClass isEqualToString:TOSStorageClassStandard]);
        NSLog(@"=====>  %@", headOutput.tosRegion);
        XCTAssertTrue([headOutput.tosRegion isEqualToString:TOS_REGION]);
        return nil;
    }] waitUntilFinished];

    [TOSTestUtil cleanBucket:bucket withClient:_client];
}

- (void)testAPI_headBucket {
    NSString *bucket = TOS_BUCKET;

    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    [[_client createBucket:createInput] waitUntilFinished];

    TOSHeadBucketInput *headInput = [TOSHeadBucketInput new];
    headInput.tosBucket = bucket;
    TOSTask *task = [_client headBucket:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadBucketOutput class]]);
        TOSHeadBucketOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];

    [TOSTestUtil cleanBucket:bucket withClient:_client];
}

- (void)testAPI_listBuckets {
    TOSListBucketsInput *listInput = [TOSListBucketsInput new];
    TOSTask *task = [_client listBuckets:listInput];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListBucketsOutput class]]);
        TOSListBucketsOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
}

- (void)testAPI_deleteBucket {
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    createInput.tosACL = TOSACLPublicRead;
    TOSTask *task = [_client createBucket:createInput];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull task) {
            XCTAssertNil(task.error);
        return nil;
        }] waitUntilFinished];

    TOSDeleteBucketInput *delete = [TOSDeleteBucketInput new];
    delete.tosBucket = bucket;
    task = [_client deleteBucket:delete];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            return nil;
    }] waitUntilFinished];
}

- (void)testAPI_listMultipartUploads {
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    [[_client createBucket:createInput] waitUntilFinished];

    TOSListMultipartUploadsInput *listInput = [TOSListMultipartUploadsInput new];
    listInput.tosBucket = bucket;
    listInput.tosMaxUploads = 900;
    TOSTask *task = [_client listMultipartUploads:listInput];

    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            XCTAssertNil(t.error);
            TOSListMultipartUploadsOutput *output = t.result;
            XCTAssertTrue(output.tosMaxUploads == 900);
            return nil;
    }] waitUntilFinished];

    [TOSTestUtil cleanBucket:bucket withClient:_client];
}

- (void)testAPI_invalidBucketName {
    NSArray *invalidNames = @[@"Bucket", @"-bucket", @"bucket-", @"bu", @"+bucket", [TOSTestUtil randomString:64]];
    
    for (NSString *bucket in invalidNames) {
        NSError *err = nil;
        BOOL isValid =  [TOSUtil isValidBucketName:bucket withError:&err];
        XCTAssertFalse(isValid);
        XCTAssertNotNil(err);
    }
    
}

- (void)testAPI_validBucketName {
    NSArray *validNames = @[@"bucket", @"bucket-name", @"bucket", [TOSTestUtil randomString:3], [TOSTestUtil randomString:63]];
    
    for (NSString *bucket in validNames) {
        NSError *err = nil;
        BOOL isValid =  [TOSUtil isValidBucketName:bucket withError:&err];
        XCTAssertTrue(isValid);
        XCTAssertNil(err);
    }
    
}

- (void)testAPI_customDomain{
    NSString *bucket = TOS_BUCKET;
    TOSCreateBucketInput *createInput = [TOSCreateBucketInput new];
    createInput.tosBucket = bucket;
    TOSTask *task = [_client createBucket:createInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSCreateBucketOutput class]]);
        TOSCreateBucketOutput *createOutput = t.result;
        XCTAssertEqual(200, createOutput.tosStatusCode);
        return nil;
    }] waitUntilFinished];
    
    TOSHeadBucketInput *headInput = [TOSHeadBucketInput new];
    headInput.tosBucket = TOS_BUCKET;
    task = [_client headBucket:headInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSHeadBucketOutput class]]);
        TOSHeadBucketOutput *headOutput = t.result;
        XCTAssertEqual(200, headOutput.tosStatusCode);
        XCTAssertTrue([TOS_REGION isEqualToString:headOutput.tosRegion]);
        XCTAssertTrue([TOSStorageClassStandard isEqualToString:headOutput.tosStorageClass]);
        return nil;
    }] waitUntilFinished];
    
    __block NSInteger ruleCount = 0;
    
    TOSPutBucketCustomDomainInput *input = [TOSPutBucketCustomDomainInput new];
    input.tosBucket = TOS_BUCKET;
    TOSCustomDomainRule *rule = [TOSCustomDomainRule new];
    rule.tosDomain = @"example.ios.sdk.com";
//    rule.tosCertId = @"id123";
    rule.tosProtocol = AuthProtocolTypeTos;
    input.tosRule = rule;
    
    task = [_client putBucketCustomDomain:input];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutBucketCustomDomainOutput class]]);
        TOSPutBucketCustomDomainOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        ruleCount+=1;
        return nil;
    }] waitUntilFinished];
    
    TOSListBucketCustomDomainInput *listInput = [TOSListBucketCustomDomainInput new];
    listInput.tosBucket = TOS_BUCKET;
    task = [_client listBucketCustomDomain:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListBucketCustomDomainOutput class]]);
        TOSListBucketCustomDomainOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        XCTAssertNotNil(listOutput.tosRules);
        XCTAssertEqual(ruleCount, listOutput.tosRules.count);
        return nil;
    }] waitUntilFinished];
    
    input.tosRule.tosProtocol = AuthProtocolTypeS3;
    input.tosRule.tosDomain = @"example.ios.s3.sdk.com";
    task = [_client putBucketCustomDomain:input];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSPutBucketCustomDomainOutput class]]);
        TOSPutBucketCustomDomainOutput *output = t.result;
        XCTAssertEqual(200, output.tosStatusCode);
        ruleCount+=1;
        return nil;
    }] waitUntilFinished];
    
    task = [_client listBucketCustomDomain:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListBucketCustomDomainOutput class]]);
        TOSListBucketCustomDomainOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        XCTAssertNotNil(listOutput.tosRules);
        XCTAssertEqual(ruleCount, listOutput.tosRules.count);
        return nil;
    }] waitUntilFinished];
    
    TOSDeleteBucketCustomDomainInput *deleteInput = [TOSDeleteBucketCustomDomainInput new];
    deleteInput.tosBucket = TOS_BUCKET;
    deleteInput.tosDomain = @"example.ios.sdk.com";
    task = [_client deleteBucketCustomDomain:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSDeleteBucketCustomDomainOutput class]]);
        TOSDeleteBucketCustomDomainOutput *deleteOutput = t.result;
        XCTAssertEqual(200, deleteOutput.tosStatusCode);
        ruleCount-=1;
        return nil;
    }] waitUntilFinished];
    
    
    task = [_client listBucketCustomDomain:listInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSListBucketCustomDomainOutput class]]);
        TOSListBucketCustomDomainOutput *listOutput = t.result;
        XCTAssertEqual(200, listOutput.tosStatusCode);
        XCTAssertNotNil(listOutput.tosRules);
        XCTAssertEqual(ruleCount, listOutput.tosRules.count);
        return nil;
    }] waitUntilFinished];
    
    deleteInput.tosDomain = @"example.ios.s3.sdk.com";
    task = [_client deleteBucketCustomDomain:deleteInput];
    [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        XCTAssertNil(t.error);
        XCTAssertNotNil(t.result);
        XCTAssertTrue([t.result isKindOfClass:[TOSDeleteBucketCustomDomainOutput class]]);
        TOSDeleteBucketCustomDomainOutput *deleteOutput = t.result;
        XCTAssertEqual(200, deleteOutput.tosStatusCode);
        ruleCount-=1;
        return nil;
    }] waitUntilFinished];
    
    [TOSTestUtil cleanBucket:bucket withClient:_client];
}

@end
