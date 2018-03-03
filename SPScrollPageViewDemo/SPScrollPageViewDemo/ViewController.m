//
//  ViewController.m
//  SPScrollPageViewDemo
//
//  Created by Tree on 2018/3/2.
//  Copyright © 2018年 Tr2e. All rights reserved.
//

#import "ViewController.h"
#import "SPScrollPageView.h"

#define  RANDOM_COLOR   [UIColor colorWithRed:arc4random_uniform(256)/225.0 green:arc4random_uniform(256)/225.0 blue:arc4random_uniform(256)/225.0 alpha:1]

@interface ViewController ()<SPScrollPageViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // # How to use #
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    SPScrollPageView *pageView = [SPScrollPageView scrollPageViewWithPageCount:5
                                                                  initialIndex:3
                                                                         frame:(CGRect){CGPointZero,screenSize}];
    pageView.sp_delegete = self;
    [self.view addSubview:pageView];
    
    // # Test #
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpToIndex:1 animated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpToIndex:2 animated:NO];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpImmediatelyToIndex:4 animated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpImmediatelyToIndex:1 animated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpToIndex:0 animated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpImmediatelyToIndex:4 animated:NO];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpToIndex:2 animated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(40 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pageView jumpImmediatelyToIndex:4 animated:YES];
    });
}

- (UIView *)scrollPageView:(SPScrollPageView *)pageView pageForIndex:(NSInteger)index{
    UIView *view = [pageView dequeuePageViewWithIndex:index];
    if (!view) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        view = [[UIView alloc] initWithFrame:(CGRect){CGPointZero,screenSize}];
        view.backgroundColor = RANDOM_COLOR;
        NSLog(@"Initialize");
    }else{
        NSLog(@"Reuse");
    }
    return view;
}

- (void)scrollPageDidEndBounceAtPage:(UIView *)stillPage index:(NSInteger)index
{
    NSLog(@"Current page number:%ld",index);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
