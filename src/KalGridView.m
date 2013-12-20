/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>

#import "KalGridView.h"
#import "KalView.h"
#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalLogic.h"
#import "KalDate.h"
#import "KalPrivate.h"
#import "NSDate+Convenience.h"

#define SLIDE_NONE 0
#define SLIDE_UP 1
#define SLIDE_DOWN 2

const CGSize kTileSize = { 46.f, 44.f };

static NSString *kSlideAnimationId = @"KalSwitchMonths";

@interface KalGridView ()

@property (nonatomic, strong) KalTileView *beginTile;
@property (nonatomic, strong) KalTileView *endTile;
@property (nonatomic, strong) NSMutableArray *highligthedTiles;

- (void)swapMonthViews;

@end

@implementation KalGridView

- (void)setBeginTile:(KalTileView *)beginTile
{
    _beginTile.selected = NO;
    _beginTile = beginTile;
    _beginTile.selected = YES;
    [self removeHighlights];
}

- (void)setEndTile:(KalTileView *)endTile
{
    _endTile.selected = NO;
    _endTile = endTile;
    
    KalTileView *realBeginTile;
    KalTileView *realEndTile;
    
    self.endTile.selected = YES;
    [self removeHighlights];
    
    if (self.endTile.date == self.beginTile.date) {
        return;
    } else if ([self.beginTile.date compare:self.endTile.date] == NSOrderedAscending) {
        realBeginTile = self.beginTile;
        realEndTile = self.endTile;
    } else {
        realBeginTile = self.endTile;
        realEndTile = self.beginTile;
    }

    int dayCount = [NSDate dayBetweenStartDate:[realBeginTile.date NSDate] endDate:[realEndTile.date NSDate]];
    for (int i=1; i<dayCount; i++) {
        NSDate *nextDay = [[realBeginTile.date NSDate] offsetDay:i];
        NSLog(@"highlighted %@", [NSDate stringFromDate:nextDay format:nil]);
        KalTileView *nextTile = [frontMonthView tileForDate:[KalDate dateFromNSDate:nextDay]];
        nextTile.highlighted = YES;
        [nextTile setNeedsDisplay];
        [self.highligthedTiles addObject:nextTile];
    }
}

- (void)removeHighlights
{
    for (KalTileView *tile in self.highligthedTiles) {
        tile.highlighted = NO;
    }
    [self.highligthedTiles removeAllObjects];
}

- (id)initWithFrame:(CGRect)frame logic:(KalLogic *)theLogic delegate:(id<KalViewDelegate>)theDelegate
{
    // MobileCal uses 46px wide tiles, with a 2px inner stroke
    // along the top and right edges. Since there are 7 columns,
    // the width needs to be 46*7 (322px). But the iPhone's screen
    // is only 320px wide, so we need to make the
    // frame extend just beyond the right edge of the screen
    // to accomodate all 7 columns. The 7th day's 2px inner stroke
    // will be clipped off the screen, but that's fine because
    // MobileCal does the same thing.
    frame.size.width = 7 * kTileSize.width;
    
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        logic = theLogic;
        delegate = theDelegate;
        
        CGRect monthRect = CGRectMake(0.f, 0.f, frame.size.width, frame.size.height);
        frontMonthView = [[KalMonthView alloc] initWithFrame:monthRect];
        backMonthView = [[KalMonthView alloc] initWithFrame:monthRect];
        backMonthView.hidden = YES;
        [self addSubview:backMonthView];
        [self addSubview:frontMonthView];
        
        self.selectionMode = KalSelectionModeSingle;
        _highligthedTiles = [[NSMutableArray alloc] init];
        
        [self jumpToSelectedMonth];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
  [[UIImage imageNamed:@"Kal.bundle/kal_grid_background.png"] drawInRect:rect];
  [[UIColor colorWithRed:0.63f green:0.65f blue:0.68f alpha:1.f] setFill];
  CGRect line;
  line.origin = CGPointMake(0.f, self.height - 1.f);
  line.size = CGSizeMake(self.width, 1.f);
  CGContextFillRect(UIGraphicsGetCurrentContext(), line);
}

- (void)sizeToFit
{
  self.height = frontMonthView.height;
}

#pragma mark -
#pragma mark Touches

//- (void)setHighlightedTiles:(NSArray *)tiles
//{
//  if (highlightedTile != tile) {
//    highlightedTile.highlighted = NO;
//    highlightedTile = [tile retain];
//    tile.highlighted = YES;
//    [tile setNeedsDisplay];
//  }
//    for (KalTileView *tile in tiles) {
//        tile.highlighted = YES;
//        [tile setNeedsDisplay];
//    }
//}

