//
//  XYChartViewBase.swift
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

/// Base-class of LineChart, BarChart, ScatterChart and CandleStickChart.
public class XYChartViewBase: ChartViewBase, XYChartDataProvider, NSUIGestureRecognizerDelegate
{
    /// the maximum number of entries to which values will be drawn
    /// (entry numbers greater than this value will cause value-labels to disappear)
    internal var _maxVisibleValueCount = 100
    
    /// flag that indicates if auto scaling on the y axis is enabled
    private var _autoScaleMinMaxEnabled = false
    private var _autoScaleLastMinX: Double?
    private var _autoScaleLastMaxX: Double?
    private var _autoScaleLastMinY: Double?
    private var _autoScaleLastMaxY: Double?
    
    private var _pinchZoomEnabled = false
    private var _doubleTapToZoomEnabled = true
    private var _dragEnabled = true
    
    private var _scaleXEnabled = true
    private var _scaleYEnabled = true
    
    /// the color for the background of the chart-drawing area (everything behind the grid lines).
    public var gridBackgroundColor = NSUIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
    
    public var borderColor = NSUIColor.blackColor()
    public var borderLineWidth: CGFloat = 1.0
    
    /// flag indicating if the grid background should be drawn or not
    public var drawGridBackgroundEnabled = false
    
    /// Sets drawing the borders rectangle to true. If this is enabled, there is no point drawing the axis-lines of x- and y-axis.
    public var drawBordersEnabled = false
    
    /// Sets the minimum offset (padding) around the chart, defaults to 10
    public var minOffset = CGFloat(10.0)
    
    /// The transformer for the chart
    internal var _valueTransformer: ChartTransformer!
    
    /// the object representing the x-axis/y-axis
    internal var _yAxis: ChartYAxis!
    internal var _xAxis: ChartYAxis!
    
    internal var _yAxisRenderer: ChartYAxisRenderer!
    internal var _xAxisRenderer: ChartYAxisRenderer!
    
    internal var _yAxisTransformer: ChartTransformer!
    internal var _xAxisTransformer: ChartTransformer!
    
    internal var _tapGestureRecognizer: NSUITapGestureRecognizer!
    internal var _doubleTapGestureRecognizer: NSUITapGestureRecognizer!
    #if !os(tvOS)
    internal var _pinchGestureRecognizer: NSUIPinchGestureRecognizer!
    #endif
    internal var _panGestureRecognizer: NSUIPanGestureRecognizer!
    
    /// flag that indicates if a custom viewport offset has been set
    private var _customViewPortEnabled = false
    
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    deinit
    {
        stopDeceleration()
    }
    
    internal override func initialize()
    {
        super.initialize()
        
        _yAxis = ChartYAxis()
        _xAxis = ChartYAxis(position: .Right)
        
        _valueTransformer = XYChartTransformer(viewPortHandler: _viewPortHandler)
        _yAxisTransformer = ChartTransformer(viewPortHandler: _viewPortHandler)
        _xAxisTransformer = ChartTransformer(viewPortHandler: _viewPortHandler)
        
        _yAxisRenderer = ChartYAxisRenderer(viewPortHandler: _viewPortHandler, yAxis: _yAxis, transformer: _yAxisTransformer)
        _xAxisRenderer = ChartYAxisRendererXYChart(viewPortHandler: _viewPortHandler, yAxis: _xAxis, transformer: _xAxisTransformer)
        
        self.highlighter = XYChartHighlighter(xychart: self)
        
        _tapGestureRecognizer = NSUITapGestureRecognizer(target: self, action: Selector("tapGestureRecognized:"))
        _doubleTapGestureRecognizer = NSUITapGestureRecognizer(target: self, action: Selector("doubleTapGestureRecognized:"))
        _doubleTapGestureRecognizer.nsuiNumberOfTapsRequired = 2
        _panGestureRecognizer = NSUIPanGestureRecognizer(target: self, action: Selector("panGestureRecognized:"))
        
        _panGestureRecognizer.delegate = self
        
        self.addGestureRecognizer(_tapGestureRecognizer)
        self.addGestureRecognizer(_doubleTapGestureRecognizer)
        self.addGestureRecognizer(_panGestureRecognizer)
        
        _doubleTapGestureRecognizer.enabled = _doubleTapToZoomEnabled
        _panGestureRecognizer.enabled = _dragEnabled
        
        #if !os(tvOS)
            _pinchGestureRecognizer = NSUIPinchGestureRecognizer(target: self, action: Selector("pinchGestureRecognized:"))
            _pinchGestureRecognizer.delegate = self
            self.addGestureRecognizer(_pinchGestureRecognizer)
            _pinchGestureRecognizer.enabled = _pinchZoomEnabled || _scaleXEnabled || _scaleYEnabled
        #endif
    }
    
    public override func drawRect(rect: CGRect)
    {
        super.drawRect(rect)
        
        if _data === nil
        {
            return
        }
        
        let optionalContext = NSUIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }
        
        // execute all drawing commands
        drawGridBackground(context: context)
        
        if (_yAxis.isEnabled)
        {
            _yAxisRenderer?.computeAxis(yMin: _yAxis.axisMinimum, yMax: _yAxis.axisMaximum)
        }
        if (_xAxis.isEnabled)
        {
            _xAxisRenderer?.computeAxis(yMin: _xAxis.axisMinimum, yMax: _xAxis.axisMaximum)
        }
        
        _xAxisRenderer?.renderAxisLine(context: context)
        _yAxisRenderer?.renderAxisLine(context: context)
        
        if (_autoScaleMinMaxEnabled)
        {
            let lowestX = self.lowestX,
            highestX = self.highestX,
            lowestY = self.lowestY,
            highestY = self.highestY
            
            if (_autoScaleLastMinX == nil || _autoScaleLastMinX != lowestX ||
                _autoScaleLastMaxX == nil || _autoScaleLastMaxX != highestX ||
                _autoScaleLastMinY == nil || _autoScaleLastMinY != lowestY ||
                _autoScaleLastMaxY == nil || _autoScaleLastMaxY != highestY)
            {
                calcMinMax()
                calculateOffsets()
                
                _autoScaleLastMinX = lowestX
                _autoScaleLastMaxX = highestX
                _autoScaleLastMinY = lowestY
                _autoScaleLastMaxY = highestY
            }
        }
        
        // make sure the graph values and grid cannot be drawn outside the content-rect
        CGContextSaveGState(context)
        
        CGContextClipToRect(context, _viewPortHandler.contentRect)
        
        if (_xAxis.isDrawLimitLinesBehindDataEnabled)
        {
            _xAxisRenderer?.renderLimitLines(context: context)
        }
        if (_yAxis.isDrawLimitLinesBehindDataEnabled)
        {
            _yAxisRenderer?.renderLimitLines(context: context)
        }
        
        _xAxisRenderer?.renderGridLines(context: context)
        _yAxisRenderer?.renderGridLines(context: context)
        
        // if highlighting is enabled
        if (valuesToHighlight())
        {
            renderer?.drawHighlighted(context: context, indices: _indicesToHighlight)
        }
        
        renderer?.drawData(context: context)
        
