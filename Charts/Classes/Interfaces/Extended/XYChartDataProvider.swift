//
//  XYChartDataProvider.swift
//  IOSCharts
//
//  Created by XSUNT on 16/4/25.
//  Copyright © 2016年 dcg. All rights reserved.
//

import Foundation
import CoreGraphics

@objc
public protocol XYChartDataProvider: ChartDataProvider
{
    func getTransformer() -> ChartTransformer
    var maxVisibleValueCount: Int { get }
    func isInverted() -> Bool
}