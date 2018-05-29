
#import "WPBadgeView.h"

@interface WPBadgeView()
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint* leadingConstraint;
@property (nonatomic, strong) NSLayoutConstraint* trailingConstraint;
@property (nonatomic, strong) UIView *contentView;
@end

@implementation WPBadgeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialSetup];
    }
    return self;
}

- (instancetype)init
{
    self = [super initWithFrame:(CGRectZero)];
    if (self) {
        [self initialSetup];
    }
    return self;
}

- (void)initialSetup
{
    [self addBlur];
    [self layoutLabel];
    [self style];
}

- (void)layoutLabel
{
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.label];

    self.topConstraint = [self.label.topAnchor constraintEqualToAnchor:self.topAnchor];
    self.bottomConstraint = [self.label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
    self.leadingConstraint = [self.label.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    self.trailingConstraint = [self.label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];

    [NSLayoutConstraint activateConstraints: @[
                                               self.topConstraint,
                                               self.bottomConstraint,
                                               self.leadingConstraint,
                                               self.trailingConstraint
                                               ]];
}

#pragma mark - Getters / setters
- (UILabel *)label
{
    if (_label == nil) {
        _label = [UILabel new];
    }
    return _label;
}

- (void)setInsets:(UIEdgeInsets)insets
{
    _insets = insets;
    self.topConstraint.constant = insets.top;
    self.bottomConstraint.constant = -insets.bottom;
    self.leadingConstraint.constant = insets.left;
    self.trailingConstraint.constant = -insets.right;
    [self setNeedsLayout];
}

#pragma mark - Helpers

- (void)style
{
    self.contentView.layer.cornerRadius = 6.f;
    self.contentView.layer.borderWidth = 0.f;
    self.contentView.clipsToBounds = YES;
    self.layer.cornerRadius = 6.f;
    self.layer.borderWidth = 0.f;
    self.layer.masksToBounds = YES;

    self.label.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.label.textColor = UIColor.whiteColor;
    self.insets = UIEdgeInsetsMake(3.f, 6.f, 3.f, 6.f);
}

- (void)addBlur
{
    self.backgroundColor = [UIColor clearColor];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.4];

    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibranciView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];

    [blurEffectView.contentView addSubview:vibranciView];
    self.contentView = vibranciView.contentView;

    [self addSubview:blurEffectView];
    [self constraintEffectView:vibranciView];
    [self constraintEffectView:blurEffectView];
}

- (void)constraintEffectView:(UIView *)view
{
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                 [view.heightAnchor constraintEqualToAnchor:self.heightAnchor],
                                 [view.widthAnchor constraintEqualToAnchor:self.widthAnchor],
                                 [view.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                                 [view.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
                                 ]];
}

@end
