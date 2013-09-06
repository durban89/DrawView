//
//  DrawView.m
//  SendingComplexObjects
//
//  Created by david on 13-9-6.
//  Copyright (c) 2013年 WalkerFree. All rights reserved.
//

#import "DrawView.h"

@interface UIColor(utilities)

@end
@implementation UIColor(utilities)

-(NSString *) stringFromColor
{
    const CGFloat *c = CGColorGetComponents(self.CGColor);
    CGColorSpaceModel csm = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    return (csm == kCGColorSpaceModelRGB) ?
    [NSString stringWithFormat:@"%0.2f %0.2f %0.2f %0.2f", c[0], c[1], c[2], c[3]]
    :
    [NSString stringWithFormat:@"%0.2f %0.2f %0.2f %0.2f", c[0], c[0], c[0], c[1]];

}

+(UIColor *) colorWithString: (NSString *) colorString
{
    const CGFloat c[4];
    sscanf([colorString cStringUsingEncoding:NSUTF8StringEncoding], "%f %f %f %f", &c[0], &c[1], &c[2], &c[3]);
    return [UIColor colorWithRed:c[0] green:c[1] blue:c[2] alpha:c[3]];
}

@end


#pragma mark - DrawView
@implementation DrawView
@synthesize points;
@synthesize currentColor;
@synthesize foreignPoints;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    //archive drawing
    [aCoder encodeCGRect:self.frame forKey:@"viewFrame"];
    [aCoder encodeObject:self.points forKey:@"points"];
    [aCoder encodeObject:self.foreignPoints forKey:@"fpoints"];
    
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    //restore drawing
//    [super initWithFrame:CGRectZero];
    self.frame = [aDecoder decodeCGRectForKey:@"viewFrame"];
    self.points = [aDecoder decodeObjectForKey:@"points"];
    self.foreignPoints = [aDecoder decodeObjectForKey:@"fpoints"];
    self.currentColor = [UIColor whiteColor];
    self.userInteractionEnabled = YES;
    return self;
}

-(void) transmit
{
    if(![GameKitHelper sharedInstance].isConnected) return ;
    if(!self.points)
    {
        [GameKitHelper sendData:[@"clear" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        NSString *errorString;
        NSData *plistdata = [NSPropertyListSerialization dataFromPropertyList:self.points
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                             errorDescription:&errorString];
        if(plistdata)
        {
            [GameKitHelper sendData:plistdata];
        }
        else
        {
            CFShow((__bridge CFTypeRef)(errorString));
        }
    }
}

- (void) clear
{
    //Upon clear
    self.points = [NSMutableArray array];
    self.foreignPoints = [NSMutableArray array];
    [self transmit];
    [self setNeedsDisplay];
    
}

-(void) connectionEstablished
{
    if(self.points && (self.points.count > 0))
    {
        [self transmit];
    }
}

-(void) receivedData:(NSData *)data
{
    //check for clear
    NSString *string = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];
    if([string isEqualToString:@"clear"])
    {
        self.foreignPoints = [NSMutableArray array];
        self.points = [NSMutableArray array];
        [self setNeedsDisplay];
        return;
    }
    
    //Otherwise handle points
    CFStringRef errorString;
    CFPropertyListRef plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)data, kCFPropertyListMutableContainers, &errorString);
    if(!plist)
    {
        CFShow(errorString);
        return;
    }
    
    if(self.foreignPoints.count == 0)
    {
        self.points = [NSMutableArray array];
    }
    [self setNeedsDisplay];
}

-(BOOL) isMultipleTouchEnabled
{
    return  NO;
}

//Start new dictionary for each touch, with points and color
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(!self.points)
    {
        self.points = [NSMutableArray array];
    }
    
    if(!self.currentColor)
    {
        self.currentColor = [UIColor whiteColor];
    }
    
    NSMutableArray *newArray = [NSMutableArray array];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:newArray forKey:@"points"];
    [dict setObject:[self.currentColor stringFromColor] forKey:@"color"];
    
    CGPoint pt = [[touches anyObject] locationInView:self];
    [newArray addObject:NSStringFromCGPoint(pt)];
    [self.points addObject:dict];
}

//Add each point to points array
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint pt = [[touches anyObject] locationInView:self];
    NSMutableArray *pointArray = [[self.points lastObject] objectForKey:@"points"];
    [pointArray addObject:NSStringFromCGPoint(pt)];
    [self setNeedsDisplay];
}

//Send over nwe trace when the touch ends
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self transmit];
}

//Draw all points, foreign and domestic, to the screen
-(void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, CGRectMake(0.0f, 0.0f, 320.f, 416.0f));
    
    if(self.points)
    {
        int arraynum = 0;
        for(NSDictionary *dict in self.points)
        {
            NSArray *ptarray = [dict objectForKey:@"points"];
            UIColor *color = [UIColor colorWithString:[dict objectForKey:@"color"]];
            [color set];
            if(ptarray.count < 3)
            {
                arraynum++;
                continue;
            }
            
            CGContextSetLineWidth(context, 4.0f);
            for(int i=0; i < (ptarray.count - 1);i++)
            {
                CGPoint pt1 = CGPointFromString([ptarray objectAtIndex:i]);
                CGPoint pt2 = CGPointFromString([ptarray objectAtIndex:i+1]);
                CGContextMoveToPoint(context, pt1.x, pt1.y);
                CGContextAddLineToPoint(context, pt2.x, pt2.y);
                CGContextStrokePath(context);
            }
            arraynum++;
        }
    }
    
    if(self.foreignPoints)
    {
        int arraynum = 0;
        for(NSDictionary *dict in self.foreignPoints)
        {
            NSArray *ptarray = [dict objectForKey:@"points"];
            UIColor *color = [UIColor colorWithString:[dict objectForKey:@"color"]];
            [color set];
            
            if(ptarray.count < 3)
            {
                arraynum++;
                continue;
            }
            
            CGContextSetLineWidth(context, 4.0f);
            for(int i=0; i < (ptarray.count - 1);i++)
            {
                CGPoint pt1 = CGPointFromString([ptarray objectAtIndex:i]);
                CGPoint pt2 = CGPointFromString([ptarray objectAtIndex:i+1]);
                CGContextMoveToPoint(context, pt1.x, pt1.y);
                CGContextAddLineToPoint(context, pt2.x, pt2.y);
                CGContextStrokePath(context);
            }
            arraynum++;
        }
        
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
