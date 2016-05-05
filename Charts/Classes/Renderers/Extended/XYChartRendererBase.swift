//
//  XYChartRenderBase.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/25.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

import Foundation
import CoreGraphics

public class XYChartRendererBase: ChartDataRendererBase
{
    public override init(animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
    }
    
    /// Draws vertical & horizontal highlight-lines if enabled.
    /// :param: context
    /// :param: points
    /// :param: horizontal
    /// :param: vertical
    public func drawHighlightLines(context context: CGContext, point: CGPoint, set: IXYChartDataSet)
    {
        CGContextSetStrokeColorWithColor(context, set.highlightColor.CGColor)
        CGContextSetLineWidth(context, set.highlightLineWidth)
        if (set.highlightLineDashLengths != nil)
        {
            CGContextSetLineDash(context, set.highlightLineDashPhase, set.highlightLineDashLengths!, set.highlightLineDashLengths!.count)
        }
        else
        {
            CGContextSetLineDash(context, 0.0, nil, 0)
        }
        
        // draw vertical highlight lines
        if set.isVerticalHighlightIndicatorEnabled
        {
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, point.x, viewPortHandler.contentTop)
            CGContextAddLineToPoint(context, point.x, viewPortHandler.contentBottom)
            CGContextStrokePath(context)
        }
        
        // draw horizontal highlight lines
        if set.isHorizontalHighlightIndicatorEnabled
        {
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, viewPortHandler.contentLeft, point.y)
            CGContextAddLineToPoint(context, viewPortHandler.contentRight, point.y)
            CGContextStrokePath(context)
        }
    }
}