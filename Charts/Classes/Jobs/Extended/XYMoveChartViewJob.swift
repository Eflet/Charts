//
//  XYMoveChartViewJob.swift
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

public class XYMoveChartViewJob: XYChartViewPortJob
{
    public override init(
        viewPortHandler: ChartViewPortHandler,
        xValue: Double,
        yValue: Double,
        transformer: ChartTransformer,
        view: XYChartViewBase)
    {
        super.init(
            viewPortHandler: viewPortHandler,
            xValue: xValue,
            yValue: yValue,
            transformer: transformer,
            view: view)
    }
    
    public override func doJob()
    {
        guard let
            viewPortHandler = viewPortHandler,
            transformer = transformer,
            view = view
            else { return }
        
        var pt = CGPoint(
            x: CGFloat(xValue), 
            y: CGFloat(yValue)
        );
        
        transformer.pointValueToPixel(&pt)
        viewPortHandler.centerViewPort(pt: pt, chart: view)
    }
}