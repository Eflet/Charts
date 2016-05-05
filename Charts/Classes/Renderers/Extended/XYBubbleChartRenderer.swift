//
//  XYBubbleChartRenderBase.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/25.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif


public class XYBubbleChartRenderer: XYChartRendererBase
{
    public weak var dataProvider: XYBubbleChartDataProvider?
    
    public init(dataProvider: XYBubbleChartDataProvider?, animator: ChartAnimator?, viewPortHandler: ChartViewPortHandler)
    {
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        
        self.dataProvider = dataProvider
    }
    
    public override func drawData(context context: CGContext)
    {
        guard let dataProvider = dataProvider, bubbleData = dataProvider.bubbleData else { return }
        
        for set in bubbleData.dataSets as! [IXYBubbleChartDataSet]
        {
            if set.isVisible && set.entryCount > 0
            {
                drawDataSet(context: context, dataSet: set)
            }
        }
    }
    
    private func getShapeSize(entrySize entrySize: CGFloat, maxSize: CGFloat, minSize: CGFloat, reference: CGFloat) -> CGFloat
    {
        let delta = maxSize - minSize
        let extendSize:  CGFloat = delta * 1.5
        let sizeFactor: CGFloat = (maxSize == 0.0) ? 1.0 : abs((entrySize - minSize + extendSize) / (delta + extendSize))
        let shapeSize: CGFloat = reference * sizeFactor
        return shapeSize
    }
    
    private var _pointBuffer = CGPoint()
    private var _sizeBuffer = [CGPoint](count: 2, repeatedValue: CGPoint())
    
    public func drawDataSet(context context: CGContext, dataSet: IXYBubbleChartDataSet)
    {
        guard let
            dataProvider = dataProvider,
            bubbleData = dataProvider.bubbleData,
            animator = animator
            else { return }
        
        let trans = dataProvider.getTransformer()
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        let entryCount = dataSet.entryCount
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        CGContextSaveGState(context)
        
        // calcualte the full width of 1 step on the x-axis
        let maxBubbleWidth: CGFloat = abs(viewPortHandler.contentRight - viewPortHandler.contentLeft)
        let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
        let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
        
        for (var j = 0; j < entryCount; j++)
        {
            guard let entry = dataSet.entryForIndex(j) as? XYBubbleChartDataEntity else { continue }
            
            _pointBuffer.x = CGFloat(entry.xvalue) * phaseX
            _pointBuffer.y = CGFloat(entry.yvalue) * phaseY
            _pointBuffer = CGPointApplyAffineTransform(_pointBuffer, valueToPixelMatrix)
            let shapeSize = getShapeSize(entrySize: entry.size, maxSize: bubbleData.maxSize, minSize: bubbleData.minSize, reference: referenceSize * dataProvider.bubbleSizeFactor)
            let shapeHalf = shapeSize / 2.0

            if ((!viewPortHandler.isInBoundsX(_pointBuffer.x + shapeHalf) || !viewPortHandler.isInBoundsY(_pointBuffer.y + shapeHalf)))
            {
                continue
            }
            let rect = CGRect(
                x: _pointBuffer.x - shapeHalf,
                y: _pointBuffer.y - shapeHalf,
                width: shapeSize,
                height: shapeSize
            )
            
            if(dataSet.fill != nil)
            {
                CGContextAddEllipseInRect(context, rect)
                dataSet.fill!.fillPath(context: context, rect: rect)
            }
            else
            {
                let color = dataSet.colorAt(entry.xIndex)
                CGContextSetFillColorWithColor(context, color.CGColor)
                CGContextFillEllipseInRect(context, rect)
            }
        }
        
        CGContextRestoreGState(context)
    }
    
