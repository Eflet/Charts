//
//  XYAnimatedZoomViewJob.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/28.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

public class XYAnimatedZoomChartViewJob: XYAnimatedViewPortJob
{
    internal var xAxis: ChartYAxis?
    internal var yAxis: ChartYAxis?
    internal var scaleX: CGFloat = 0.0
    internal var scaleY: CGFloat = 0.0
    internal var zoomOriginX: CGFloat = 0.0
    internal var zoomOriginY: CGFloat = 0.0
    internal var zoomCenterX: CGFloat = 0.0
    internal var zoomCenterY: CGFloat = 0.0
    
    public init(
        viewPortHandler: ChartViewPortHandler,
        transformer: ChartTransformer,
        view: XYChartViewBase,
        yAxis: ChartYAxis,
        xAxis: ChartYAxis,
        scaleX: CGFloat,
        scaleY: CGFloat,
        xOrigin: CGFloat,
        yOrigin: CGFloat,
        zoomCenterX: CGFloat,
        zoomCenterY: CGFloat,
        zoomOriginX: CGFloat,
        zoomOriginY: CGFloat,
        duration: NSTimeInterval,
        easing: ChartEasingFunctionBlock?)
    {
        super.init(viewPortHandler: viewPortHandler,
            xValue: 0.0,
            yValue: 0.0,
            transformer: transformer,
            view: view,
            xOrigin: xOrigin,
            yOrigin: yOrigin,
            duration: duration,
            easing: easing)
        
        self.yAxis = yAxis
        self.xAxis = xAxis
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.zoomCenterX = zoomCenterX
        self.zoomCenterY = zoomCenterY
        self.zoomOriginX = zoomOriginX
        self.zoomOriginY = zoomOriginY
    }
    
    internal override func animationUpdate()
    {
        guard let
            viewPortHandler = viewPortHandler,
            transformer = transformer,
            view = view
            else { return }
        
        let scaleX = xOrigin + (self.scaleX - xOrigin) * phase
        let scaleY = yOrigin + (self.scaleY - yOrigin) * phase
        
        var matrix = viewPortHandler.setZoom(scaleX: scaleX, scaleY: scaleY)
        viewPortHandler.refresh(newMatrix: matrix, chart: view, invalidate: false)
        
        let yvalsInView = CGFloat(yAxis?.axisRange ?? 0.0) / viewPortHandler.scaleY
        let xvalsInView = CGFloat(xAxis?.axisRange ?? 0.0) / viewPortHandler.scaleX
        
        var pt = CGPoint(
            x: zoomOriginX + ((zoomCenterX + xvalsInView / 2.0) - zoomOriginX) * phase,
            y: zoomOriginY + ((zoomCenterY + yvalsInView / 2.0) - zoomOriginY) * phase
        )
        
        transformer.pointValueToPixel(&pt)
        
        matrix = viewPortHandler.translate(pt: pt)
        viewPortHandler.refresh(newMatrix: matrix, chart: view, invalidate: true)
    }
    
    internal override func animationEnd()
    {
        (view as? XYChartViewBase)?.calculateOffsets()
        view?.setNeedsDisplay()
    }
}
