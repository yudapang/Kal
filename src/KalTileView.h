/*
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <UIKit/UIKit.h>

typedef enum {
    KalTileTypeRegular   = 0,
    KalTileTypeAdjacent  = 1 << 0,
    KalTileTypeToday     = 1 << 1,
    KalTileTypeFirst     = 1 << 2,
    KalTileTypeLast      = 1 << 3,
    KalTileTypeDisable   = 1 << 4,
} KalTileType;

@interface KalTileView : UIView
{
    CGPoint origin;
    struct {
        unsigned int selected : 1;
        unsigned int highlighted : 1;
        unsigned int marked : 1;
    } flags;
}

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isMarked) BOOL marked;
@property (nonatomic, assign) KalTileType type;

- (void)resetState;
- (BOOL)isToday;
- (BOOL)isFirst;
- (BOOL)isLast;
- (BOOL)isDisable;
- (BOOL)belongsToAdjacentMonth;

@end