    public override func drawValues(context context: CGContext)
    {
        guard let
            dataProvider = dataProvider,
            bubbleData = dataProvider.bubbleData,
            animator = animator
            else { return }
        
        // if values are drawn
        if (passesCheck())
        {
            guard let dataSets = bubbleData.dataSets as? [IXYBubbleChartDataSet] else { return }
            
            let phaseX = animator.phaseX
            let phaseY = animator.phaseY
            
            var pt = CGPoint()
            
            for dataSet in dataSets
            {
                if !dataSet.isDrawValuesEnabled || dataSet.entryCount == 0
                {
                    continue
                }
                
                let alpha = phaseX == 1 ? phaseY : phaseX
                
                guard let formatter = (dataSet as! XYBubbleChartDataSet).sizeValueFormatter else { continue }
                
                let trans = dataProvider.getTransformer()
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                let entryCount = dataSet.entryCount
                
                for (var j = 0; j < entryCount; j++)
                {
                    guard let e = dataSet.entryForIndex(j) as? XYBubbleChartDataEntity else { break }
                    
                    let valueTextColor = dataSet.valueTextColorAt(j).colorWithAlphaComponent(alpha)
                    
                    pt.x = CGFloat(e.xvalue) * phaseX
                    pt.y = CGFloat(e.yvalue) * phaseY
                    pt = CGPointApplyAffineTransform(pt, valueToPixelMatrix)
                    
                    if ((!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y)))
                    {
                        continue
                    }
                    
                    let text = formatter.stringFromNumber(e.size)
                    
                    // Larger font for larger bubbles?
                    let valueFont = dataSet.valueFont
                    let lineHeight = valueFont.lineHeight
                    
                    ChartUtils.drawText(
                        context: context,
                        text: text!,
                        point: CGPoint(
                            x: pt.x,
                            y: pt.y - (0.5 * lineHeight)),
                        align: .Center,
                        attributes: [NSFontAttributeName: valueFont, NSForegroundColorAttributeName: valueTextColor])
                }
            }
        }
    }
    
    public override func drawExtras(context context: CGContext)
    {
        
    }
    
    public override func drawHighlighted(context context: CGContext, indices: [ChartHighlight])
    {
        guard let
            dataProvider = dataProvider,
            bubbleData = dataProvider.bubbleData,
            animator = animator
            else { return }
        
        CGContextSaveGState(context)
        
        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        
        for indice in indices
        {
            guard let dataSet = bubbleData.getDataSetByIndex(indice.dataSetIndex) as? IXYBubbleChartDataSet else { continue }
            
            if (!dataSet.isHighlightEnabled)
            {
                continue
            }

            let entry: XYBubbleChartDataEntity! = bubbleData.getEntryForHighlight(indice) as! XYBubbleChartDataEntity
            if (entry === nil || entry.xIndex != indice.xIndex)
            {
                continue
            }
            
            let trans = dataProvider.getTransformer()
            
            let maxBubbleWidth: CGFloat = abs(viewPortHandler.contentRight - viewPortHandler.contentLeft)
            let maxBubbleHeight: CGFloat = abs(viewPortHandler.contentBottom - viewPortHandler.contentTop)
            let referenceSize: CGFloat = min(maxBubbleHeight, maxBubbleWidth)
            
            _pointBuffer.x = CGFloat(entry.xvalue) * phaseX
            _pointBuffer.y = CGFloat(entry.yvalue) * phaseY
            trans.pointValueToPixel(&_pointBuffer)
            
            let shapeSize = getShapeSize(entrySize: entry.size, maxSize: bubbleData.maxSize, minSize: bubbleData.minSize, reference: referenceSize * dataProvider.bubbleSizeFactor)
            let shapeHalf = shapeSize / 2.0
            
            if ((!viewPortHandler.isInBoundsX(_pointBuffer.x + shapeHalf) || !viewPortHandler.isInBoundsY(_pointBuffer.y + shapeHalf)))
            {
                continue
            }
            
            drawHighlightLines(context: context, point: _pointBuffer, set: dataSet)
            
            let originalColor = dataSet.colorAt(entry.xIndex)
            
            var h: CGFloat = 0.0
            var s: CGFloat = 0.0
            var b: CGFloat = 0.0
            var a: CGFloat = 0.0
            
            originalColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            
            let color = NSUIColor(hue: h, saturation: s, brightness: b * 0.5, alpha: a)
            let rect = CGRect(
                x: _pointBuffer.x - shapeHalf,
                y: _pointBuffer.y - shapeHalf,
                width: shapeSize,
                height: shapeSize)
            
            CGContextSetLineWidth(context, dataSet.highlightCircleWidth)
            CGContextSetStrokeColorWithColor(context, color.CGColor)
            CGContextStrokeEllipseInRect(context, rect)
        }
        
        CGContextRestoreGState(context)
    }
    
    internal func passesCheck() -> Bool
    {
        guard let dataProvider = dataProvider, bubbleData = dataProvider.bubbleData else { return false }
        let yCheck = CGFloat(bubbleData.yValCount) < CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleY
        let xCheck = CGFloat(bubbleData.xValCount) < CGFloat(dataProvider.maxVisibleValueCount) * viewPortHandler.scaleX
        return yCheck && xCheck
    }
}