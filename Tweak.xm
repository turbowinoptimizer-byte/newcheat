#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

// ========== OFFSETS FREE FIRE OB52 iOS (offsets_formatadas.txt) ==========
// System.Object - usados para desbanir conta (patch seguro)
#define ADDR_FINALIZE    0x66FFC38   // Finalize
#define ADDR_EQUALS      0x62294D4   // Equals

static bool bDesbanirAtivo = false;
static uint32_t s_origFinalize = 0, s_origEquals = 0;
static bool s_origFinalizeSet = false, s_origEqualsSet = false;
static CGPoint lastPoint;

static uintptr_t getBase(void) {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

static bool patchMem(uintptr_t address, uint32_t data) {
    if (address == 0 || address < 0x10000) return false;
    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return false;
    *(uint32_t*)(void*)address = data;
    kr = vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    return (kr == KERN_SUCCESS);
}

static bool readMem(uintptr_t address, uint32_t *out) {
    if (address == 0 || !out) return false;
    pointer_t data = 0;
    mach_msg_type_number_t data_count = 0;
    kern_return_t kr = vm_read(mach_task_self(), (vm_address_t)address, 4, &data, &data_count);
    if (kr != KERN_SUCCESS || data_count < 4) return false;
    *out = *(uint32_t*)(uintptr_t)data;
    vm_deallocate(mach_task_self(), (vm_address_t)data, data_count);
    return true;
}

// Aplica ou remove patches para desbanir conta (não gera ban)
static void applyDesbanir(BOOL on) {
    uintptr_t base = getBase();
    if (base == 0) return;
    uintptr_t addrF = base + ADDR_FINALIZE;
    uintptr_t addrE = base + ADDR_EQUALS;
    if (on) {
        if (!s_origFinalizeSet) s_origFinalizeSet = readMem(addrF, &s_origFinalize);
        if (!s_origEqualsSet) s_origEqualsSet = readMem(addrE, &s_origEquals);
        patchMem(addrF, 0xD65F03C0); // ret ARM64
        patchMem(addrE, 0xD65F03C0);
    } else {
        if (s_origFinalizeSet) patchMem(addrF, s_origFinalize);
        if (s_origEqualsSet) patchMem(addrE, s_origEquals);
    }
}

// ========== PAINEL: Mod Trick (roxo luxo) ==========
@interface UnbanPanelView : UIView
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) CAGradientLayer *headerGradient;
@property (nonatomic, strong) UIView *toggleBg;
@property (nonatomic, strong) UIView *toggleCircle;
@property (nonatomic, assign) BOOL desbanirOn;
@end

@implementation UnbanPanelView

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        UnbanPanelView *panel = [[UnbanPanelView alloc] initWithFrame:window.bounds];
        panel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        panel.backgroundColor = [UIColor clearColor];
        panel.userInteractionEnabled = NO;
        [window addSubview:panel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:panel action:@selector(togglePanel)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 2;
        [window addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat w = 320;
        CGFloat h = 220;
        _container = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - w) / 2, (frame.size.height - h) / 2, w, h)];
        _container.backgroundColor = [UIColor colorWithRed:0.14 green:0.06 blue:0.24 alpha:0.98];
        _container.layer.cornerRadius = 20;
        _container.layer.borderWidth = 1;
        _container.layer.borderColor = [UIColor colorWithRed:0.45 green:0.2 blue:0.7 alpha:0.6].CGColor;
        _container.layer.shadowColor = [UIColor colorWithRed:0.5 green:0.2 blue:0.8 alpha:1.0].CGColor;
        _container.layer.shadowOffset = CGSizeMake(0, 6);
        _container.layer.shadowRadius = 20;
        _container.layer.shadowOpacity = 0.5;
        _container.hidden = YES;
        [self addSubview:_container];

        // Header roxo com gradiente (luxo)
        CGFloat headerH = 56;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, headerH)];
        _headerView.layer.cornerRadius = 20;
        _headerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        [_container addSubview:_headerView];
        _headerGradient = [CAGradientLayer layer];
        _headerGradient.frame = _headerView.bounds;
        _headerGradient.cornerRadius = 20;
        _headerGradient.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        _headerGradient.colors = @[
            (id)[UIColor colorWithRed:0.5 green:0.22 blue:0.78 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.38 green:0.12 blue:0.58 alpha:1.0].CGColor
        ];
        _headerGradient.startPoint = CGPointMake(0, 0);
        _headerGradient.endPoint = CGPointMake(1, 1);
        [_headerView.layer insertSublayer:_headerGradient atIndex:0];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, w, 28)];
        title.text = @"Mod Trick";
        title.textColor = [UIColor colorWithRed:1.0 green:0.95 blue:1.0 alpha:1.0];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        [_headerView addSubview:title];

        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(40, headerH - 1, w - 80, 1)];
        line.backgroundColor = [UIColor colorWithRed:0.6 green:0.35 blue:0.9 alpha:0.5];
        [_container addSubview:line];

        CGFloat btnY = 72;
        CGFloat btnH = 60;
        UIView *btn = [[UIView alloc] initWithFrame:CGRectMake(24, btnY, w - 48, btnH)];
        btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.08 blue:0.32 alpha:1.0];
        btn.layer.cornerRadius = 14;
        btn.layer.borderWidth = 1;
        btn.layer.borderColor = [UIColor colorWithRed:0.45 green:0.2 blue:0.65 alpha:0.5].CGColor;
        [_container addSubview:btn];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 200, 24)];
        lbl.text = @"Desbanir conta";
        lbl.textColor = [UIColor colorWithRed:0.95 green:0.9 blue:1.0 alpha:1.0];
        lbl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [btn addSubview:lbl];

        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 34, 140, 18)];
        status.tag = 101;
        status.text = @"DESATIVADO";
        status.textColor = [UIColor colorWithRed:0.65 green:0.5 blue:0.8 alpha:1.0];
        status.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [btn addSubview:status];

        _toggleBg = [[UIView alloc] initWithFrame:CGRectMake(btn.frame.size.width - 72, 16, 52, 28)];
        _toggleBg.backgroundColor = [UIColor colorWithRed:0.35 green:0.15 blue:0.5 alpha:1.0];
        _toggleBg.layer.cornerRadius = 14;
        _toggleBg.layer.borderWidth = 1;
        _toggleBg.layer.borderColor = [UIColor colorWithRed:0.5 green:0.25 blue:0.7 alpha:0.4].CGColor;
        [btn addSubview:_toggleBg];

        _toggleCircle = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 22, 22)];
        _toggleCircle.backgroundColor = [UIColor colorWithRed:0.95 green:0.88 blue:1.0 alpha:1.0];
        _toggleCircle.layer.cornerRadius = 11;
        _toggleCircle.layer.shadowColor = [UIColor colorWithRed:0.5 green:0.2 blue:0.8 alpha:0.8].CGColor;
        _toggleCircle.layer.shadowOffset = CGSizeMake(0, 2);
        _toggleCircle.layer.shadowRadius = 4;
        _toggleCircle.layer.shadowOpacity = 0.4;
        [_toggleBg addSubview:_toggleCircle];

        UITapGestureRecognizer *btnTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleDesbanir)];
        [btn addGestureRecognizer:btnTap];

        UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(0, h - 40, w, 22)];
        hint.text = @"3 dedos · toque duplo para abrir/fechar";
        hint.textColor = [UIColor colorWithRed:0.6 green:0.45 blue:0.75 alpha:1.0];
        hint.textAlignment = NSTextAlignmentCenter;
        hint.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        [_container addSubview:hint];
    }
    return self;
}

