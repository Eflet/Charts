//
//  XYBubbleChartDataProvider.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/25.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

@objc
public protocol XYBubbleChartDataProvider: XYChartDataProvider
{
    var bubbleData: XYBubbleChartData? { get }
    
    var bubbleSizeFactor: CGFloat { get }
}