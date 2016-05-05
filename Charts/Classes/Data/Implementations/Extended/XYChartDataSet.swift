//
//  XYChartDataSet.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

public class XYChartDataSet: ChartDataSet, IXYChartDataSet
{
    // MARK: - Data functions and accessors
    internal var _xMax = Double(0.0)
    internal var _xMin = Double(0.0)
    
    internal var _lastMaxx = DBL_MAX
    internal var _lastMinx = -DBL_MAX
    internal var _lastMaxy = DBL_MAX
    internal var _lastMiny = -DBL_MAX
    
    // MARK: - Styling functions and accessors
    
    public var highlightColor = NSUIColor(red: 255.0/255.0, green: 187.0/255.0, blue: 115.0/255.0, alpha: 1.0)
    public var highlightLineWidth = CGFloat(0.5)
    public var highlightLineDashPhase = CGFloat(0.0)
    public var highlightLineDashLengths: [CGFloat]?
    
    public func calcMinMax(startx startx: Double, endx: Double, starty:Double, endy:Double)
    {
        let yValCount = _yVals.count
        
        if yValCount == 0
        {
            return
        }
        
        _lastMinx = startx == Double.infinity ? -DBL_MAX : startx
        _lastMaxx = endx == Double.infinity ? DBL_MAX : endx
        _lastMiny = starty == Double.infinity ? -DBL_MAX : starty
        _lastMaxy = endy == Double.infinity ? DBL_MAX : endy
        
        _yMin = DBL_MAX
        _yMax = -DBL_MAX
        _xMin = DBL_MAX
        _xMax = -DBL_MAX
        
        for (var i = 0; i < _yVals.count; i++)
        {
            let e = _yVals[i] as! XYChartDataEntry
            if(_lastMinx < e.xvalue && e.xvalue <= _lastMaxx
                && _lastMiny < e.yvalue && e.yvalue <= _lastMaxy)
            {
                if (!e.yvalue.isNaN)
                {
                    _yMin = min(_yMin, e.yvalue)
                    _yMax = max(_yMax, e.yvalue)
                }
                if (!e.xvalue.isNaN)
                {
                    _xMin = min(_xMin, e.xvalue)
                    _xMax = max(_xMax, e.xvalue)
                }
            }
        }
        
        if (_yMin == DBL_MAX)
        {
            _yMin = 0.0
            _yMax = 0.0
        }
        if(_xMin == DBL_MAX)
        {
            _xMin = 0.0
            _xMax = 0.0
        }
    }
    
    public override func calcMinMax(start start: Int, end: Int)
    {
        calcMinMax(startx: _lastMinx , endx: _lastMaxx, starty: _lastMiny, endy: _lastMaxy)
    }
    
    /// the formatter used to customly format the values
    internal var _xValueFormatter: NSNumberFormatter? = ChartUtils.defaultValueFormatter()
    
    /// The formatter used to customly format the values
    public var xValueFormatter: NSNumberFormatter?
    {
        get
        {
            return _xValueFormatter
        }
        set
        {
            if newValue == nil
            {
                _xValueFormatter = ChartUtils.defaultValueFormatter()
            }
            else
            {
                _xValueFormatter = newValue
            }
        }
    }
    
    /// the formatter used to customly format the values
    internal var _yValueFormatter: NSNumberFormatter? = ChartUtils.defaultValueFormatter()
    
    /// The formatter used to customly format the values
    public var yValueFormatter: NSNumberFormatter?
    {
        get
        {
            return _yValueFormatter
        }
        set
        {
            if newValue == nil
            {
                _yValueFormatter = ChartUtils.defaultValueFormatter()
            }
            else
            {
                _yValueFormatter = newValue
            }
        }
    }
    
    /// - returns: the minimum x-value this DataSet holds
    public var xMin: Double { return _xMin }
    
    /// - returns: the maximum x-value this DataSet holds
    public var xMax: Double { return _xMax }
    
    /// - returns: the x value of the Entry object at the given xIndex. Returns NaN if no value is at the given x-index.
    public func xValForXIndex(x: Int) -> Double
    {
        let e = self.entryForXIndex(x)
        
        if (e !== nil && e!.xIndex == x) { return (e as! XYChartDataEntry).xvalue }
        else { return Double.NaN }
    }
    
    public override func yValForXIndex(x: Int) -> Double
    {
        let e = self.entryForXIndex(x)
        
        if (e !== nil && e!.xIndex == x) { return (e as! XYChartDataEntry).yvalue }
        else { return Double.NaN }
    }
    
    public override func entryForIndex(i: Int) -> XYChartDataEntry?
    {
        return _yVals[i] as? XYChartDataEntry
    }
    
    /// Adds an Entry to the DataSet dynamically.
    /// Entries are added to the end of the list.
    /// This will also recalculate the current minimum and maximum values of the DataSet and the value-sum.
    /// - parameter e: the entry to add
    /// - returns: true
    public override func addEntry(e: ChartDataEntry) -> Bool
    {
        super.addEntry(e)
        let xval = (e as! XYChartDataEntry).xvalue
        _xMax = max(_xMax, xval)
        _xMin = min(_xMin, xval)
        return true
    }
    
    /// Adds an Entry to the DataSet dynamically.
    /// Entries are added to their appropriate index respective to it's x-index.
    /// This will also recalculate the current minimum and maximum values of the DataSet and the value-sum.
    /// - parameter e: the entry to add
    /// - returns: true
    public override func addEntryOrdered(e: ChartDataEntry) -> Bool
    {
        super.addEntryOrdered(e)
        let xval = (e as! XYChartDataEntry).xvalue
        _xMax = max(_xMax, xval)
        _xMin = min(_xMin, xval)
        return true
    }

    /// Enables / disables the horizontal highlight-indicator. If disabled, the indicator is not drawn.
    public var drawHorizontalHighlightIndicatorEnabled = true
    
    /// Enables / disables the vertical highlight-indicator. If disabled, the indicator is not drawn.
    public var drawVerticalHighlightIndicatorEnabled = true
    
    /// - returns: true if horizontal highlight indicator lines are enabled (drawn)
    public var isHorizontalHighlightIndicatorEnabled: Bool { return drawHorizontalHighlightIndicatorEnabled }
    
    /// - returns: true if vertical highlight indicator lines are enabled (drawn)
    public var isVerticalHighlightIndicatorEnabled: Bool { return drawVerticalHighlightIndicatorEnabled }
    
    /// Enables / disables both vertical and horizontal highlight-indicators.
    /// :param: enabled
    public func setDrawHighlightIndicators(enabled: Bool)
    {
        drawHorizontalHighlightIndicatorEnabled = enabled
        drawVerticalHighlightIndicatorEnabled = enabled
    }
    
    // MARK: - NSCopying
    
    public override func copyWithZone(zone: NSZone) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! XYChartDataSet
        copy._xMax = _xMax
        copy._xMin = _xMin
        copy.highlightColor = highlightColor
        copy.highlightLineWidth = highlightLineWidth
        copy.highlightLineDashPhase = highlightLineDashPhase
        copy.highlightLineDashLengths = highlightLineDashLengths
        copy.drawHorizontalHighlightIndicatorEnabled = drawHorizontalHighlightIndicatorEnabled
        copy.drawVerticalHighlightIndicatorEnabled = drawVerticalHighlightIndicatorEnabled
        return copy
    }
}