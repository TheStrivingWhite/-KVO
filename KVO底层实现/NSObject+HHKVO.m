//
//  NSObject+HHKVO.m
//  KVO底层实现
//
//  Created by yy on 2018/9/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import "NSObject+HHKVO.h"
#import <objc/message.h>


#define HHKVO_Name @"HHKVO"
#define HHKVO_Observer_Key "HHKVO_Observer_Key"
#define HHKVO_Context_Key @"HHKVO_Context_Key"
#define HHKVO_Changet_Key "HHKVO_Change_Key"

@implementation NSObject (HHKVO)

static NSString * getSetterMethodParameter(NSString * key){
    if (key.length == 0) {
        return nil;
    }
    NSString * newFirsRangetKeyName = [[key substringToIndex:1] uppercaseString];
    NSString * endRangeKeyName = [key substringFromIndex:1];
    NSString * methodString = [NSString stringWithFormat:@"set%@%@:",newFirsRangetKeyName,endRangeKeyName];
    return methodString;
}

static NSString * getterForSetter(NSString *setter)
{
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    // remove 'set' at the begining and ':' at the end
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    // lower case the first letter
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    
    return key;
}

static void kvo_setter(id self,SEL _cmp,id newValue){
    
    NSString * keypath = getterForSetter(NSStringFromSelector(_cmp));
    
    // 保存当前KVO的类
    Class kvoClass = [self class];
    // 将self的isa指针指向父类，调用父类setter方法
    object_setClass(self, class_getSuperclass([self class]));
    
    // 调用父类setter方法，重新复制
    objc_msgSend(self, _cmp, newValue);
    // 取出观察者
    id objc = objc_getAssociatedObject(self, HHKVO_Observer_Key);
    
    NSNumber * optionsNumber = objc_getAssociatedObject(self, HHKVO_Changet_Key);
    NSDictionary * dict = @{@"new":newValue,@"kind":optionsNumber};
    // 通知观察者，执行通知方法
    objc_msgSend(objc, @selector(observeValueForKeyPath:ofObject:change:context:), keypath, self, dict, newValue);
    // 重新修改为ZJKVO_Person类
    object_setClass(self, kvoClass);
    
}


- (void)HH_addObserver:(NSObject *)observer
                forKey:(NSString *)key
               options:(NSKeyValueObservingOptions)options
               context:(nullable void *)context
{
    /*1.创建一个派生类 */
    //1.1 获取类名
    NSString * className = NSStringFromClass([self class]);
    
    Class  newClass = object_getClass(self);
    
    BOOL hasClass = [className hasPrefix:HHKVO_Name];
    
    if (!hasClass) {
        //如果不包含 那么 就是第一次 监听
        
        //1.2 动态拼接类名
        NSString * newClassName = [HHKVO_Name stringByAppendingFormat:@"_%@",className];
        //1.3 动态创建类
        newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
    }

    //1.3.1 获取 key 的setter 方法名字
    NSString * setMethodName = getSetterMethodParameter(key);
    //1.3.2 根据名字生成 方法
    SEL method = NSSelectorFromString(setMethodName);
     //1.3.3 检查类里面有没有 set方法
    Method setMethod = class_getInstanceMethod([self class], method);
    
    if (!setMethod) {
        // 如果当前类里面 没有 对应的方法 抛出异常
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    
    //1.3.4 如果没有的话，那就给类添加方法
    if (![self hasSelector:method]) {
         //1.3.5 给新的类赋值 set 方法，但是这里得先获取参数列表
        const char * types = method_getTypeEncoding(setMethod);
         //1.3.6 给新的类赋值 set 方法
        class_addMethod(newClass, method, (IMP)kvo_setter, types);
    }
    if (!hasClass) {
        //1.4 注册 这个 类
        objc_registerClassPair(newClass);
        
        //2.0 更改当前 类的指针
        object_setClass(self, newClass);
    }
    //到这了 有一个问题，那就是 如何通知 系统的方法  那就是 给当前类 添加一个属性
    objc_setAssociatedObject(self, HHKVO_Observer_Key, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, HHKVO_Changet_Key, @(options), OBJC_ASSOCIATION_ASSIGN);
    
}
- (BOOL)hasSelector:(SEL)selector{
    unsigned int count = 0;
    Method * methodList = class_copyMethodList([self class], &count);
    for (int i = 0; i < count; i++) {
        SEL sel = method_getName(methodList[i]);
        if (sel == selector) {
            break;
            return YES;
        }
    }
    return NO;
}

@end
