//
//  ViewController.m
//  KVO底层实现
//
//  Created by yy on 2018/9/3.
//  Copyright © 2018年 1. All rights reserved.
//

#import "ViewController.h"
#import "Perosn.h"
#import "NSObject+HHKVO.h"

@interface ViewController ()

@property (nonatomic,strong) Perosn * person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    Perosn * person = [[Perosn alloc]init];
    [person HH_addObserver:self forKey:@"name" options:NSKeyValueObservingOptionNew context:nil];
    _person = person;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    
    if ([keyPath isEqualToString:@"name"]) {
        NSLog(@"name %@",self.person.name);
        NSLog(@"change %@",change);
    }
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.person.name = [NSString stringWithFormat:@"%d",arc4random() % 100 + 1];
    
}
@end