// Quando o painel está fechado: toques passam para o jogo (você joga normal).
// Quando o painel está aberto: toques ficam no painel (não move o jogo).
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.container.hidden) {
        return nil; // painel fechado = toque vai para o jogo
    }
    return [super hitTest:point withEvent:event];
}

- (void)togglePanel {
    BOOL wasHidden = self.container.hidden;
    self.userInteractionEnabled = wasHidden; // aberto = captura toques
    [UIView animateWithDuration:0.25 animations:^{
        self.container.alpha = wasHidden ? 1.0 : 0.0;
        self.container.hidden = !wasHidden;
    } completion:^(BOOL finished) {
        if (self.container.hidden) {
            self.container.alpha = 1.0;
            self.userInteractionEnabled = NO; // fechado = não captura, jogo recebe toques
        }
    }];
}

- (void)toggleDesbanir {
    self.desbanirOn = !self.desbanirOn;
    bDesbanirAtivo = self.desbanirOn;
    applyDesbanir(self.desbanirOn);

    UILabel *status = (UILabel *)[self.container viewWithTag:101];
    if (status) status.text = self.desbanirOn ? @"ATIVADO" : @"DESATIVADO";
    if (status) status.textColor = self.desbanirOn ? [UIColor colorWithRed:0.85 green:0.7 blue:1.0 alpha:1.0] : [UIColor colorWithRed:0.65 green:0.5 blue:0.8 alpha:1.0];

    [UIView animateWithDuration:0.25 animations:^{
        if (self.desbanirOn) {
            self.toggleCircle.frame = CGRectMake(25, 3, 22, 22);
            self.toggleBg.backgroundColor = [UIColor colorWithRed:0.55 green:0.25 blue:0.85 alpha:1.0];
            self.toggleBg.layer.borderColor = [UIColor colorWithRed:0.7 green:0.45 blue:1.0 alpha:0.6].CGColor;
        } else {
            self.toggleCircle.frame = CGRectMake(3, 3, 22, 22);
            self.toggleBg.backgroundColor = [UIColor colorWithRed:0.35 green:0.15 blue:0.5 alpha:1.0];
            self.toggleBg.layer.borderColor = [UIColor colorWithRed:0.5 green:0.25 blue:0.7 alpha:0.4].CGColor;
        }
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    lastPoint = [[touches anyObject] locationInView:self];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.container.hidden) return;
    CGPoint p = [[touches anyObject] locationInView:self];
    self.container.center = CGPointMake(self.container.center.x + (p.x - lastPoint.x), self.container.center.y + (p.y - lastPoint.y));
    lastPoint = p;
}

@end
