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

@interface TOSUtilityTests : XCTestCase

@end

@implementation TOSUtilityTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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

- (void)testUrlSafeBase64String {
    NSString * raw = @"Twas brillig, and the slithy toves";
    NSString * encoded = [TOSUtil urlSafeBase64String:raw];
    XCTAssertTrue([@"VHdhcyBicmlsbGlnLCBhbmQgdGhlIHNsaXRoeSB0b3Zlcw==" isEqualToString:encoded]);
    
    NSArray<NSString *> * rawStr = @[@"中文", @"中 / / 文",
                        @"", @"f", @"fo", @"foo", @"foob", @"fooba", @"foobar",
                        @"sure.", @"sure", @"sur", @"su", @"leasure.", @"easure.", @"asure.", @"sure."];
    NSArray<NSString *> * encodedStr = @[@"5Lit5paH", @"5LitIC8gLyDmloc=",
                        @"", @"Zg==", @"Zm8=", @"Zm9v", @"Zm9vYg==", @"Zm9vYmE=", @"Zm9vYmFy",
                        @"c3VyZS4=", @"c3VyZQ==", @"c3Vy", @"c3U=", @"bGVhc3VyZS4=", @"ZWFzdXJlLg==", @"YXN1cmUu", @"c3VyZS4="];
    for (int i = 0; i < [rawStr count]; i++) {
        NSString * str = [rawStr objectAtIndex:i];
        XCTAssertTrue([[encodedStr objectAtIndex:i] isEqualToString:[TOSUtil urlSafeBase64String:str]]);
    }
}

@end
