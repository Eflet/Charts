//
//  XYBubbleChartDataEntity.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/20.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation

public class XYBubbleChartDataEntity: XYChartDataEntry
{
    /// The size of the bubble.
    public var size = CGFloat(0.0)
    
    public required init()
    {
        super.init()
    }
    
    /// - parameter x: The value on the x-axis.
    /// - parameter y: The value on the y-axis.
    /// - parameter size: The size of the bubble.
    /// - parameter xIndex: The index on the x-axis.
    public init(x: Double, y: Double, size: CGFloat, xIndex: Int)
    {
        super.init(x: x, y: y, xIndex: xIndex)
        self.size = size
    }
    
    /// - parameter x: The value on the x-axis.
    /// - parameter y: The value on the y-axis.
    /// - parameter size: The size of the bubble.
    /// - parameter xIndex: The index on the x-axis.
    /// - parameter data: Spot for additional data this Entry represents.
    public init(x: Double, y: Double, size: CGFloat, xIndex: Int, data: AnyObject?)
    {
        super.init(x: x, y: y, xIndex: xIndex, data: data)
        self.size = size
    }
    
    public override var description: String
        {
            return "XYBubbleChartDataEntity, xIndex: \(xIndex), xvalue \(xvalue), yvalue \(yvalue), size \(size)"
    }
    
    // MARK: NSCopying
    
    public override func copyWithZone(zone: NSZone) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! XYBubbleChartDataEntity
        copy.size = size
        return copy
    }
}