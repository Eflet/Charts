//
//  XYChartDataEntity.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

public class XYChartDataEntry: ChartDataEntry
{
    /// the actual value (y axis)
    public var yvalue = Double(0.0)
    /// the actual value (x axis)
    public var xvalue = Double(0.0)
    
    public required init()
    {
        super.init()
    }
    
    public init(x: Double, y: Double, xIndex: Int)
    {
        super.init(value: y, xIndex: xIndex)
        self.xvalue = x
        self.yvalue = y
    }
    
    public init(x: Double, y: Double, xIndex: Int, data: AnyObject?)
    {
        super.init(value: y, xIndex: xIndex)
        self.xvalue = x
        self.yvalue = y
        self.data = data
    }
    
    // MARK: NSObject
    
    public override func isEqual(object: AnyObject?) -> Bool
    {
        if (object === nil)
        {
            return false
        }
        
        if (!object!.isKindOfClass(self.dynamicType))
        {
            return false
        }
        
        if ((object as! ChartDataEntry).data !== data && !object!.data.isEqual(self.data))
        {
            return false
        }
        
        if ((object as! ChartDataEntry).xIndex != xIndex)
        {
            return false
        }
        
        if (fabs((object as! XYChartDataEntry).xvalue - xvalue) > 0.00001)
        {
            return false
        }
        
        if (fabs((object as! XYChartDataEntry).yvalue - yvalue) > 0.00001)
        {
            return false
        }
        
        return true
    }
    
    // MARK: NSObject
    
    public override var description: String
    {
        return "XYChartDataEntry, xIndex: \(xIndex), xvalue \(xvalue), yvalue \(yvalue)"
    }
    
    // MARK: NSCopying
    
    public override func copyWithZone(zone: NSZone) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! XYChartDataEntry
        copy.xvalue = xvalue
        copy.yvalue = yvalue
        return copy
    }
}

public func ==(lhs: XYChartDataEntry, rhs: XYChartDataEntry) -> Bool
{
    if (lhs === rhs)
    {
        return true
    }
    
    if (!lhs.isKindOfClass(rhs.dynamicType))
    {
        return false
    }
    
    if (lhs.data !== rhs.data && !lhs.data!.isEqual(rhs.data))
    {
        return false
    }
    
    if (lhs.xIndex != rhs.xIndex)
    {
        return false
    }
    
    if (fabs(lhs.xvalue - rhs.xvalue) > 0.00001)
    {
        return false
    }
    
    if (fabs(lhs.yvalue - rhs.yvalue) > 0.00001)
    {
        return false
    }
    
    return true
}