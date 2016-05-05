//
//  XYBubbleChartDataSet.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

public class XYBubbleChartDataSet: XYChartDataSet, IXYBubbleChartDataSet
{
    // MARK: - Data functions and accessors
    
    internal var _maxSize = CGFloat(0.0)
    internal var _minSize = CGFloat(0.0)
    public var maxSize: CGFloat { return _maxSize }
    public var minSize: CGFloat { return _minSize }
    
    public var fill: ChartFill?
    
    public override func calcMinMax(startx startx: Double, endx: Double, starty:Double, endy:Double)
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
        _maxSize = CGFloat.min
        _minSize = CGFloat.max
        
        // ignore start and end
        for (var i = 0; i < _yVals.count; i++)
        {
            let e = _yVals[i] as! XYBubbleChartDataEntity
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
                if(!e.size.isNaN)
                {
                    _maxSize = max(_maxSize, e.size)
                    _minSize = min(_minSize, e.size)
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
        if(_minSize == CGFloat.max)
        {
            _maxSize = CGFloat(0.0)
            _minSize = CGFloat(0.0)
        }
    }

    /// the formatter used to customly format the values
    internal var _sizeValueFormatter: NSNumberFormatter? = ChartUtils.defaultValueFormatter()
    
    /// The formatter used to customly format the values
    public var sizeValueFormatter: NSNumberFormatter?
        {
        get
        {
            return _sizeValueFormatter
        }
        set
        {
            if newValue == nil
            {
                _sizeValueFormatter = ChartUtils.defaultValueFormatter()
            }
            else
            {
                _sizeValueFormatter = newValue
            }
        }
    }
    
    // MARK: - Styling functions and accessors
    
    /// Sets/gets the width of the circle that surrounds the bubble when highlighted
    public var highlightCircleWidth: CGFloat = 2.5
    
    // MARK: - NSCopying
    
    public override func copyWithZone(zone: NSZone) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! XYBubbleChartDataSet
        copy._maxSize = _maxSize
        copy._minSize = _minSize
        copy._sizeValueFormatter = _sizeValueFormatter
        copy.highlightCircleWidth = highlightCircleWidth
        copy.fill = fill
        return copy
    }
}