        if (!_xAxis.isDrawLimitLinesBehindDataEnabled)
        {
            _xAxisRenderer?.renderLimitLines(context: context)
        }
        if (!_yAxis.isDrawLimitLinesBehindDataEnabled)
        {
            _yAxisRenderer?.renderLimitLines(context: context)
        }

        
        // Removes clipping rectangle
        CGContextRestoreGState(context)
        
        renderer!.drawExtras(context: context)
        
        _xAxisRenderer.renderAxisLabels(context: context)
        _yAxisRenderer.renderAxisLabels(context: context)
        
        renderer!.drawValues(context: context)
        
        _legendRenderer.renderLegend(context: context)
        
        drawMarkers(context: context)
        
        drawDescription(context: context)
    }
    
    internal func prepareValuePxMatrix()
    {
        _yAxisTransformer.prepareMatrixValuePx(chartXMin: _xAxis.axisMinimum, deltaX: getDeltaX(), deltaY: getDeltaY(), chartYMin: _yAxis.axisMinimum)
        _xAxisTransformer.prepareMatrixValuePx(chartXMin: _xAxis.axisMinimum, deltaX: getDeltaX(), deltaY: getDeltaY(), chartYMin: _yAxis.axisMinimum)
        _valueTransformer.prepareMatrixValuePx(chartXMin: _xAxis.axisMinimum, deltaX: getDeltaX(), deltaY: getDeltaY(), chartYMin: _yAxis.axisMinimum)
    }
    
    internal func prepareOffsetMatrix()
    {
        _yAxisTransformer.prepareMatrixOffset(_yAxis.isInverted)
        _xAxisTransformer.prepareMatrixOffset(_xAxis.isInverted)
        _valueTransformer.prepareMatrixOffset(isAnyAxisInverted)
    }
    
    public override func notifyDataSetChanged()
    {
        calcMinMax()
        
        _yAxis?._defaultValueFormatter = _defaultValueFormatter
        _xAxis?._defaultValueFormatter = _defaultValueFormatter
        
        _yAxisRenderer?.computeAxis(yMin: _yAxis.axisMinimum, yMax: _yAxis.axisMaximum)
        _xAxisRenderer?.computeAxis(yMin: _xAxis.axisMinimum, yMax: _xAxis.axisMaximum)
        
        if let data = _data
        {
            if (_legend !== nil)
            {
                _legendRenderer?.computeLegend(data)
            }
        }
        
        calculateOffsets()
        
        setNeedsDisplay()
    }
    
    internal override func calcMinMax()
    {
        let xyData = data as? XYChartData
        
        if (_autoScaleMinMaxEnabled)
        {
            xyData?.calcMinMax(startx: lowestX, endx: highestX, starty: lowestY, endy: highestY)
        }
        var minY = !isnan(_yAxis.customAxisMin)
            ? _yAxis.customAxisMin
            : xyData?.getYMin() ?? 0.0
        var maxY = !isnan(_yAxis.customAxisMax)
            ? _yAxis.customAxisMax
            : xyData?.getYMax() ?? 0.0
        var minX = !isnan(_xAxis.customAxisMin)
            ? _xAxis.customAxisMin
            : xyData?.getXMin() ?? 0.0
        var maxX = !isnan(_xAxis.customAxisMax)
            ? _xAxis.customAxisMax
            : xyData?.getXMax() ?? 0.0
        
        let yRange = abs(maxY - minY)
        let xRange = abs(maxX - minX)
        
        // in case all values are equal
        if (yRange == 0.0)
        {
            maxY = maxY + 1.0
            minY = minY - 1.0
        }
        
        if (xRange == 0.0)
        {
            maxX = maxX + 1.0
            minX = minY - 1.0
        }
        
        let yTopSpace = yRange * Double(_yAxis.spaceTop)
        let yBottomSpace = yRange * Double(_yAxis.spaceBottom)
        let xTopSpace = xRange * Double(_xAxis.spaceTop)
        let xBottomSpace = xRange * Double(_xAxis.spaceBottom)
        
        // Use the values as they are
        _yAxis.axisMinimum = !isnan(_yAxis.customAxisMin)
            ? _yAxis.customAxisMin
            : (minY - yBottomSpace)
        _yAxis.axisMaximum = !isnan(_yAxis.customAxisMax)
            ? _yAxis.customAxisMax
            : (maxY + yTopSpace)
        
        _xAxis.axisMinimum = !isnan(_xAxis.customAxisMin)
            ? _xAxis.customAxisMin
            : (minX - xBottomSpace)
        _xAxis.axisMaximum = !isnan(_xAxis.customAxisMax)
            ? _yAxis.customAxisMax
            : (maxX + xTopSpace)
        
        _yAxis.axisRange = abs(_yAxis.axisMaximum - _yAxis.axisMinimum)
        _xAxis.axisRange = abs(_xAxis.axisMaximum - _xAxis.axisMinimum)
    }
    
    internal override func calculateOffsets()
    {
        if (!_customViewPortEnabled)
        {
            var offsetLeft = CGFloat(0.0)
            var offsetRight = CGFloat(0.0)
            var offsetTop = CGFloat(0.0)
            var offsetBottom = CGFloat(0.0)
            
            // setup offsets for legend
            if (_legend !== nil && _legend.isEnabled)
            {
                if (_legend.position == .RightOfChart
                    || _legend.position == .RightOfChartCenter)
                {
                    offsetRight += min(_legend.neededWidth, _viewPortHandler.chartWidth * _legend.maxSizePercent) + _legend.xOffset * 2.0
                }
                if (_legend.position == .LeftOfChart
                    || _legend.position == .LeftOfChartCenter)
                {
                    offsetLeft += min(_legend.neededWidth, _viewPortHandler.chartWidth * _legend.maxSizePercent) + _legend.xOffset * 2.0
                }
                else if (_legend.position == .BelowChartLeft
                    || _legend.position == .BelowChartRight
                    || _legend.position == .BelowChartCenter)
                {
                    // It's possible that we do not need this offset anymore as it
                    //   is available through the extraOffsets, but changing it can mean
                    //   changing default visibility for existing apps.
                    let yOffset = _legend.textHeightMax
                    
                    offsetBottom += min(_legend.neededHeight + yOffset, _viewPortHandler.chartHeight * _legend.maxSizePercent)
                }
                else if (_legend.position == .AboveChartLeft
                    || _legend.position == .AboveChartRight
                    || _legend.position == .AboveChartCenter)
                {
                    // It's possible that we do not need this offset anymore as it
                    //   is available through the extraOffsets, but changing it can mean
                    //   changing default visibility for existing apps.
                    let yOffset = _legend.textHeightMax
                    
                    offsetTop += min(_legend.neededHeight + yOffset, _viewPortHandler.chartHeight * _legend.maxSizePercent)
                }
            }
            
            // offsets for y-labels
            if (_yAxis.needsOffset)
            {
                offsetLeft += _yAxis.requiredSize().width
            }
            // offsets for x-labels
            if (_xAxis.needsOffset)
            {
                offsetBottom += _xAxis.requiredSize().height
            }
            
            offsetTop += self.extraTopOffset
            offsetRight += self.extraRightOffset
            offsetBottom += self.extraBottomOffset
            offsetLeft += self.extraLeftOffset
            
            _viewPortHandler.restrainViewPort(
                offsetLeft: max(self.minOffset, offsetLeft),
                offsetTop: max(self.minOffset, offsetTop),
                offsetRight: max(self.minOffset, offsetRight),
                offsetBottom: max(self.minOffset, offsetBottom))
        }
        
        prepareOffsetMatrix()
        prepareValuePxMatrix()
    }
    
    public override func getMarkerPosition(entry e: ChartDataEntry, highlight: ChartHighlight) -> CGPoint
    {
        //guard let data = _data else { return CGPointZero }
        let ent = e as! XYChartDataEntry
        //let dataSetIndex = highlight.dataSetIndex
        let xPos = CGFloat(ent.xvalue)
        let yPos = CGFloat(ent.yvalue)
        
        // position of the marker depends on selected value index and value
        var pt = CGPoint(x: xPos * _animator.phaseY , y: yPos * _animator.phaseY)
        
        getTransformer().pointValueToPixel(&pt)
        
        return pt
    }
    
    /// draws the grid background
    internal func drawGridBackground(context context: CGContext)
    {
        if (drawGridBackgroundEnabled || drawBordersEnabled)
        {
            CGContextSaveGState(context)
        }
        
        if (drawGridBackgroundEnabled)
        {
            // draw the grid background
            CGContextSetFillColorWithColor(context, gridBackgroundColor.CGColor)
            CGContextFillRect(context, _viewPortHandler.contentRect)
        }
        
        if (drawBordersEnabled)
        {
            CGContextSetLineWidth(context, borderLineWidth)
            CGContextSetStrokeColorWithColor(context, borderColor.CGColor)
            CGContextStrokeRect(context, _viewPortHandler.contentRect)
        }
        
        if (drawGridBackgroundEnabled || drawBordersEnabled)
        {
            CGContextRestoreGState(context)
        }
    }
    
    // MARK: - Gestures
    
    private enum GestureScaleAxis
    {
        case Both
        case X
        case Y
    }
    
    private var _isDragging = false
    private var _isScaling = false
    private var _gestureScaleAxis = GestureScaleAxis.Both
    private var _closestDataSetToTouch: IChartDataSet!
    private var _panGestureReachedEdge: Bool = false
    private weak var _outerScrollView: NSUIScrollView?
    
    private var _lastPanPoint = CGPoint() /// This is to prevent using setTranslation which resets velocity
    
    private var _decelerationLastTime: NSTimeInterval = 0.0
    private var _decelerationDisplayLink: NSUIDisplayLink!
    private var _decelerationVelocity = CGPoint()
    
    @objc private func tapGestureRecognized(recognizer: NSUITapGestureRecognizer)
    {
        if _data === nil
        {
            return
        }
        
        if (recognizer.state == NSUIGestureRecognizerState.Ended)
        {
            if !self.isHighLightPerTapEnabled { return }
            
            let h = getHighlightByTouchPoint(recognizer.locationInView(self))
            
            if (h === nil || h!.isEqual(self.lastHighlighted))
            {
                self.highlightValue(highlight: nil, callDelegate: true)
                self.lastHighlighted = nil
            }
            else
            {
                self.lastHighlighted = h
                self.highlightValue(highlight: h, callDelegate: true)
            }
        }
    }
    
    @objc private func doubleTapGestureRecognized(recognizer: NSUITapGestureRecognizer)
    {
        if _data === nil
        {
            return
        }
        
        if (recognizer.state == NSUIGestureRecognizerState.Ended)
        {
            if _data !== nil && _doubleTapToZoomEnabled
            {
                var location = recognizer.locationInView(self)
                location.x = location.x - _viewPortHandler.offsetLeft
                
                if (isAnyAxisInverted && _closestDataSetToTouch !== nil && _yAxis.isInverted)
                {
                    location.y = -(location.y - _viewPortHandler.offsetTop)
                }
                else
                {
                    location.y = -(self.bounds.size.height - location.y - _viewPortHandler.offsetBottom)
                }
                
                self.zoom(isScaleXEnabled ? 1.4 : 1.0, scaleY: isScaleYEnabled ? 1.4 : 1.0, x: location.x, y: location.y)
            }
        }
    }
    
    #if !os(tvOS)
    @objc private func pinchGestureRecognized(recognizer: NSUIPinchGestureRecognizer)
    {
        if (recognizer.state == NSUIGestureRecognizerState.Began)
        {
            stopDeceleration()
            
            if _data !== nil && (_pinchZoomEnabled || _scaleXEnabled || _scaleYEnabled)
            {
                _isScaling = true
                
                if (_pinchZoomEnabled)
                {
                    _gestureScaleAxis = .Both
                }
                else
                {
                    let x = abs(recognizer.locationInView(self).x - recognizer.nsuiLocationOfTouch(1, inView: self).x)
                    let y = abs(recognizer.locationInView(self).y - recognizer.nsuiLocationOfTouch(1, inView: self).y)
                    
                    if (x > y)
                    {
                        _gestureScaleAxis = .X
                    }
                    else
                    {
                        _gestureScaleAxis = .Y
                    }
                }
            }
        }
        else if (recognizer.state == NSUIGestureRecognizerState.Ended ||
            recognizer.state == NSUIGestureRecognizerState.Cancelled)
        {
            if (_isScaling)
            {
                _isScaling = false
                
                // Range might have changed, which means that Y-axis labels could have changed in size, affecting Y-axis size. So we need to recalculate offsets.
                calculateOffsets()
                setNeedsDisplay()
            }
        }
        else if (recognizer.state == NSUIGestureRecognizerState.Changed)
        {
            let isZoomingOut = (recognizer.nsuiScale < 1)
            var canZoomMoreX = isZoomingOut ? _viewPortHandler.canZoomOutMoreX : _viewPortHandler.canZoomInMoreX
            var canZoomMoreY = isZoomingOut ? _viewPortHandler.canZoomOutMoreY : _viewPortHandler.canZoomInMoreY
            
            if (_isScaling)
            {
                canZoomMoreX = canZoomMoreX && _scaleXEnabled && (_gestureScaleAxis == .Both || _gestureScaleAxis == .X);
                canZoomMoreY = canZoomMoreY && _scaleYEnabled && (_gestureScaleAxis == .Both || _gestureScaleAxis == .Y);
                if canZoomMoreX || canZoomMoreY
                {
                    var location = recognizer.locationInView(self)
                    location.x = location.x - _viewPortHandler.offsetLeft
                    
                    if (isAnyAxisInverted && _closestDataSetToTouch !== nil && _yAxis.isInverted)
                    {
                        location.y = -(location.y - _viewPortHandler.offsetTop)
                    }
                    else
                    {
                        location.y = -(_viewPortHandler.chartHeight - location.y - _viewPortHandler.offsetBottom)
                    }
                    
                    let scaleX = canZoomMoreX ? recognizer.nsuiScale : 1.0
                    let scaleY = canZoomMoreY ? recognizer.nsuiScale : 1.0
                    
                    var matrix = CGAffineTransformMakeTranslation(location.x, location.y)
                    matrix = CGAffineTransformScale(matrix, scaleX, scaleY)
                    matrix = CGAffineTransformTranslate(matrix,
                        -location.x, -location.y)
                    
                    matrix = CGAffineTransformConcat(_viewPortHandler.touchMatrix, matrix)
                    
                    _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: true)
                    
                    if (delegate !== nil)
                    {
                        delegate?.chartScaled?(self, scaleX: scaleX, scaleY: scaleY)
                    }
                }
                
                recognizer.nsuiScale = 1.0
            }
        }
    }
    #endif
    
    @objc private func panGestureRecognized(recognizer: NSUIPanGestureRecognizer)
    {
        if (recognizer.state == NSUIGestureRecognizerState.Began && recognizer.nsuiNumberOfTouches() > 0)
        {
            stopDeceleration()
            
            if _data === nil
            { // If we have no data, we have nothing to pan and no data to highlight
                return;
            }
            
            // If drag is enabled and we are in a position where there's something to drag:
            //  * If we're zoomed in, then obviously we have something to drag.
            //  * If we have a drag offset - we always have something to drag
            if self.isDragEnabled &&
                (!self.hasNoDragOffset || !self.isFullyZoomedOut)
            {
                _isDragging = true
                
                _closestDataSetToTouch = getDataSetByTouchPoint(recognizer.nsuiLocationOfTouch(0, inView: self))
                
                let translation = recognizer.translationInView(self)
                let didUserDrag = translation.y != 0.0 || translation.x != 0.0
                
                // Check to see if user dragged at all and if so, can the chart be dragged by the given amount
                if (didUserDrag && !performPanChange(translation: translation))
                {
                    if (_outerScrollView !== nil)
                    {
                        // We can stop dragging right now, and let the scroll view take control
                        _outerScrollView = nil
                        _isDragging = false
                    }
                }
                else
                {
                    if (_outerScrollView !== nil)
                    {
                        // Prevent the parent scroll view from scrolling
                        _outerScrollView?.scrollEnabled = false
                    }
                }
                
                _lastPanPoint = recognizer.translationInView(self)
            }
            else if self.isHighlightPerDragEnabled
            {
                // We will only handle highlights on NSUIGestureRecognizerState.Changed
                
                _isDragging = false
            }
        }
        else if (recognizer.state == NSUIGestureRecognizerState.Changed)
        {
            if (_isDragging)
            {
                let originalTranslation = recognizer.translationInView(self)
                let translation = CGPoint(x: originalTranslation.x - _lastPanPoint.x, y: originalTranslation.y - _lastPanPoint.y)
                
                performPanChange(translation: translation)
                
                _lastPanPoint = originalTranslation
            }
            else if (isHighlightPerDragEnabled)
            {
                let h = getHighlightByTouchPoint(recognizer.locationInView(self))
                
                let lastHighlighted = self.lastHighlighted
                
                if ((h === nil && lastHighlighted !== nil) ||
                    (h !== nil && lastHighlighted === nil) ||
                    (h !== nil && lastHighlighted !== nil && !h!.isEqual(lastHighlighted)))
                {
                    self.lastHighlighted = h
                    self.highlightValue(highlight: h, callDelegate: true)
                }
            }
        }
        else if (recognizer.state == NSUIGestureRecognizerState.Ended || recognizer.state == NSUIGestureRecognizerState.Cancelled)
        {
            if (_isDragging)
            {
                if (recognizer.state == NSUIGestureRecognizerState.Ended && isDragDecelerationEnabled)
                {
                    stopDeceleration()
                    
                    _decelerationLastTime = CACurrentMediaTime()
                    _decelerationVelocity = recognizer.velocityInView(self)
                    
                    _decelerationDisplayLink = NSUIDisplayLink(target: self, selector: Selector("decelerationLoop"))
                    _decelerationDisplayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
                }
                
                _isDragging = false
            }
            
            if (_outerScrollView !== nil)
            {
                _outerScrollView?.scrollEnabled = true
                _outerScrollView = nil
            }
        }
    }
    
    private func performPanChange(var translation translation: CGPoint) -> Bool
    {
        if (isAnyAxisInverted && _closestDataSetToTouch !== nil
            && _yAxis.isInverted)
        {
            translation.x = -translation.x
            translation.y = -translation.y
        }
        
        let originalMatrix = _viewPortHandler.touchMatrix
        
        var matrix = CGAffineTransformMakeTranslation(translation.x, translation.y)
        matrix = CGAffineTransformConcat(originalMatrix, matrix)
        
        matrix = _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: true)
        
        if (delegate !== nil)
        {
            delegate?.chartTranslated?(self, dX: translation.x, dY: translation.y)
        }
        
        // Did we managed to actually drag or did we reach the edge?
        return matrix.tx != originalMatrix.tx || matrix.ty != originalMatrix.ty
    }
    
    public func stopDeceleration()
    {
        if (_decelerationDisplayLink !== nil)
        {
            _decelerationDisplayLink.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
            _decelerationDisplayLink = nil
        }
    }
    
    @objc private func decelerationLoop()
    {
        let currentTime = CACurrentMediaTime()
        
        _decelerationVelocity.x *= self.dragDecelerationFrictionCoef
        _decelerationVelocity.y *= self.dragDecelerationFrictionCoef
        
        let timeInterval = CGFloat(currentTime - _decelerationLastTime)
        
        let distance = CGPoint(
            x: _decelerationVelocity.x * timeInterval,
            y: _decelerationVelocity.y * timeInterval
        )
        
        if (!performPanChange(translation: distance))
        {
            // We reached the edge, stop
            _decelerationVelocity.x = 0.0
            _decelerationVelocity.y = 0.0
        }
        
        _decelerationLastTime = currentTime
        
        if (abs(_decelerationVelocity.x) < 0.001 && abs(_decelerationVelocity.y) < 0.001)
        {
            stopDeceleration()
            
            // Range might have changed, which means that Y-axis labels could have changed in size, affecting Y-axis size. So we need to recalculate offsets.
            calculateOffsets()
            setNeedsDisplay()
        }
    }
    
    private func nsuiGestureRecognizerShouldBegin(gestureRecognizer: NSUIGestureRecognizer) -> Bool
    {
        if (gestureRecognizer == _panGestureRecognizer)
        {
            if _data === nil || !_dragEnabled ||
                (self.hasNoDragOffset && self.isFullyZoomedOut && !self.isHighlightPerDragEnabled)
            {
                return false
            }
        }
        else
        {
            #if !os(tvOS)
                if (gestureRecognizer == _pinchGestureRecognizer)
                {
                    if _data === nil || (!_pinchZoomEnabled && !_scaleXEnabled && !_scaleYEnabled)
                    {
                        return false
                    }
                }
            #endif
        }
        
        return true
    }
    
    #if !os(OSX)
    public override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if (!super.gestureRecognizerShouldBegin(gestureRecognizer))
        {
            return false
        }
        
        return nsuiGestureRecognizerShouldBegin(gestureRecognizer)
    }
    #endif
    
    #if os(OSX)
    public func gestureRecognizerShouldBegin(gestureRecognizer: NSGestureRecognizer) -> Bool
    {
    return nsuiGestureRecognizerShouldBegin(gestureRecognizer)
    }
    #endif
    
    public func gestureRecognizer(gestureRecognizer: NSUIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: NSUIGestureRecognizer) -> Bool
    {
        #if !os(tvOS)
            if ((gestureRecognizer.isKindOfClass(NSUIPinchGestureRecognizer) &&
                otherGestureRecognizer.isKindOfClass(NSUIPanGestureRecognizer)) ||
                (gestureRecognizer.isKindOfClass(NSUIPanGestureRecognizer) &&
                    otherGestureRecognizer.isKindOfClass(NSUIPinchGestureRecognizer)))
            {
                return true
            }
        #endif
        
        if (gestureRecognizer.isKindOfClass(NSUIPanGestureRecognizer) &&
            otherGestureRecognizer.isKindOfClass(NSUIPanGestureRecognizer) && (
                gestureRecognizer == _panGestureRecognizer
            ))
        {
            var scrollView = self.superview
            while (scrollView !== nil && !scrollView!.isKindOfClass(NSUIScrollView))
            {
                scrollView = scrollView?.superview
            }
            
            // If there is two scrollview together, we pick the superview of the inner scrollview.
            // In the case of UITableViewWrepperView, the superview will be UITableView
            if let superViewOfScrollView = scrollView?.superview where superViewOfScrollView.isKindOfClass(NSUIScrollView)
            {
                scrollView = superViewOfScrollView
            }
            
            var foundScrollView = scrollView as? NSUIScrollView
            
            if (foundScrollView !== nil && !foundScrollView!.scrollEnabled)
            {
                foundScrollView = nil
            }
            
            var scrollViewPanGestureRecognizer: NSUIGestureRecognizer!
            
            if (foundScrollView !== nil)
            {
                for scrollRecognizer in foundScrollView!.nsuiGestureRecognizers!
                {
                    if (scrollRecognizer.isKindOfClass(NSUIPanGestureRecognizer))
                    {
                        scrollViewPanGestureRecognizer = scrollRecognizer as! NSUIPanGestureRecognizer
                        break
                    }
                }
            }
            
            if (otherGestureRecognizer === scrollViewPanGestureRecognizer)
            {
                _outerScrollView = foundScrollView
                
                return true
            }
        }
        
        return false
    }
    
    /// MARK: Viewport modifiers
    
    /// Zooms in by 1.4, into the charts center. center.
    public func zoomIn()
    {
        let center = _viewPortHandler.contentCenter
        
        let matrix = _viewPortHandler.zoomIn(x: center.x, y: -center.y)
        _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: false)
        
        // Range might have changed, which means that Y-axis labels could have changed in size, affecting Y-axis size. So we need to recalculate offsets.
        calculateOffsets()
        setNeedsDisplay()
    }
    
    /// Zooms out by 0.7, from the charts center. center.
    public func zoomOut()
    {
        let center = _viewPortHandler.contentCenter
        
        let matrix = _viewPortHandler.zoomOut(x: center.x, y: -center.y)
        _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: false)
        
        // Range might have changed, which means that Y-axis labels could have changed in size, affecting Y-axis size. So we need to recalculate offsets.
        calculateOffsets()
        setNeedsDisplay()
    }
    
    /// Zooms in or out by the given scale factor. x and y are the coordinates
    /// (in pixels) of the zoom center.
    ///
    /// - parameter scaleX: if < 1 --> zoom out, if > 1 --> zoom in
    /// - parameter scaleY: if < 1 --> zoom out, if > 1 --> zoom in
    /// - parameter x:
    /// - parameter y:
    public func zoom(scaleX: CGFloat, scaleY: CGFloat, x: CGFloat, y: CGFloat)
    {
        let matrix = _viewPortHandler.zoom(scaleX: scaleX, scaleY: scaleY, x: -x, y: -y)
        _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: false)
        
        // Range might have changed, which means that Y-axis labels could have changed in size, affecting Y-axis size. So we need to recalculate offsets.
        calculateOffsets()
        setNeedsDisplay()
    }
    
    /// Zooms in or out by the given scale factor.
    /// x and y are the values (**not pixels**) which to zoom to or from (the values of the zoom center).
    ///
    /// - parameter scaleX: if < 1 --> zoom out, if > 1 --> zoom in
    /// - parameter scaleY: if < 1 --> zoom out, if > 1 --> zoom in
    /// - parameter xValue:
    /// - parameter yValue:
    public func zoom(
        scaleX: CGFloat,
        scaleY: CGFloat,
        xValue: Double,
        yValue: Double)
    {
        let job = XYZoomChartViewJob(viewPortHandler: viewPortHandler, scaleX: scaleX, scaleY: scaleY, xValue: xValue, yValue: yValue, transformer: getTransformer(), view: self)
        addViewportJob(job)
    }
    
    /// Zooms by the specified scale factor to the specified values on the specified axis.
    ///
    /// - parameter scaleX:
    /// - parameter scaleY:
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func zoomAndCenterViewAnimated(
        scaleX scaleX: CGFloat,
        scaleY: CGFloat,
        xValue: Double,
        yValue: Double,
        duration: NSTimeInterval,
        easing: ChartEasingFunctionBlock?)
    {
        let origin = getValueByTouchPoint(
            pt: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
        
        let job = XYAnimatedZoomChartViewJob(
            viewPortHandler: viewPortHandler,
            transformer: getTransformer(),
            view: self,
            yAxis: _yAxis,
            xAxis: _xAxis,
            scaleX: scaleX,
            scaleY: scaleY,
            xOrigin: viewPortHandler.scaleX,
            yOrigin: viewPortHandler.scaleY,
            zoomCenterX: CGFloat(xValue),
            zoomCenterY: CGFloat(yValue),
            zoomOriginX: origin.x,
            zoomOriginY: origin.y,
            duration: duration,
            easing: easing)
        
        addViewportJob(job)
    }
    
    /// Zooms by the specified scale factor to the specified values on the specified axis.
    ///
    /// - parameter scaleX:
    /// - parameter scaleY:
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func zoomAndCenterViewAnimated(
        scaleX scaleX: CGFloat,
        scaleY: CGFloat,
        xValue: Double,
        yValue: Double,
        duration: NSTimeInterval,
        easingOption: ChartEasingOption)
    {
        zoomAndCenterViewAnimated(scaleX: scaleX, scaleY: scaleY, xValue: xValue, yValue: yValue, duration: duration, easing: easingFunctionFromOption(easingOption))
    }
    
    /// Zooms by the specified scale factor to the specified values on the specified axis.
    ///
    /// - parameter scaleX:
    /// - parameter scaleY:
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func zoomAndCenterViewAnimated(
        scaleX scaleX: CGFloat,
        scaleY: CGFloat,
        xValue: Double,
        yValue: Double,
        duration: NSTimeInterval)
    {
        zoomAndCenterViewAnimated(scaleX: scaleX, scaleY: scaleY, xValue: xValue, yValue: yValue, duration: duration, easingOption: .EaseInOutSine)
    }
    
    /// Resets all zooming and dragging and makes the chart fit exactly it's bounds.
    public func fitScreen()
    {
        let matrix = _viewPortHandler.fitScreen()
        _viewPortHandler.refresh(newMatrix: matrix, chart: self, invalidate: false)
        
        calculateOffsets()
        setNeedsDisplay()
    }
    
    /// Sets the minimum scale value to which can be zoomed out. 1 = fitScreen
    public func setScaleMinima(scaleX: CGFloat, scaleY: CGFloat)
    {
        _viewPortHandler.setMinimumScaleX(scaleX)
        _viewPortHandler.setMinimumScaleY(scaleY)
    }
    
    /// Sets the size of the area (range on the x-axis) that should be maximum visible at once (no further zomming out allowed).
    /// If this is e.g. set to 10, no more than 10 values on the x-axis can be viewed at once without scrolling.
    public func setVisibleXRangeMaximum(maxXRange: CGFloat)
    {
        let deltaX = getDeltaX()
        let xScale = deltaX / maxXRange
        _viewPortHandler.setMinimumScaleX(xScale)
    }
    
    /// Sets the size of the area (range on the x-axis) that should be minimum visible at once (no further zooming in allowed).
    /// If this is e.g. set to 10, no less than 10 values on the x-axis can be viewed at once without scrolling.
    public func setVisibleXRangeMinimum(minXRange: CGFloat)
    {
        let deltaX = getDeltaX()
        let xScale = deltaX / minXRange
        _viewPortHandler.setMaximumScaleX(xScale)
    }
    
    /// Limits the maximum and minimum value count that can be visible by pinching and zooming.
    /// e.g. minRange=10, maxRange=100 no less than 10 values and no more that 100 values can be viewed
    /// at once without scrolling
    public func setVisibleXRange(minXRange minXRange: CGFloat, maxXRange: CGFloat)
    {
        let deltaX = getDeltaX()
        let maxScale = deltaX / minXRange
        let minScale = deltaX / maxXRange
        _viewPortHandler.setMinMaxScaleX(minScaleX: minScale, maxScaleX: maxScale)
    }
    
    /// Sets the size of the area (range on the y-axis) that should be maximum visible at once.
    ///
    /// - parameter yRange:
    public func setVisibleYRangeMaximum(maxYRange: CGFloat)
    {
        let yScale = getDeltaY() / maxYRange
        _viewPortHandler.setMaximumScaleY(yScale)
    }
    
    /// Sets the size of the area (range on the y-axis) that should be minimum visible at once.
    ///
    /// - parameter yRange:
    public func setVisibleYRangeMinimum(minYRange: CGFloat)
    {
        let yScale = getDeltaY() / minYRange
        _viewPortHandler.setMinimumScaleY(yScale)
    }
    
    /// Centers the viewport to the specified x-value on the x-axis.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter xValue:
    public func moveViewToX(xValue: Double)
    {
        let valsInView = getDeltaX() / _viewPortHandler.scaleX
        let job = XYMoveChartViewJob(
            viewPortHandler: viewPortHandler,
            xValue: xValue + Double(valsInView) / 2.0,
            yValue: 0.0,
            transformer: getTransformer(),
            view: self)
        
        addViewportJob(job)
    }
    
    /// Centers the viewport to the specified y-value on the y-axis.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter yValue:
    public func moveViewToY(yValue: Double)
    {
        let valsInView = getDeltaY() / _viewPortHandler.scaleY
        
        let job = XYMoveChartViewJob(
            viewPortHandler: viewPortHandler,
            xValue: 0.0,
            yValue: yValue + Double(valsInView) / 2.0,
            transformer: getTransformer(),
            view: self)
        
        addViewportJob(job)
    }
    
    /// This will move the left side of the current viewport to the specified x-value on the x-axis, and center the viewport to the specified y-value on the y-axis.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    public func moveViewTo(xValue xValue: Double, yValue: Double)
    {
        let xvalsInView = getDeltaX() / _viewPortHandler.scaleX
        let yvalsInView = getDeltaY() / _viewPortHandler.scaleY
        let job = XYMoveChartViewJob(
            viewPortHandler: viewPortHandler,
            xValue: xValue + Double(xvalsInView) / 2.0,
            yValue: yValue + Double(yvalsInView) / 2.0,
            transformer: getTransformer(),
            view: self)
        
        addViewportJob(job)
    }
    
    /// This will move the left side of the current viewport to the specified x-value and center the viewport to the specified y-position animated.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func moveViewToAnimated(
        xValue xValue: Double,
        yValue: Double,
        duration: NSTimeInterval,
        easing: ChartEasingFunctionBlock?)
    {
        let bounds = getValueByTouchPoint(
            pt: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
        
        let yValInView = getDeltaY() / _viewPortHandler.scaleY
        let xValInView = getDeltaX() / _viewPortHandler.scaleX
        
        let job = XYAnimatedMoveChartViewJob(
            viewPortHandler: viewPortHandler,
            xValue: xValue + Double(xValInView) / 2.0,
            yValue: yValue + Double(yValInView) / 2.0,
            transformer: getTransformer(),
            view: self,
            xOrigin: bounds.x,
            yOrigin: bounds.y,
            duration: duration,
            easing: easing)
        
        addViewportJob(job)
    }
    
    /// This will move the left side of the current viewport to the specified x-value and center the viewport to the specified y-position animated.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func moveViewToAnimated(
        xValue xValue: Double,
        yValue: Double,
        duration: NSTimeInterval,
        easingOption: ChartEasingOption)
    {
        moveViewToAnimated(xValue: xValue, yValue: yValue, duration: duration, easing: easingFunctionFromOption(easingOption))
    }
    
    /// This will move the left side of the current viewport to the specified x-value and center the viewport to the specified y-position animated.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func moveViewToAnimated(
        xValue xValue: Double,
        yValue: Double,
        duration: NSTimeInterval)
    {
        moveViewToAnimated(xValue: xValue, yValue: yValue, duration: duration, easingOption: .EaseInOutSine)
    }
    
    /// This will move the center of the current viewport to the specified x-value and y-value.
    /// This also refreshes the chart by calling setNeedsDisplay().
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter axis: - which axis should be used as a reference for the y-axis
    public func centerViewTo(
        xValue xValue: Double,
        yValue: Double)
    {
        let yValInView = getDeltaY() / _viewPortHandler.scaleY
        let xValInView = getDeltaX() / _viewPortHandler.scaleX
        
        let job = XYMoveChartViewJob(
            viewPortHandler: viewPortHandler,
            xValue: xValue + Double(xValInView) / 2.0,
            yValue: yValue + Double(yValInView) / 2.0,
            transformer: getTransformer(),
            view: self)
        
        addViewportJob(job)
    }
    
    /// This will move the center of the current viewport to the specified x-value and y-value animated.
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func centerViewToAnimated(
        xValue xValue: Double,
        yValue: Double,
        duration: NSTimeInterval,
        easing: ChartEasingFunctionBlock?)
    {
        let bounds = getValueByTouchPoint(
            pt: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
        
        let yValInView = getDeltaY() / _viewPortHandler.scaleY
        let xValInView = getDeltaX() / _viewPortHandler.scaleX
        
        let job = XYAnimatedMoveChartViewJob(
            viewPortHandler: viewPortHandler,
            xValue: xValue + Double(xValInView) / 2.0,
            yValue: yValue + Double(yValInView) / 2.0,
            transformer: getTransformer(),
            view: self,
            xOrigin: bounds.x,
            yOrigin: bounds.y,
            duration: duration,
            easing: easing)
        
        addViewportJob(job)
    }
    
    /// This will move the center of the current viewport to the specified x-value and y-value animated.
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func centerViewToAnimated(
        xValue xValue: Double,
        yValue: Double,
        duration: NSTimeInterval,
        easingOption: ChartEasingOption)
    {
        centerViewToAnimated(xValue: xValue, yValue: yValue, duration: duration, easing: easingFunctionFromOption(easingOption))
    }
    
    /// This will move the center of the current viewport to the specified x-value and y-value animated.
    ///
    /// - parameter xValue:
    /// - parameter yValue:
    /// - parameter duration: the duration of the animation in seconds
    /// - parameter easing:
    public func centerViewToAnimated(
        xValue xValue: Double,
        yValue: Double,
        duration: NSTimeInterval)
    {
        centerViewToAnimated(xValue: xValue, yValue: yValue, duration: duration, easingOption: .EaseInOutSine)
    }
    
    /// Sets custom offsets for the current `ChartViewPort` (the offsets on the sides of the actual chart window). Setting this will prevent the chart from automatically calculating it's offsets. Use `resetViewPortOffsets()` to undo this.
    /// ONLY USE THIS WHEN YOU KNOW WHAT YOU ARE DOING, else use `setExtraOffsets(...)`.
    public func setViewPortOffsets(left left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat)
    {
        _customViewPortEnabled = true
        
        if (NSThread.isMainThread())
        {
            self._viewPortHandler.restrainViewPort(offsetLeft: left, offsetTop: top, offsetRight: right, offsetBottom: bottom)
            prepareOffsetMatrix()
            prepareValuePxMatrix()
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), {
                self.setViewPortOffsets(left: left, top: top, right: right, bottom: bottom)
            })
        }
    }
    
    /// Resets all custom offsets set via `setViewPortOffsets(...)` method. Allows the chart to again calculate all offsets automatically.
    public func resetViewPortOffsets()
    {
        _customViewPortEnabled = false
        calculateOffsets()
    }
    
    // MARK: - Accessors
    
    /// - returns: the delta-x value (x-value range) of the specified axis.
    public func getDeltaX() -> CGFloat
    {
        return CGFloat(_xAxis.axisRange)
    }
    
    /// - returns: the delta-y value (y-value range) of the specified axis.
    public func getDeltaY() -> CGFloat
    {
        return CGFloat(_yAxis.axisRange)
    }
    
    /// - returns: the position (in pixels) the provided Entry has inside the chart view
    public func getPosition(e: ChartDataEntry) -> CGPoint
    {
        let ent = e as! XYChartDataEntry
        var vals = CGPoint(x: CGFloat(ent.xvalue), y: CGFloat(ent.yvalue))
        
        getTransformer().pointValueToPixel(&vals)
        
        return vals
    }
    
    /// is dragging enabled? (moving the chart with the finger) for the chart (this does not affect scaling).
    public var dragEnabled: Bool
        {
        get
        {
            return _dragEnabled
        }
        set
        {
            if (_dragEnabled != newValue)
            {
                _dragEnabled = newValue
            }
        }
    }
    
    /// is dragging enabled? (moving the chart with the finger) for the chart (this does not affect scaling).
    public var isDragEnabled: Bool
        {
            return dragEnabled
    }
    
    /// is scaling enabled? (zooming in and out by gesture) for the chart (this does not affect dragging).
    public func setScaleEnabled(enabled: Bool)
    {
        if (_scaleXEnabled != enabled || _scaleYEnabled != enabled)
        {
            _scaleXEnabled = enabled
            _scaleYEnabled = enabled
            #if !os(tvOS)
                _pinchGestureRecognizer.enabled = _pinchZoomEnabled || _scaleXEnabled || _scaleYEnabled
            #endif
        }
    }
    
    public var scaleXEnabled: Bool
        {
        get
        {
            return _scaleXEnabled
        }
        set
        {
            if (_scaleXEnabled != newValue)
            {
                _scaleXEnabled = newValue
                #if !os(tvOS)
                    _pinchGestureRecognizer.enabled = _pinchZoomEnabled || _scaleXEnabled || _scaleYEnabled
                #endif
            }
        }
    }
    
    public var scaleYEnabled: Bool
        {
        get
        {
            return _scaleYEnabled
        }
        set
        {
            if (_scaleYEnabled != newValue)
            {
                _scaleYEnabled = newValue
                #if !os(tvOS)
                    _pinchGestureRecognizer.enabled = _pinchZoomEnabled || _scaleXEnabled || _scaleYEnabled
                #endif
            }
        }
    }
    
    public var isScaleXEnabled: Bool { return scaleXEnabled; }
    public var isScaleYEnabled: Bool { return scaleYEnabled; }
    
    /// flag that indicates if double tap zoom is enabled or not
    public var doubleTapToZoomEnabled: Bool
        {
        get
        {
            return _doubleTapToZoomEnabled
        }
        set
        {
            if (_doubleTapToZoomEnabled != newValue)
            {
                _doubleTapToZoomEnabled = newValue
                _doubleTapGestureRecognizer.enabled = _doubleTapToZoomEnabled
            }
        }
    }
    
    /// **default**: true
    /// - returns: true if zooming via double-tap is enabled false if not.
    public var isDoubleTapToZoomEnabled: Bool
        {
            return doubleTapToZoomEnabled
    }
    
    /// flag that indicates if highlighting per dragging over a fully zoomed out chart is enabled
    public var highlightPerDragEnabled = true
    
    /// If set to true, highlighting per dragging over a fully zoomed out chart is enabled
    /// You might want to disable this when using inside a `NSUIScrollView`
    ///
    /// **default**: true
    public var isHighlightPerDragEnabled: Bool
        {
            return highlightPerDragEnabled
    }
    
    /// **default**: true
    /// - returns: true if drawing the grid background is enabled, false if not.
    public var isDrawGridBackgroundEnabled: Bool
        {
            return drawGridBackgroundEnabled
    }
    
    /// **default**: false
    /// - returns: true if drawing the borders rectangle is enabled, false if not.
    public var isDrawBordersEnabled: Bool
        {
            return drawBordersEnabled
    }
    
    /// - returns: the Highlight object (contains x-index and DataSet index) of the selected value at the given touch point inside the Line-, Scatter-, or CandleStick-Chart.
    public func getHighlightByTouchPoint(pt: CGPoint) -> ChartHighlight?
    {
        if _data === nil
        {
            Swift.print("Can't select by touch. No data set.")
            return nil
        }
        
        return self.highlighter?.getHighlight(x: Double(pt.x), y: Double(pt.y))
    }
    
    /// - returns: the x and y values in the chart at the given touch point
    /// (encapsulated in a `CGPoint`). This method transforms pixel coordinates to
    /// coordinates / values in the chart. This is the opposite method to
    /// `getPixelsForValues(...)`.
    public func getValueByTouchPoint(var pt pt: CGPoint) -> CGPoint
    {
        getTransformer().pixelToValue(&pt)
        
        return pt
    }
    
    /// Transforms the given chart values into pixels. This is the opposite
    /// method to `getValueByTouchPoint(...)`.
    public func getPixelForValue(x: Double, y: Double) -> CGPoint
    {
        var pt = CGPoint(x: CGFloat(x), y: CGFloat(y))
        
        getTransformer().pointValueToPixel(&pt)
        
        return pt
    }
    
    /// - returns: the y-value at the given touch position (must not necessarily be
    /// a value contained in one of the datasets)
    public func getYValueByTouchPoint(pt pt: CGPoint) -> CGFloat
    {
        return getValueByTouchPoint(pt: pt).y
    }
    
    /// - returns: the Entry object displayed at the touched position of the chart
    public func getEntryByTouchPoint(pt: CGPoint) -> ChartDataEntry!
    {
        let h = getHighlightByTouchPoint(pt)
        if (h !== nil)
        {
            return _data!.getEntryForHighlight(h!)
        }
        return nil
    }
    
    /// - returns: the DataSet object displayed at the touched position of the chart
    public func getDataSetByTouchPoint(pt: CGPoint) -> IXYChartDataSet!
    {
        let h = getHighlightByTouchPoint(pt)
        if (h !== nil)
        {
            return _data?.getDataSetByIndex(h!.dataSetIndex) as! IXYChartDataSet!
        }
        return nil
    }
    
    /// - returns: the current x-scale factor
    public var scaleX: CGFloat
        {
            if (_viewPortHandler === nil)
            {
                return 1.0
            }
            return _viewPortHandler.scaleX
    }
    
    /// - returns: the current y-scale factor
    public var scaleY: CGFloat
        {
            if (_viewPortHandler === nil)
            {
                return 1.0
            }
            return _viewPortHandler.scaleY
    }
    
    /// if the chart is fully zoomed out, return true
    public var isFullyZoomedOut: Bool { return _viewPortHandler.isFullyZoomedOut; }
    
    /// - returns: the y-axis object. In the horizontal bar-chart, this is the
    /// top axis.
    public var yAxis: ChartYAxis
        {
            return _yAxis
    }
    
    /// - returns: the object representing all x-labels, this method can be used to
    /// acquire the XAxis object and modify it (e.g. change the position of the
    /// labels)
    public var xAxis: ChartYAxis
        {
            return _xAxis
    }
    
    /// flag that indicates if pinch-zoom is enabled. if true, both x and y axis can be scaled simultaneously with 2 fingers, if false, x and y axis can be scaled separately
    public var pinchZoomEnabled: Bool
        {
        get
        {
            return _pinchZoomEnabled
        }
        set
        {
            if (_pinchZoomEnabled != newValue)
            {
                _pinchZoomEnabled = newValue
                #if !os(tvOS)
                    _pinchGestureRecognizer.enabled = _pinchZoomEnabled || _scaleXEnabled || _scaleYEnabled
                #endif
            }
        }
    }
    
    /// **default**: false
    /// - returns: true if pinch-zoom is enabled, false if not
    public var isPinchZoomEnabled: Bool { return pinchZoomEnabled; }
    
    /// Set an offset in dp that allows the user to drag the chart over it's
    /// bounds on the x-axis.
    public func setDragOffsetX(offset: CGFloat)
    {
        _viewPortHandler.setDragOffsetX(offset)
    }
    
    /// Set an offset in dp that allows the user to drag the chart over it's
    /// bounds on the y-axis.
    public func setDragOffsetY(offset: CGFloat)
    {
        _viewPortHandler.setDragOffsetY(offset)
    }
    
    /// - returns: true if both drag offsets (x and y) are zero or smaller.
    public var hasNoDragOffset: Bool { return _viewPortHandler.hasNoDragOffset; }
    
    /// The X axis renderer. This is a read-write property so you can set your own custom renderer here.
    /// **default**: An instance of ChartXAxisRenderer
    /// - returns: The current set X axis renderer
    public var xAxisRenderer: ChartYAxisRenderer
        {
        get { return _xAxisRenderer }
        set { _xAxisRenderer = newValue }
    }
    
    /// The Y axis renderer. This is a read-write property so you can set your own custom renderer here.
    /// **default**: An instance of ChartYAxisRenderer
    /// - returns: The current set right Y axis renderer
    public var yAxisRenderer: ChartYAxisRenderer
        {
        get { return _yAxisRenderer }
        set { _yAxisRenderer = newValue }
    }
    
    public override var chartYMax: Double
        {
            return _yAxis.axisMaximum
    }
    
    public override var chartYMin: Double
        {
            return _yAxis.axisMinimum
    }
    
    public override var chartXMax: Double
        {
            return _xAxis.axisMaximum
    }
    
    public override var chartXMin: Double
        {
            return _xAxis.axisMinimum
    }
    
    /// - returns: true if either the left or the right or both axes are inverted.
    public var isAnyAxisInverted: Bool
        {
            return _xAxis.isInverted || _yAxis.isInverted
    }
    
    /// flag that indicates if auto scaling on the y axis is enabled.
    /// if yes, the y axis automatically adjusts to the min and max y values of the current x axis range whenever the viewport changes
    public var autoScaleMinMaxEnabled: Bool
        {
        get { return _autoScaleMinMaxEnabled; }
        set { _autoScaleMinMaxEnabled = newValue; }
    }
    
    /// **default**: false
    /// - returns: true if auto scaling on the y axis is enabled.
    public var isAutoScaleMinMaxEnabled : Bool { return autoScaleMinMaxEnabled; }
    
    
    // MARK: - XYChartDataProvider
    
    /// - returns: the Transformer class that contains all matrices and is
    /// responsible for transforming values into pixels on the screen and
    /// backwards.
    public func getTransformer() -> ChartTransformer
    {
        return _valueTransformer
    }
    
    /// the number of maximum visible drawn values on the chart
    /// only active when `setDrawValues()` is enabled
    public var maxVisibleValueCount: Int
        {
        get
        {
            return _maxVisibleValueCount
        }
        set
        {
            _maxVisibleValueCount = newValue
        }
    }
    
    public func isInverted() -> Bool
    {
        return isAnyAxisInverted
    }
    
    public var lowestX: Double
        {
            var pt = CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom)
            getTransformer().pixelToValue(&pt)
            return Double(pt.x)
    }
    
    
    public var highestX: Double
        {
            var pt = CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentBottom)
            getTransformer().pixelToValue(&pt)
            return Double(pt.x)
    }
    
    public var lowestY: Double
        {
            var pt = CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom)
            getTransformer().pixelToValue(&pt)
            return Double(pt.y)
    }
    
    
    public var highestY: Double
        {
            var pt = CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop)
            getTransformer().pixelToValue(&pt)
            return Double(pt.y)
    }
}