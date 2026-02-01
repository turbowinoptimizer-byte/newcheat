#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// OFFSETS OB52 RAGE
#define ADDR_ANTI_BAN    0x66FFC38 
#define ADDR_EQUALS      0x62294D4
#define ADDR_AIMBOT      0x3462558 
#define ADDR_RECOIL      0x68BA0D4 
#define ADDR_SPEED       0x40B32E0

static bool bAimbot = false, bNoRecoil = false, bEspLinha = false, bSpeed = false;
static CGPoint lastPoint;

void patchMem(uintptr_t address, uint32_t data) {
    if (address < 0x100000000) return;
    vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    *(uint32_t*)address = data;
    vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

@interface ModernToggleButton : UIView {
    UILabel *_titleLabel;
    UILabel *_statusLabel;
    UIView *_toggleContainer;
    UIView *_toggleCircle;
    BOOL _isOn;
    void(^_onToggle)(BOOL);
}
@end

@implementation ModernToggleButton

- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0];
        self.layer.cornerRadius = 12;
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 200, 20)];
        _titleLabel.text = title;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [self addSubview:_titleLabel];
        
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, 100, 15)];
        _statusLabel.text = @"OFF";
        _statusLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        _statusLabel.font = [UIFont systemFontOfSize:11];
        [self addSubview:_statusLabel];
        
        _toggleContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 70, 20, 50, 28)];
        _toggleContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
        _toggleContainer.layer.cornerRadius = 14;
        [self addSubview:_toggleContainer];
        
        _toggleCircle = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 22, 22)];
        _toggleCircle.backgroundColor = [UIColor whiteColor];
        _toggleCircle.layer.cornerRadius = 11;
        [_toggleContainer addSubview:_toggleCircle];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)setOnToggle:(void(^)(BOOL))block {
    _onToggle = block;
}

- (void)toggle {
    _isOn = !_isOn;
    
    [UIView animateWithDuration:0.25 animations:^{
        if (_isOn) {
            _toggleCircle.frame = CGRectMake(25, 3, 22, 22);
            _toggleContainer.backgroundColor = [UIColor redColor];
            _statusLabel.text = @"ON";
            _statusLabel.textColor = [UIColor redColor];
        } else {
            _toggleCircle.frame = CGRectMake(3, 3, 22, 22);
            _toggleContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
            _statusLabel.text = @"OFF";
            _statusLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        }
    }];
    
    if (_onToggle) _onToggle(_isOn);
}

- (void)dealloc {
    _onToggle = nil;
}

@end

@interface PainelMukaRage : UIView {
    UIView *_mainContainer;
}
@end

@implementation PainelMukaRage
static PainelMukaRage *instance;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        instance = [[PainelMukaRage alloc] initWithFrame:CGRectMake(0, 0, 360, 450)];
        instance.center = window.center;
        [window addSubview:instance];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(toggleMenu)];
        tap.numberOfTouchesRequired = 3; 
        tap.numberOfTapsRequired = 2;
        [window addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _mainContainer = [[UIView alloc] initWithFrame:self.bounds];
        _mainContainer.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.98];
        _mainContainer.layer.cornerRadius = 20;
        _mainContainer.hidden = YES;
        [self addSubview:_mainContainer];
        
        // Header Simplificado
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 80)];
        header.backgroundColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
        header.layer.cornerRadius = 20;
        header.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        [_mainContainer addSubview:header];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 360, 30)];
        title.text = @"RAGE PANEL";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:24];
        [header addSubview:title];
        
        UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 360, 20)];
        subtitle.text = @"@MUKAWX._";
        subtitle.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        subtitle.textAlignment = NSTextAlignmentCenter;
        subtitle.font = [UIFont systemFontOfSize:12];
        [header addSubview:subtitle];
        
        [self addMenuFunctions];
        [self addFooter];
    }
    return self;
}

-(void)addMenuFunctions {
    NSArray *features = @[@"AIMBOT RAGE", @"NO RECOIL 100%", @"ESP LINHA", @"SPEED HACK (5x)"];
    
    int yPos = 100;
    for (int i = 0; i < features.count; i++) {
        ModernToggleButton *btn = [[ModernToggleButton alloc] initWithFrame:CGRectMake(20, yPos, 320, 65) 
                                                                      title:features[i]];
        
        // Callbacks otimizados
        __weak typeof(self) weakSelf = self;
        if (i == 0) [btn setOnToggle:^(BOOL on) { [weakSelf swAim:on]; }];
        else if (i == 1) [btn setOnToggle:^(BOOL on) { [weakSelf swRecoil:on]; }];
        else if (i == 2) [btn setOnToggle:^(BOOL on) { [weakSelf swEsp:on]; }];
        else if (i == 3) [btn setOnToggle:^(BOOL on) { [weakSelf swSpeed:on]; }];
        
        [_mainContainer addSubview:btn];
        yPos += 75;
    }
}

-(void)addFooter {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 410, 360, 40)];
    footer.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    footer.layer.cornerRadius = 20;
    footer.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [_mainContainer addSubview:footer];
    
    UILabel *info = [[UILabel alloc] initWithFrame:footer.bounds];
    info.text = @"ANTI-BAN ATIVO | v2.5";
    info.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    info.textAlignment = NSTextAlignmentCenter;
    info.font = [UIFont boldSystemFontOfSize:12];
    [footer addSubview:info];
}

-(void)touchesBegan:(NSSet*)t withEvent:(UIEvent*)e { 
    lastPoint = [[t anyObject] locationInView:self]; 
}

-(void)touchesMoved:(NSSet*)t withEvent:(UIEvent*)e {
    CGPoint p = [[t anyObject] locationInView:self.superview];
    self.center = CGPointMake(p.x + (self.frame.size.width/2 - lastPoint.x), 
                              p.y + (self.frame.size.height/2 - lastPoint.y));
}

-(void)toggleMenu { 
    _mainContainer.hidden = !_mainContainer.hidden;
}

-(void)swAim:(BOOL)on {
    bAimbot = on;
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    patchMem(base + ADDR_AIMBOT, bAimbot ? 0xD65F03C0 : 0xF9400000);
}

-(void)swRecoil:(BOOL)on {
    bNoRecoil = on;
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    patchMem(base + ADDR_RECOIL, bNoRecoil ? 0xD65F03C0 : 0xF9400000);
}

-(void)swEsp:(BOOL)on {
    bEspLinha = on;
    [self setNeedsDisplay];
}

-(void)swSpeed:(BOOL)on {
    bSpeed = on;
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    patchMem(base + ADDR_SPEED, bSpeed ? 0x40C00000 : 0x40A00000);
}

- (void)drawRect:(CGRect)rect {
    if (!bEspLinha) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextMoveToPoint(ctx, self.bounds.size.width/2, 0);
    CGContextAddLineToPoint(ctx, self.bounds.size.width/2, 500);
    CGContextStrokePath(ctx);
}

@end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t base = _dyld_get_image_vmaddr_slide(0);
        patchMem(base + ADDR_ANTI_BAN, 0xD65F03C0);
        patchMem(base + ADDR_EQUALS, 0xD65F03C0);
    });
}
