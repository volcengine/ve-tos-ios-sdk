//
// Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import <Foundation/Foundation.h>

@interface TOSSynchronizedMutableDictionary<KeyType, ObjectType> : NSObject

@property (readonly, copy) NSArray<KeyType> *allKeys;
@property (readonly, copy) NSArray<ObjectType> *allValues;
@property (readonly, nonatomic, strong) NSUUID *instanceKey;

/// Create new instance.
- (instancetype)init;

/// Creates another dictionary which syncs on the same queue.
- (instancetype)syncedDictionary;

- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey;

- (void)removeObject:(id)object;
- (void)removeObjectForKey:(id)aKey;
- (void)removeAllObjects;

- (void)mutateWithBlock:(void (^)(NSMutableDictionary *))block;
+ (void)mutateSyncedDictionaries:(NSArray<TOSSynchronizedMutableDictionary *> *)dictionaries
                       withBlock:(void (^)(NSUUID *, NSMutableDictionary *))block;

- (BOOL)isEqualToTOSSynchronizedMutableDictionary:(TOSSynchronizedMutableDictionary *)other;

@end
