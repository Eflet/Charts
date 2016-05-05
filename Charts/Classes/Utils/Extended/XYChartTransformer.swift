//
//  XYChartTransformer.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/27.
//  Copyright © 2016年 dcg. All rights reserved.
//


import Foundation
import CoreGraphics

public class XYChartTransformer: ChartTransformer
{
    public override func prepareMatrixValuePx(chartXMin chartXMin: Double, deltaX: CGFloat, deltaY: CGFloat, chartYMin: Double)
    {
        var scaleX = (_viewPortHandler.contentWidth / deltaX)
        var scaleY = (_viewPortHandler.contentHeight / deltaY)
        
        if CGFloat.infinity == scaleX
        {
            scaleX = 0.0
        }
        if CGFloat.infinity == scaleY
        {
            scaleY = 0.0
        }
        
        // setup all matrices
        _matrixValueToPx = CGAffineTransformIdentity
        _matrixValueToPx = CGAffineTransformScale(_matrixValueToPx, scaleX, -scaleY)
        _matrixValueToPx = CGAffineTransformTranslate(_matrixValueToPx, CGFloat(-chartXMin), CGFloat(-chartYMin))
    }
    
    /// Prepares the matrix that contains all offsets.
    public override func prepareMatrixOffset(inverted: Bool)
    {
        if (!inverted)
        {
            _matrixOffset = CGAffineTransformMakeTranslation(_viewPortHandler.offsetLeft, _viewPortHandler.chartHeight - _viewPortHandler.offsetBottom)
        }
        else
        {
            _matrixOffset = CGAffineTransformMakeScale(1.0, -1.0)
            _matrixOffset = CGAffineTransformTranslate(_matrixOffset, _viewPortHandler.offsetLeft, -_viewPortHandler.offsetTop)
        }
    }
    
    /// Transforms the given value to the point value on the chart.
    public override func pointValueToPixel(inout point: CGPoint)
    {
        point = CGPointApplyAffineTransform(point, valueToPixelMatrix)
    }
    
    /// Transforms the given touch point (pixels) into a value on the chart.
    public override func pixelToValue(inout pixel: CGPoint)
    {
        pixel = CGPointApplyAffineTransform(pixel, pixelToValueMatrix)
    }
}