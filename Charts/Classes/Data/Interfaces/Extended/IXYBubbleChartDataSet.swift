//
//  IXYBubbleChartDataSet.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

@objc
public protocol IXYBubbleChartDataSet: IXYChartDataSet
{
    // MARK: - Data functions and accessors
    var maxSize: CGFloat { get }
    var minSize: CGFloat { get }
   
    /// Returns the object that is used for filling the bubble.
    /// - default: nil
    var fill: ChartFill? { get set }
    
    /// The formatter used to customly format the values
    var sizeValueFormatter: NSNumberFormatter? { get set }
    
    // MARK: - Styling functions and accessors
    
    /// Sets/gets the width of the circle that surrounds the bubble when highlighted
    var highlightCircleWidth: CGFloat { get set }
}
