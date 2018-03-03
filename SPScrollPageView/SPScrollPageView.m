//
//  SPScrollPageView.m
//
//  Created by Tree on 2018/2/23.
//  Copyright © 2018年 Tr2e. All rights reserved.
//

#import "SPScrollPageView.h"

@interface SPReuseCell:UIView
@property (nonatomic, assign) NSInteger targetIndex;
@end
@implementation SPReuseCell
@end

@interface SPScrollPageView()
{
    NSMutableDictionary       *_pageMap;
    NSMutableSet                *_cellSet;
    SPReuseCell                  *_reuseCell;
    NSInteger                     _initialIndex;
    NSInteger                     _currentPageNumber;
    
    BOOL _isPanning;
    BOOL _isPanningEnd;
    BOOL _isUpdatingInfo;

    struct {
        unsigned int pageForIndex:1;
        unsigned int didEndBounce:1;
    } _spDelegateRespondsTo;
    struct {
        unsigned int isAnimated:1;
        unsigned int isJumping:1;
        unsigned int isImmediateJump:1;
        NSInteger     targetIndex;
    } _jumpInfo;
}
@end

@implementation SPScrollPageView
@synthesize sp_delegete;

#pragma mark - Init
+ (instancetype)scrollPageViewWithPageCount:(NSInteger)pageCount initialIndex:(NSInteger)targetPage frame:(CGRect)frame
{
    SPScrollPageView *pageView = [[SPScrollPageView alloc] initWithFrame:frame];
    pageView.pageCount = pageCount;
    pageView.initialIndex = ABS(MIN(pageCount-1, targetPage));
    [pageView prepareForMainView];
    return pageView;
}

#pragma mark - Set Up
- (void)prepareForMainView
{
    if (!_pageCount) {
        _pageCount = 1;// default is 1
    }
    // default configuration
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.backgroundColor = [UIColor whiteColor];

    _currentPageNumber = 0;
    _pageMap = [NSMutableDictionary dictionary];
    
    // contentView
    [self setupContentViewWithPageCount:_pageCount];
    
    // target index
    [self confirmInitialIndex];
    
    // observer
    [self observeContentOffset];
    
    // pan
    [self.panGestureRecognizer addTarget:self action:@selector(handlePanAction:)];
}

- (void)handlePanAction:(UIPanGestureRecognizer *)panRec{
    _isPanning = !(
                  panRec.state == UIGestureRecognizerStateEnded ||
                  panRec.state == UIGestureRecognizerStateFailed ||
                  panRec.state == UIGestureRecognizerStateCancelled
                  );
}

- (void)setupContentViewWithPageCount:(NSInteger)pageCount
{
    NSInteger temp = pageCount;
    temp = MAX(temp, 0);
    temp = MIN(temp, 2);
    
    if(pageCount)
    _cellSet = [NSMutableSet setWithCapacity:temp];
    
    CGSize pageSize = self.frame.size;
    self.contentSize = CGSizeMake(pageSize.width*MAX(1, pageCount), pageSize.height);
    for (NSInteger i = 0; i<temp; i++) {
        SPReuseCell *cell = [[SPReuseCell alloc] initWithFrame:self.bounds];
        cell.tag = i;
        [_cellSet addObject:cell];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    // initialize the first page
    if (_spDelegateRespondsTo.pageForIndex)
    {
        UIView *view = [self.sp_delegete scrollPageView:self pageForIndex:_initialIndex];
        if (![_pageMap objectForKey:@(_initialIndex)]) {
            [_pageMap setObject:view forKey:@(_initialIndex)];
        }
        SPReuseCell *cell = [self getReuseCell:NO];
        [cell addSubview:view];
        if (_spDelegateRespondsTo.didEndBounce) {
            [self.sp_delegete scrollPageDidEndBounceAtPage:view index:_initialIndex];
        }
    }
}

#pragma mark - Target index
- (void)confirmInitialIndex
{
    CGSize pageSize = self.bounds.size;
    
    SPReuseCell *cell = [self getReuseCell:NO];
    cell.frame = (CGRect){CGPointMake(_initialIndex*pageSize.width, 0),pageSize};
    [self setContentOffset:CGPointMake(_initialIndex*pageSize.width, 0) animated:NO];
    [self addSubview:cell];
}

#pragma mark - Reuse Part
- (void)observeContentOffset
{
    [self addObserver:self
           forKeyPath:@"contentOffset"
              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
              context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self manageCellReuse];
    }
}

