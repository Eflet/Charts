//
//  XYAnimatedMoveViewJob.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/28.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

public class XYAnimatedMoveChartViewJob: XYAnimatedViewPortJob
{
    public override init(
        viewPortHandler: ChartViewPortHandler,
        xValue: Double,
        yValue: Double,
        transformer: ChartTransformer,
        view: XYChartViewBase,
        xOrigin: CGFloat,
        yOrigin: CGFloat,
        duration: NSTimeInterval,
        easing: ChartEasingFunctionBlock?)
    {
        super.init(viewPortHandler: viewPortHandler,
            xValue: xValue,
            yValue: yValue,
            transformer: transformer,
            view: view,
            xOrigin: xOrigin,
            yOrigin: yOrigin,
            duration: duration,
            easing: easing)
    }
    
    internal override func animationUpdate()
    {
        guard let
            viewPortHandler = viewPortHandler,
            transformer = transformer,
            view = view
            else { return }
        
        var pt = CGPoint(
            x: xOrigin + (CGFloat(xValue) - xOrigin) * phase,
            y: yOrigin + (CGFloat(yValue) - yOrigin) * phase
        );
        
        transformer.pointValueToPixel(&pt)
        viewPortHandler.centerViewPort(pt: pt, chart: view)
    }
}