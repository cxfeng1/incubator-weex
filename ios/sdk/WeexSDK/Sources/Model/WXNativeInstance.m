/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "WXNativeInstance.h"
#import "WXSDKInstance_private.h"

@implementation WXNativeInstance

- (void)createBody:(NSDictionary *)bodyData
{
    WXPerformBlockOnMainThread(^{
        _rootView = [[WXRootView alloc] initWithFrame:self.frame];
        _rootView.instance = self;
        if(self.onCreate) {
            self.onCreate(_rootView);
        }
        
        [WXSDKEngine registerDefaults];
        [self _performComponentTask:^(WXComponentManager *manager) {
            [manager createRoot:bodyData];
        }];
    });
}

- (void)addElement:(NSDictionary *)elementData toParent:(NSString *)parentRef atIndex:(NSInteger)index
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager addComponent:elementData toSupercomponent:parentRef atIndex:index appendingInTree:NO];
    }];
}

- (void)removeElement:(NSString *)elementRef
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager removeComponent:elementRef];
    }];
}

- (void)updateStyles:(NSDictionary *)styles forElement:(NSString *)elementRef
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager updateStyles:styles forComponent:elementRef];
    }];
}

- (void)updateAttibutes:(NSDictionary *)attibutes forElement:(NSString *)elementRef
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager updateAttributes:attibutes forComponent:elementRef];
    }];
}

- (void)addEvent:(NSString *)eventName forElement:(NSString *)elementRef
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager addEvent:eventName toComponent:elementRef];
    }];
}

- (void)removeEvent:(NSString *)eventName forElement:(NSString *)elementRef
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager removeEvent:eventName fromComponent:elementRef];
    }];
}

- (void)createFinish
{
    [self _performComponentTask:^(WXComponentManager *manager) {
        [manager createFinish];
    }];
}

- (void)_performComponentTask:(void(^)(WXComponentManager *manager))task
{
    __weak typeof(self) weakSelf = self;
    WXPerformBlockOnComponentThread(^{
        WXComponentManager *manager = weakSelf.componentManager;
        if (!manager.isValid) {
            return;
        }
        [manager startComponentTasks];
        task(manager);
    });
}

@end
