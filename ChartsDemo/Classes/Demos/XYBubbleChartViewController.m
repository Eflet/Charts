//
//  XYBubbleChartViewController.m
//  ChartsDemo
//
//  Created by XSUNT on 16/5/5.
//  Copyright © 2016年 dcg. All rights reserved.
//

#import "XYBubbleChartViewController.h"

@interface XYBubbleChartViewController () <ChartViewDelegate>

@property (nonatomic, strong) IBOutlet XYBubbleChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UISlider *sliderY;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextX;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextY;

@end


@implementation XYBubbleChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Bubble Chart";
    
    self.options = @[
                     @{@"key": @"toggleValues", @"label": @"Toggle Values"},
                     @{@"key": @"toggleHighlight", @"label": @"Toggle Highlight"},
                     @{@"key": @"animateX", @"label": @"Animate X"},
                     @{@"key": @"animateY", @"label": @"Animate Y"},
                     @{@"key": @"animateXY", @"label": @"Animate XY"},
                     @{@"key": @"saveToGallery", @"label": @"Save to Camera Roll"},
                     @{@"key": @"togglePinchZoom", @"label": @"Toggle PinchZoom"},
                     @{@"key": @"toggleAutoScaleMinMax", @"label": @"Toggle auto scale min/max"},
                     @{@"key": @"toggleData", @"label": @"Toggle Data"},
                     ];
    
    _chartView.delegate = self;
    
    _chartView.descriptionText = @"";
    _chartView.noDataTextDescription = @"You need to provide data for the chart.";
    
    _chartView.drawGridBackgroundEnabled = NO;
    _chartView.dragEnabled = YES;
    [_chartView setScaleEnabled:YES];
    _chartView.maxVisibleValueCount = 200;
    _chartView.pinchZoomEnabled = YES;
    ChartLegend *l = _chartView.legend;
    l.position = ChartLegendPositionRightOfChart;
    l.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
    
    ChartYAxis *yl = _chartView.yAxis;
    yl.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
    yl.spaceTop = 0.3;
    yl.spaceBottom = 0.3;
//    yl.customAxisMin = 0.0; // this replaces startAtZero = YES
//
    
    ChartYAxis *xl = _chartView.xAxis;
    xl.labelPosition = YAxisLabelPositionOutsideChart;
//    xl.spaceTop = 0.3;
//    xl.spaceBottom = 2;
    xl.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
    
    _sliderX.value = 5.0;
    _sliderY.value = 50.0;
    [self slidersValueChanged:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateChartData
{
    if (self.shouldHideData)
    {
        _chartView.data = nil;
        return;
    }
    
    [self setDataCount:(_sliderX.value + 1) range:_sliderY.value];
}

- (void)setDataCount:(int)count range:(double)range
{
    // No need x vals
//    NSMutableArray *xVals = [[NSMutableArray alloc] init];
//    
//    for (int i = 0; i < count; i++)
//    {
//        [xVals addObject:[@(i) stringValue]];
//    }
    
    NSMutableArray *yVals1 = [[NSMutableArray alloc] init];
    NSMutableArray *yVals2 = [[NSMutableArray alloc] init];
    NSMutableArray *yVals3 = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        double valX = (double) (arc4random_uniform(range));
        double valy = (double) (arc4random_uniform(range));
        double size = (double) (arc4random_uniform(range));
        [yVals1 addObject:[[XYBubbleChartDataEntity alloc] initWithX:valX y:valy size:size xIndex:i]];
        
        valX = (double) (arc4random_uniform(range));
        valy = (double) (arc4random_uniform(range));
        size = (double) (arc4random_uniform(range));
        [yVals2 addObject:[[XYBubbleChartDataEntity alloc] initWithX:valX y:valy size:size xIndex:i]];
        
        valX = (double) (arc4random_uniform(range));
        valy = (double) (arc4random_uniform(range));
        size = (double) (arc4random_uniform(range));
        [yVals3 addObject:[[XYBubbleChartDataEntity alloc] initWithX:valX y:valy size:size xIndex:i]];
    }
    
    XYBubbleChartDataSet *set1 = [[XYBubbleChartDataSet alloc] initWithYVals:yVals1 label:@"DS 1"];
    [set1 setColor:ChartColorTemplates.colorful[0] alpha:0.50f];
    [set1 setDrawValuesEnabled:YES];
    XYBubbleChartDataSet *set2 = [[XYBubbleChartDataSet alloc] initWithYVals:yVals2 label:@"DS 2"];
    [set2 setColor:ChartColorTemplates.colorful[1] alpha:0.50f];
    [set2 setDrawValuesEnabled:YES];
    XYBubbleChartDataSet *set3 = [[XYBubbleChartDataSet alloc] initWithYVals:yVals3 label:@"DS 3"];
    [set3 setColor:ChartColorTemplates.colorful[2] alpha:0.50f];
    [set3 setDrawValuesEnabled:YES];
    
    NSMutableArray *dataSets = [[NSMutableArray alloc] init];
    [dataSets addObject:set1];
    [dataSets addObject:set2];
    [dataSets addObject:set3];
    
    XYBubbleChartData *data = [[XYBubbleChartData alloc] initWithDataSets:dataSets];
    [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:7.f]];
    [data setHighlightCircleWidth: 1.5];
    [data setValueTextColor:UIColor.whiteColor];
    
    _chartView.data = data;
}

- (void)optionTapped:(NSString *)key
{
    [super handleOption:key forChartView:_chartView];
}

#pragma mark - Actions

- (IBAction)slidersValueChanged:(id)sender
{
    _sliderTextX.text = [@((int)_sliderX.value + 1) stringValue];
    _sliderTextY.text = [@((int)_sliderY.value) stringValue];
    
    [self updateChartData];
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull )entry dataSetIndex:(NSInteger)dataSetIndex highlight:(ChartHighlight * __nonnull)highlight
{
    NSLog(@"chartValueSelected");
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}


@end
