//
//  XYZoomChartViewJob.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/28.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

public class XYZoomChartViewJob: XYChartViewPortJob
{
    internal var scaleX: CGFloat = 0.0
    internal var scaleY: CGFloat = 0.0
    
    public init(
        viewPortHandler: ChartViewPortHandler,
        scaleX: CGFloat,
        scaleY: CGFloat,
        xValue: Double,
        yValue: Double,
        transformer: ChartTransformer,
        view: XYChartViewBase)
    {
        super.init(
            viewPortHandler: viewPortHandler,
            xValue: xValue,
            yValue: yValue,
            transformer: transformer,
            view: view)
        
        self.scaleX = scaleX
        self.scaleY = scaleY
    }
    
    public override func doJob()
    {
        guard let
            viewPortHandler = viewPortHandler,
            transformer = transformer,
            view = view
            else { return }
        
        var matrix = viewPortHandler.setZoom(scaleX: scaleX, scaleY: scaleY)
        viewPortHandler.refresh(newMatrix: matrix, chart: view, invalidate: false)
        
        let ysInView = (view as! XYChartViewBase).getDeltaY() / viewPortHandler.scaleY
        let xsInView = (view as! XYChartViewBase).getDeltaX() / viewPortHandler.scaleX
        
        var pt = CGPoint(
            x: CGFloat(xValue) + xsInView / 2.0,
            y: CGFloat(yValue) + ysInView / 2.0
        )
        
        transformer.pointValueToPixel(&pt)
        
        matrix = viewPortHandler.translate(pt: pt)
        viewPortHandler.refresh(newMatrix: matrix, chart: view, invalidate: false)
        
        (view as! XYChartViewBase).calculateOffsets()
        view.setNeedsDisplay()
    }
}