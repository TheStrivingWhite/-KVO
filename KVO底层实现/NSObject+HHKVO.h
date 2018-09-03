//
//  NSObject+HHKVO.h
//  KVO底层实现
//
//  Created by yy on 2018/9/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (HHKVO)

- (void)HH_addObserver:(NSObject *)observer
                forKey:(NSString *)key
               options:(NSKeyValueObservingOptions)options
               context:(nullable void *)context;

@end
