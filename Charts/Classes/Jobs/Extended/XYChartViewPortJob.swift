//
//  XYChartViewPortJob.swift
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

public class XYChartViewPortJob: ChartViewPortJob
{
    internal var xValue: Double = 0.0
    
    public init(
        viewPortHandler: ChartViewPortHandler,
        xValue: Double,
        yValue: Double,
        transformer: ChartTransformer,
        view: XYChartViewBase)
    {
        super.init(viewPortHandler: viewPortHandler, xIndex: CGFloat(xValue), yValue: yValue, transformer: transformer, view: view)
        self.xValue = xValue
    }
}