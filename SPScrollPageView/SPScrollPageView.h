//
//  SPScrollPageView.h
//
//  Created by Tree on 2018/2/23.
//  Copyright © 2018年 Tr2e. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPScrollPageView;
@protocol SPScrollPageViewDelegate<NSObject>
@optional
- (void)scrollPageDidEndBounceAtPage:(UIView *)stillPage index:(NSInteger)index;
@required
- (UIView *)scrollPageView:(SPScrollPageView *)pageView pageForIndex:(NSInteger)index;
@end

@interface SPScrollPageView : UIScrollView
@property (nonatomic, weak) id<SPScrollPageViewDelegate> sp_delegete;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, assign) NSInteger initialIndex;
+ (instancetype)scrollPageViewWithPageCount:(NSInteger)pageCount initialIndex:(NSInteger)targetPage frame:(CGRect)frame;
- (UIView *)dequeuePageViewWithIndex:(NSInteger)index;
- (void)jumpToIndex:(NSInteger)index animated:(BOOL)animated;
- (void)jumpImmediatelyToIndex:(NSInteger)index animated:(BOOL)animated;
@end