/**
 *  如果是跳转，则直接在目标处添加，跳转结束时，清空jumpInfo
 *  如果是拖动，则不更新当前页索引，动态添加、移除reuseCell
 *  如果是滑动，则在滑动动画结束时，更新当前页索引，移除reuseCell
 *  tag == 0:当前展示的 / tag == 1:reuseCell
 */

- (void)manageCellReuse
{
    CGPoint contentOffset = self.contentOffset;
    CGSize  baseSize = self.frame.size;
    CGFloat pageParams = 0;
    pageParams = contentOffset.x/baseSize.width;
    
    // # Jump Immediately #
    if (_jumpInfo.isImmediateJump) {
        if (ABS(_jumpInfo.targetIndex - pageParams) == 1)
        {
            _jumpInfo.isImmediateJump = NO;
            _jumpInfo.targetIndex = -1;
        }
        return;
    }
    
    // # Jumping #
    // begin to jump
    if (_jumpInfo.isJumping && _jumpInfo.targetIndex >= 0)
    {
        pageParams = _jumpInfo.targetIndex;
        [self addReuseCellAtIndex:pageParams];
        if (!self.decelerating)
            _jumpInfo.isJumping = NO;
        if (!_jumpInfo.isAnimated) {
            [self endJumpAction];
        }
        return;
    }
    
    // end jump
    if (_jumpInfo.targetIndex == pageParams)
    {
        [self endJumpAction];
        return;
    }
    
    // # Confirm target page number #
    NSInteger targetPage = (pageParams>_currentPageNumber?ceilf(pageParams):floor(pageParams));
    if (targetPage > _pageCount-1 || targetPage < 0)
        return;
    
    // # Panning #
    if (_isPanning)
    {
        // when page is at current index
        if (targetPage == _currentPageNumber) {
            [self removeReuseCell];
            return;
        }
        if (targetPage == _reuseCell.targetIndex) {
            return;
        }
        [self addReuseCellAtIndex:targetPage];
        return;
    }
    
    // # Scrolling #
    BOOL needUpdate = (NSInteger)pageParams == pageParams;
    if (needUpdate && !_isUpdatingInfo)
    {
        if (_currentPageNumber == targetPage){
            _isPanningEnd = YES;
            _isUpdatingInfo = YES;
            [self removeReuseCell];
//            NSLog(@"--->panning end remove<---");
        }else{
            [self updateCurrentPageNumber];
            [self removeReuseCell];
//            NSLog(@"---> scroll end <---");
        }
    }
    if(!needUpdate)
    {
        _isUpdatingInfo = NO;
    }
}

/**
 *  End Jump Action
 */
- (void)endJumpAction
{
    [self updateCurrentPageNumber];
    [self removeReuseCell];
    _jumpInfo.targetIndex = -1;
    _jumpInfo.isAnimated = YES;
}

/**
 * Update current page number
 */
- (void)updateCurrentPageNumber
{
//    NSLog(@"update");
    _isUpdatingInfo = YES;
    
    CGPoint contentOffset = self.contentOffset;
    CGSize  baseSize = self.frame.size;
    NSInteger target = contentOffset.x/baseSize.width;
    _currentPageNumber = target;
    
    [self didEndAnimationAtIndex:target];
}

/**
 *  remove the reuse cell from scroll view
 */
