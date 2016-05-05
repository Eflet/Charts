//
//  XYBubbleChartView.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/26.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

public class XYBubbleChartView: XYChartViewBase, XYBubbleChartDataProvider
{
    /// The max bubble size depend on min(contentWidth, contentHeight) * bubbleSizeFactor
    public var bubbleSizeFactor = CGFloat(0.2)
    
    public override func initialize()
    {
        super.initialize()
        renderer = XYBubbleChartRenderer(dataProvider: self, animator: _animator, viewPortHandler: _viewPortHandler)
    }
    
    // MARK: - BubbleChartDataProbider
    
    public var bubbleData: XYBubbleChartData? { return _data as? XYBubbleChartData }
}