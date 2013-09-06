//
//  DrawView.h
//  SendingComplexObjects
//
//  Created by david on 13-9-6.
//  Copyright (c) 2013年 WalkerFree. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameKitHelper.h"

@interface DrawView : UIView<GameKitHelperDataDelegate>

@property (retain) NSMutableArray *points;
@property (retain) NSArray *foreignPoints;
@property (retain) UIColor *currentColor;
- (void) clear;

@end