- (void)removeReuseCell
{
    for (SPReuseCell *cell in _cellSet) {
        // when user panning,the shown page doesn't change
        if (!_isPanning && !_isPanningEnd) {
            cell.tag = cell.tag?0:1;
        }
        if (cell.tag && cell.superview){
            _reuseCell = cell;
            _reuseCell.targetIndex = -1;
            [_reuseCell.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [cell removeFromSuperview];
//            NSLog(@"---> Remove At:%ld<---",_currentPageNumber);
        }
    }
    _isPanningEnd = NO;
}

/**
 *  add the reuse cell
 */
- (void)addReuseCellAtIndex:(NSInteger)target
{
    CGSize  baseSize = self.frame.size;
    _reuseCell = [self getReuseCell:YES];
    _reuseCell.targetIndex = target;
    _reuseCell.frame = (CGRect){CGPointMake(target*baseSize.width, 0),_reuseCell.frame.size};
    UIView *page = [self viewForIndex:target];
    [_reuseCell addSubview:page];
    [self addSubview:_reuseCell];
//    NSLog(@"---> Add Page:%ld <---",target);
}

/**
 *  get the reuse cell
 *  NO: the shown cell
 *  YES: the reuse cell
 */
- (SPReuseCell *)getReuseCell:(BOOL)isReuse
{
    SPReuseCell *targetCell = nil;
    for (SPReuseCell *cell in _cellSet){
        if (cell.tag == (isReuse?1:0)) {
            targetCell = cell;
            break;
        }
    }
    return targetCell;
}

#pragma mark - Delegate
- (void)didEndAnimationAtIndex:(NSInteger)index
{
    if (_spDelegateRespondsTo.didEndBounce) {
        UIView *pageView = [_pageMap objectForKey:@(index)];
        [self.sp_delegete scrollPageDidEndBounceAtPage:pageView index:index];
    }
}

- (UIView *)viewForIndex:(NSInteger)index
{
    UIView *page = nil;
    if (_spDelegateRespondsTo.pageForIndex) {
        page = [self.sp_delegete scrollPageView:self pageForIndex:index];
        if (![_pageMap objectForKey:@(index)]) {
            [_pageMap setObject:page forKey:@(index)];
        }
    }
    return page;
}

#pragma mark - Action
- (void)jumpToIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0) return;
    if (index > _pageCount - 1) return;
    
    _jumpInfo.isJumping = YES;
    _jumpInfo.isAnimated = animated;
    _jumpInfo.targetIndex = index;
    
    CGSize  baseSize = self.frame.size;
    [self setContentOffset:CGPointMake(baseSize.width * index, 0)
                  animated:animated];
}

- (void)jumpImmediatelyToIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0) return;
    if (index > _pageCount - 1) return;
    if (!animated)
    {
        [self jumpToIndex:index animated:NO];
        return;
    }
    
    CGSize  baseSize = self.frame.size;
    SPReuseCell *shownCell = [self getReuseCell:NO];
    
    if (ABS(index-_currentPageNumber) > 1) {
        _jumpInfo.isImmediateJump = YES;
        _jumpInfo.targetIndex = index;
        NSInteger tempIndex = index>_currentPageNumber?index-1:index+1;
        shownCell.frame = CGRectMake(tempIndex*baseSize.width, 0, baseSize.width, baseSize.height);
        [self setContentOffset:CGPointMake(baseSize.width*tempIndex, 0) animated:NO];
    }
    [self jumpToIndex:index animated:animated];
}


#pragma mark - Dequeue Page View
- (UIView *)dequeuePageViewWithIndex:(NSInteger)index
{
    return [_pageMap objectForKey:@(index)];
}

#pragma mark - Override
- (void)setPagingEnabled:(BOOL)pagingEnabled
{
    pagingEnabled = YES;
    [super setPagingEnabled:pagingEnabled];
}

#pragma mark - Set/Get
- (void)setSp_delegete:(id<SPScrollPageViewDelegate>)asp_delegete
{
    if (sp_delegete != asp_delegete) {
        sp_delegete = asp_delegete;
        
        _spDelegateRespondsTo.didEndBounce = [sp_delegete respondsToSelector:
                                              @selector(scrollPageDidEndBounceAtPage:index:)];
        _spDelegateRespondsTo.pageForIndex = [sp_delegete respondsToSelector:
                                              @selector(scrollPageView:pageForIndex:)];
    }
}

#pragma mark - dealloc
- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentOffset"];
}

@end