- (void)setSelectedTiles:(KalTileView *)tile
{
    tile.selected = YES;
    [delegate didSelectDate:tile.date];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:event];
    
    if (!hitView)
        return;
    
    if ([hitView isKindOfClass:[KalTileView class]]) {
        KalTileView *tile = (KalTileView*)hitView;
        self.beginTile = tile;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    UIView *hitView = [self hitTest:location withEvent:event];
    
    if (!hitView)
        return;
    
    if ([hitView isKindOfClass:[KalTileView class]]) {
        KalTileView *tile = (KalTileView*)hitView;
        if (tile == self.beginTile || tile == self.endTile)
            return;
        if (tile.belongsToAdjacentMonth) {
            if ([tile.date compare:[KalDate dateFromNSDate:logic.baseDate]] == NSOrderedDescending) {
                [delegate showFollowingMonth];
                double delayInSeconds = 1;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    self.beginTile.selected = YES;
                    [self.beginTile setNeedsDisplay];
                });
            } else {
                [delegate showPreviousMonth];
            }
            self.endTile = [frontMonthView tileForDate:tile.date];
        } else {
            self.endTile = tile;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  CGPoint location = [touch locationInView:self];
  UIView *hitView = [self hitTest:location withEvent:event];
  
  if ([hitView isKindOfClass:[KalTileView class]]) {
    KalTileView *tile = (KalTileView*)hitView;
    if (tile.belongsToAdjacentMonth) {
      if ([tile.date compare:[KalDate dateFromNSDate:logic.baseDate]] == NSOrderedDescending) {
        [delegate showFollowingMonth];
      } else {
        [delegate showPreviousMonth];
      }
        self.endTile = [frontMonthView tileForDate:tile.date];
    } else {
        self.endTile = tile;
    }
      self.beginTile.selected = YES;
  }
}

#pragma mark -
#pragma mark Slide Animation

- (void)swapMonthsAndSlide:(int)direction keepOneRow:(BOOL)keepOneRow
{
  backMonthView.hidden = NO;
  
  // set initial positions before the slide
  if (direction == SLIDE_UP) {
    backMonthView.top = keepOneRow
      ? frontMonthView.bottom - kTileSize.height
      : frontMonthView.bottom;
  } else if (direction == SLIDE_DOWN) {
    NSUInteger numWeeksToKeep = keepOneRow ? 1 : 0;
    NSInteger numWeeksToSlide = [backMonthView numWeeks] - numWeeksToKeep;
    backMonthView.top = -numWeeksToSlide * kTileSize.height;
  } else {
    backMonthView.top = 0.f;
  }
  
  // trigger the slide animation
  [UIView beginAnimations:kSlideAnimationId context:NULL]; {
    [UIView setAnimationsEnabled:direction!=SLIDE_NONE];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    
    frontMonthView.top = -backMonthView.top;
    backMonthView.top = 0.f;

    frontMonthView.alpha = 0.f;
    backMonthView.alpha = 1.f;
    
    self.height = backMonthView.height;
    
    [self swapMonthViews];
  } [UIView commitAnimations];
 [UIView setAnimationsEnabled:YES];
}

- (void)slide:(int)direction
{
  self.transitioning = YES;
  
  [backMonthView showDates:logic.daysInSelectedMonth
      leadingAdjacentDates:logic.daysInFinalWeekOfPreviousMonth
     trailingAdjacentDates:logic.daysInFirstWeekOfFollowingMonth];
  
  // At this point, the calendar logic has already been advanced or retreated to the
  // following/previous month, so in order to determine whether there are 
  // any cells to keep, we need to check for a partial week in the month
  // that is sliding offscreen.
  
  BOOL keepOneRow = (direction == SLIDE_UP && [logic.daysInFinalWeekOfPreviousMonth count] > 0)
                 || (direction == SLIDE_DOWN && [logic.daysInFirstWeekOfFollowingMonth count] > 0);
  
  [self swapMonthsAndSlide:direction keepOneRow:keepOneRow];
  
//  self.selectedTile = [frontMonthView firstTileOfMonth];
}

- (void)slideUp { [self slide:SLIDE_UP]; }
- (void)slideDown { [self slide:SLIDE_DOWN]; }

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
  self.transitioning = NO;
  backMonthView.hidden = YES;
}

#pragma mark -

- (void)selectDate:(KalDate *)date
{
//  self.selectedTile = [frontMonthView tileForDate:date];
}

- (void)swapMonthViews
{
  KalMonthView *tmp = backMonthView;
  backMonthView = frontMonthView;
  frontMonthView = tmp;
  [self exchangeSubviewAtIndex:[self.subviews indexOfObject:frontMonthView] withSubviewAtIndex:[self.subviews indexOfObject:backMonthView]];
}

- (void)jumpToSelectedMonth
{
  [self slide:SLIDE_NONE];
}

- (void)markTilesForDates:(NSArray *)dates { [frontMonthView markTilesForDates:dates]; }

- (KalDate *)selectedDate { return self.endTile.date; }

#pragma mark -


@end
