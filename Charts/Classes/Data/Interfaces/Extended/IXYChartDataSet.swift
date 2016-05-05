//
//  IXYChartDataSet.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

import Foundation
import CoreGraphics

@objc
public protocol IXYChartDataSet: IChartDataSet
{
    // MARK: - Data functions and accessors
    
    var yMin: Double { get }
    var yMax: Double { get }
    var xMin: Double { get }
    var xMax: Double { get }
    
    /// The formatter used to customly format the values
    var xValueFormatter: NSNumberFormatter? { get set }
    /// The formatter used to customly format the values
    var yValueFormatter: NSNumberFormatter? { get set }
    
    /// - returns: the x value of the Entry object at the given xIndex. Returns NaN if no value is at the given x-index.
    func yValForXIndex(x: Int) -> Double
    func xValForXIndex(x: Int) -> Double
    
    func entryForIndex(i: Int) -> XYChartDataEntry?
    
    /// This is an opportunity to calculate the minimum and maximum y/x value in the specified range.
    /// If your data is in an array, you might loop over them to find the values.
    /// If your data is in a database, you might query for the min/max and put them in variables.
    /// - parameter startx: the minx of the entry x entry to calculate
    /// - parameter endx: the maxx of the entry x to calculate
    /// - parameter starty: the minx of the entry y entry to calculate
    /// - parameter endy: the maxx of the entry y to calculate
    func calcMinMax(startx startx: Double, endx: Double, starty:Double, endy:Double)
    
     // MARK: - Styling functions and accessors
    
    var highlightColor: NSUIColor { get set }
    var highlightLineWidth: CGFloat { get set }
    var highlightLineDashPhase: CGFloat { get set }
    var highlightLineDashLengths: [CGFloat]? { get set }
    
    /// Enables / disables the horizontal highlight-indicator. If disabled, the indicator is not drawn.
    var drawHorizontalHighlightIndicatorEnabled: Bool { get set }
    
    /// Enables / disables the vertical highlight-indicator. If disabled, the indicator is not drawn.
    var drawVerticalHighlightIndicatorEnabled: Bool { get set }
    
    /// - returns: true if horizontal highlight indicator lines are enabled (drawn)
    var isHorizontalHighlightIndicatorEnabled: Bool { get }
    
    /// - returns: true if vertical highlight indicator lines are enabled (drawn)
    var isVerticalHighlightIndicatorEnabled: Bool { get }
    
    /// Enables / disables both vertical and horizontal highlight-indicators.
    /// :param: enabled
    func setDrawHighlightIndicators(enabled: Bool)
}
