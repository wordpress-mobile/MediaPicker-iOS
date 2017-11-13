#import "SampleCellOverlayView.h"

@interface SampleCellOverlayView ()
@property (nonatomic, strong) UIView *labelBackgroundView;
@property (nonatomic, strong) UILabel *label;
@end

@implementation SampleCellOverlayView

- (instancetype)init
{
    if (self = [super init]) {
        [self addBackgroundView];
        [self addLabel];
    }

    return self;
}

- (void)addBackgroundView
{
    UIView *labelBackgroundView = [UIView new];
    labelBackgroundView.backgroundColor = [UIColor darkGrayColor];
    labelBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:labelBackgroundView];
    [NSLayoutConstraint activateConstraints:@[
                                              [labelBackgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [labelBackgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              [labelBackgroundView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [labelBackgroundView.heightAnchor constraintEqualToConstant:20.0],
                                              ]];

    self.labelBackgroundView = labelBackgroundView;
}

- (void)addLabel
{
    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:12.0];
    label.textColor = [UIColor whiteColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;

    [self.labelBackgroundView addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
                                              [label.centerXAnchor constraintEqualToAnchor:self.labelBackgroundView.centerXAnchor],
                                              [label.centerYAnchor constraintEqualToAnchor:self.labelBackgroundView.centerYAnchor]
                                              ]];

    self.label = label;
}

- (void)setLabelText:(NSString *)labelText
{
    self.label.text = labelText;
}

- (NSString *)labelText
{
    return self.label.text;
}

@end
