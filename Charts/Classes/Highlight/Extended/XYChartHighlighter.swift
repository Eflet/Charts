//
//  XYChartHighlighter.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/25.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

public class XYChartHighlighter : ChartHighlighter
{
    /// instance of the data-provider
    public weak var xychart: XYChartViewBase?
    
    public init(xychart: XYChartViewBase)
    {
        super.init()
        self.xychart = xychart
    }
    
    /// Returns a Highlight object corresponding to the given x- and y- touch positions in pixels.
    /// - parameter x:
    /// - parameter y:
    /// - returns:
    public override func getHighlight(x x: Double, y: Double) -> ChartHighlight?
    {
        guard let data = self.xychart?.data as? XYChartData else { return nil }
        var value = CGPoint(x: x, y: y)
        self.xychart?.getTransformer().pixelToValue(&value )
        let e = data.entryForValue(Double(value.x), yvalue: Double(value.y))
        if(e == nil)
        {
            return nil
        }
        let set = data.getDataSetForEntry(e)
        if(set == nil)
        {
            return nil
        }
        let dataSetIndex = data.indexOfDataSet(set!)
        return ChartHighlight(xIndex: e!.xIndex , dataSetIndex: dataSetIndex)
    }
}
