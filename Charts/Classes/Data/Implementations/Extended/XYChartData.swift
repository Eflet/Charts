//
//  XYChartData.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

public class XYChartData : ChartData
{
    internal var _xMax = Double(0.0)
    internal var _xMin = Double(0.0)
    
    internal var _lastMaxx = DBL_MAX
    internal var _lastMinx = -DBL_MAX
    internal var _lastMaxy = DBL_MAX
    internal var _lastMiny = -DBL_MAX
    
    private var _xValCount = Int(0)
    
    public override init()
    {
        super.init()
    }
    
    public init(dataSets: [IChartDataSet]?)
    {
        super.init()
        _dataSets = dataSets == nil ? [IChartDataSet]() : dataSets
        super.initialize(_dataSets)
    }
    
    // Checks if the combination of x-values array and DataSet array is legal or not.
    // :param: dataSets
    internal override func checkIsLegal(dataSets: [IChartDataSet]!)
    {
        if _dataSets == nil
        {
            return
        }
        
        // check each set should be IXYChartDataSet
        for i in 0 ..< dataSets.count
        {
            if !(dataSets[i] is IXYChartDataSet)
            {
                print("One or more of the DataSet Entry is Illegal.", terminator: "\n")
                return
            }
        }
    }
    
    public func calcMinMax(startx startx: Double, endx: Double, starty:Double, endy:Double)
    {
        if (_dataSets == nil || _dataSets.count < 1)
        {
            _xMax = 0.0
            _xMin = 0.0
            _yMax = 0.0
            _yMin = 0.0
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
            
            for set in _dataSets as! [IXYChartDataSet]!
            {
                set.calcMinMax(startx: _lastMinx , endx: _lastMaxx, starty: _lastMiny, endy: _lastMaxy)
                _yMin = min(_yMin, set.yMin)
                _yMax = max(_yMax, set.yMax)
                _xMin = min(_xMin, set.xMin)
                _xMax = max(_xMax, set.xMax)
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
    }
    
    // calc minimum and maximum y and x value over all datasets
    internal override func calcMinMax(start start: Int, end: Int)
    {
        calcMinMax(startx: _lastMinx , endx: _lastMaxx, starty: _lastMiny, endy: _lastMaxy)
    }
    
    public func entryForValue(xvalue: Double, yvalue: Double) -> XYChartDataEntry?
    {
        var e : XYChartDataEntry? = nil
        var min_dist = DBL_MAX
        let xRange = abs(_xMax - _xMin)
        let yRange = abs(_yMax - _yMin)
        for i in 0 ..< _dataSets.count
        {
            let set = _dataSets[i] as! IXYChartDataSet
            for j in 0 ..< set.entryCount
            {
                guard let ie = set.entryForIndex(j) else { continue }
                let distX = abs(xvalue - ie.xvalue)
                let distY = abs(yvalue - ie.yvalue)
                // we can not use xvalue and yvalue to calculate the distance because x and y may have different unit
                let fix_distx = distX / xRange
                let fix_disty = distY / yRange
                let dist = pow(fix_distx,2)+pow(fix_disty,2)
                if(dist < min_dist){
                    e = ie
                    min_dist = dist
                }
            }
            
        }
        return e
    }
    
    internal override func calcYValueCount()
    {
        super.calcYValueCount()
        // the two cound should be same
        _xValCount = self.yValCount
    }
    
    /// - returns: the smallest x-value the data object contains.
    public var xMin: Double
    {
            return _xMin
    }
    
    public func getXMin() -> Double
    {
        return _xMin
    }
    
    /// - returns: the greatest x-value the data object contains.
    public var xMax: Double
    {
            return _xMax
    }
    
    public func getXMax() -> Double
    {
        return _xMax
    }
    
    /// - returns: the total number of x-values across all DataSet objects the this object represents.
    public override var xValCount: Int
    {
        return _xValCount
    }
    
    public override func addDataSet(d: IChartDataSet!)
    {
        super.addDataSet(d)
        if (_dataSets == nil)
        {
            return
        }
        let xyd = d as! IXYChartDataSet
        _xMax = max(_xMax, xyd.xMax)
        _xMin = min(_xMin, xyd.xMin)
        _xValCount = self.yValCount
    }
    
    public override func removeDataSetByIndex(index: Int) -> Bool
    {
        super.removeDataSetByIndex(index)
        _xValCount = self.yValCount
        return true
    }
    
    /// Adds an Entry to the DataSet at the specified index. Entries are added to the end of the list.
    public override func addEntry(e: ChartDataEntry, dataSetIndex: Int)
    {
        super.addEntry(e, dataSetIndex: dataSetIndex)
        if _dataSets != nil && _dataSets.count > dataSetIndex && dataSetIndex >= 0
        {
            let set = _dataSets[dataSetIndex] as! IXYChartDataSet
            _xMax = max(_xMax, set.xMax)
            _xMin = min(_xMin, set.xMin)
            
            _xValCount = self.yValCount
        }
        else
        {
            print("ChartData.addEntry() - dataSetIndex our of range.", terminator: "\n")
        }
    }
    
    /// Removes the given Entry object from the DataSet at the specified index.
    public override func removeEntry(entry: ChartDataEntry!, dataSetIndex: Int) -> Bool
    {
        let removed = super.removeEntry(entry, dataSetIndex: dataSetIndex)
        _xValCount = self.yValCount
        return removed
    }
}