//
//  XYBubbleChartData.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

public class XYBubbleChartData: XYChartData
{
    internal var _maxSize = CGFloat(0.0)
    internal var _minSize = CGFloat(0.0)
    public var maxSize: CGFloat { return _maxSize }
    public var minSize: CGFloat { return _minSize }
    
    
    public override init()
    {
        super.init()
    }
    
    public override init(dataSets: [IChartDataSet]?)
    {
        super.init(dataSets: dataSets)
    }
    
    public override func calcMinMax(startx startx: Double, endx: Double, starty:Double, endy:Double)
    {
        if (_dataSets == nil || _dataSets.count < 1)
        {
            _xMax = 0.0
            _xMin = 0.0
            _yMax = 0.0
            _yMin = 0.0
            _maxSize = CGFloat(0.0)
            _minSize = CGFloat(0.0)
        }
        else
        {
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
            
            for set in _dataSets as! [IXYBubbleChartDataSet]!
            {
                set.calcMinMax(startx: _lastMinx , endx: _lastMaxx, starty: _lastMiny, endy: _lastMaxy)
                _yMin = min(_yMin, set.yMin)
                _yMax = max(_yMax, set.yMax)
                _xMin = min(_xMin, set.xMin)
                _xMax = max(_xMax, set.xMax)
                _maxSize = max(_maxSize, set.maxSize)
                _minSize = min(_minSize, set.minSize)
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
    }
    
    /// Sets the width of the circle that surrounds the bubble when highlighted for all DataSet objects this data object contains
    public func setHighlightCircleWidth(width: CGFloat)
    {
        for set in _dataSets as! [IXYBubbleChartDataSet]!
        {
            set.highlightCircleWidth = width
        }
    }
}