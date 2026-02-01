#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// OFFSETS OB52 RAGE
#define ADDR_ANTI_BAN    0x66FFC38 
#define ADDR_EQUALS      0x62294D4
#define ADDR_AIMBOT      0x3462558 
#define ADDR_RECOIL      0x68BA0D4 
#define ADDR_SPEED       0x40B32E0

static bool bAimbot = false, bNoRecoil = false;
static bool bEspLinha = false, bSpeed = false;
static CGPoint lastPoint;

void patchMem(uintptr_t address, uint32_t data) {
    if (address < 0x100000000) return;
    vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    *(uint32_t*)address = data;
    vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

@interface ModernToggleButton : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *toggleContainer;
@property (nonatomic, strong) UIView *toggleCircle;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy) void(^onToggle)(BOOL);
@end

@implementation ModernToggleButton

- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0];
        self.layer.cornerRadius = 12;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 4;
        self.layer.shadowOpacity = 0.3;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 200, 20)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [self addSubview:self.titleLabel];
        
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, 100, 15)];
        self.statusLabel.text = @"DESATIVADO";
        self.statusLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
        self.statusLabel.font = [UIFont systemFontOfSize:11];
        [self addSubview:self.statusLabel];
        
        // Toggle Container
        self.toggleContainer = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 70, 20, 50, 28)];
        self.toggleContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
        self.toggleContainer.layer.cornerRadius = 14;
        [self addSubview:self.toggleContainer];
        
        // Toggle Circle
        self.toggleCircle = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 22, 22)];
        self.toggleCircle.backgroundColor = [UIColor whiteColor];
        self.toggleCircle.layer.cornerRadius = 11;
        self.toggleCircle.layer.shadowColor = [UIColor blackColor].CGColor;
        self.toggleCircle.layer.shadowOffset = CGSizeMake(0, 1);
        self.toggleCircle.layer.shadowRadius = 2;
        self.toggleCircle.layer.shadowOpacity = 0.3;
        [self.toggleContainer addSubview:self.toggleCircle];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)toggle {
    self.isOn = !self.isOn;
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isOn) {
            self.toggleCircle.frame = CGRectMake(25, 3, 22, 22);
            self.toggleContainer.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
            self.statusLabel.text = @"ATIVADO";
            self.statusLabel.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
            self.layer.borderColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5].CGColor;
            self.layer.borderWidth = 1.5;
        } else {
            self.toggleCircle.frame = CGRectMake(3, 3, 22, 22);
            self.toggleContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
            self.statusLabel.text = @"DESATIVADO";
            self.statusLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0];
            self.layer.borderWidth = 0;
        }
    }];
    
    if (self.onToggle) self.onToggle(self.isOn);
}

@end

@interface PainelMukaRage : UIView
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIView *headerGradient;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
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
        tap.numberOfTouchesRequired = 3; tap.numberOfTapsRequired = 2;
        [window addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Container Principal
        self.mainContainer = [[UIView alloc] initWithFrame:self.bounds];
        self.mainContainer.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.1 alpha:0.98];
        self.mainContainer.layer.cornerRadius = 20;
        self.mainContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.mainContainer.layer.shadowOffset = CGSizeMake(0, 10);
        self.mainContainer.layer.shadowRadius = 20;
        self.mainContainer.layer.shadowOpacity = 0.5;
        self.mainContainer.hidden = YES;
        [self addSubview:self.mainContainer];
        
        // Header com Gradiente
        self.headerGradient = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 360, 80)];
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.frame = self.headerGradient.bounds;
        self.gradientLayer.colors = @[
            (id)[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.6 green:0.0 blue:0.0 alpha:1.0].CGColor
        ];
        self.gradientLayer.startPoint = CGPointMake(0, 0);
        self.gradientLayer.endPoint = CGPointMake(1, 1);
        self.gradientLayer.cornerRadius = 20;
        self.gradientLayer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        [self.headerGradient.layer insertSublayer:self.gradientLayer atIndex:0];
        [self.mainContainer addSubview:self.headerGradient];
        
        // Título
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 360, 30)];
        title.text = @"RAGE PANEL";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:24];
        [self.headerGradient addSubview:title];
        
        // Subtítulo
        UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 360, 20)];
        subtitle.text = @"@MUKAWX._";
        subtitle.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        subtitle.textAlignment = NSTextAlignmentCenter;
        subtitle.font = [UIFont systemFontOfSize:12];
        [self.headerGradient addSubview:subtitle];
        
        // Linha Decorativa
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 79, 360, 1)];
        line.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.3];
        [self.mainContainer addSubview:line];
        
        [self addMenuFunctions];
        [self addFooter];
    }
    return self;
}

-(void)addMenuFunctions {
    NSArray *features = @[
        @[@"AIMBOT RAGE", @"Mira automática ultra precisa"],
        @[@"NO RECOIL 100%", @"Remove todo o recuo das armas"],
        @[@"ESP LINHA", @"Linha visual para inimigos"],
        @[@"SPEED HACK (5x)", @"Velocidade aumentada 5x"]
    ];
    
    int yPos = 100;
    for (int i = 0; i < features.count; i++) {
        ModernToggleButton *btn = [[ModernToggleButton alloc] initWithFrame:CGRectMake(20, yPos, 320, 65) 
                                                                      title:features[i][0]];
        
        // Adicionar descrição
        UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, 250, 15)];
        desc.text = features[i][1];
        desc.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        desc.font = [UIFont systemFontOfSize:10];
        [btn addSubview:desc];
        
        // Callbacks
        if (i == 0) btn.onToggle = ^(BOOL on) { [self swAim:on]; };
        else if (i == 1) btn.onToggle = ^(BOOL on) { [self swRecoil:on]; };
        else if (i == 2) btn.onToggle = ^(BOOL on) { [self swEsp:on]; };
        else if (i == 3) btn.onToggle = ^(BOOL on) { [self swSpeed:on]; };
        
        [self.mainContainer addSubview:btn];
        yPos += 75;
    }
}

-(void)addFooter {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 410, 360, 40)];
    footer.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    footer.layer.cornerRadius = 20;
    footer.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.mainContainer addSubview:footer];
    
    UILabel *info = [[UILabel alloc] initWithFrame:footer.bounds];
    info.text = @"🔒 ANTI-BAN ATIVO | v2.5";
    info.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    info.textAlignment = NSTextAlignmentCenter;
    info.font = [UIFont boldSystemFontOfSize:12];
    [footer addSubview:info];
}

// ARRASTAR PAINEL
-(void)touchesBegan:(NSSet*)t withEvent:(UIEvent*)e { 
    lastPoint = [[t anyObject] locationInView:self]; 
}

-(void)touchesMoved:(NSSet*)t withEvent:(UIEvent*)e {
    CGPoint p = [[t anyObject] locationInView:self.superview];
    self.center = CGPointMake(p.x + (self.frame.size.width/2 - lastPoint.x), 
                              p.y + (self.frame.size.height/2 - lastPoint.y));
}

-(void)toggleMenu { 
    [UIView animateWithDuration:0.3 animations:^{
        self.mainContainer.alpha = self.mainContainer.hidden ? 0.0 : 1.0;
        self.mainContainer.transform = self.mainContainer.hidden ? CGAffineTransformMakeScale(0.8, 0.8) : CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.mainContainer.hidden = !self.mainContainer.hidden;
        if (!self.mainContainer.hidden) {
            self.mainContainer.alpha = 1.0;
            self.mainContainer.transform = CGAffineTransformIdentity;
        }
    }];
}

// LOGICA DAS FUNCOES
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

// DESENHO DO ESP
- (void)drawRect:(CGRect)rect {
    if (!bEspLinha) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 3.0);
    
    // Gradiente no ESP
    CGFloat colors[] = {
        1.0, 0.0, 0.0, 1.0,
        1.0, 0.0, 0.0, 0.3
    };
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
    
    CGContextDrawLinearGradient(ctx, gradient, 
                                CGPointMake(self.bounds.size.width/2, 0), 
                                CGPointMake(self.bounds.size.width/2, 500), 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}
@end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t base = _dyld_get_image_vmaddr_slide(0);
        patchMem(base + ADDR_ANTI_BAN, 0xD65F03C0);
        patchMem(base + ADDR_EQUALS, 0xD65F03C0);
    });
}
