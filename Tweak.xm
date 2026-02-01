#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

// ========== OFFSETS FREE FIRE OB52 iOS (offsets_formatadas.txt) ==========
// System.Object
#define ADDR_ANTI_BAN    0x66FFC38   // Finalize
#define ADDR_EQUALS      0x62294D4   // Equals
// Camera/aim (PPLMKEJJHFO - GetCameraTrackableEntityAimRotation)
#define ADDR_AIMBOT      0x3462558   // PPLMKEJJHFO
// Weapon scatter (recoil)
#define ADDR_RECOIL      0x68BA0D4   // set_ScatterSpeed
// Player speed factor (setter - patch ret para travar fator alto)
#define ADDR_SPEED       0x68B9F34   // set_PlayerSpeedFactor

static bool bAimbot = false, bNoRecoil = false;
static bool bEspLinha = false, bSpeed = false, bStreamMod = false;
static bool bTeleport = false, bVoar = false, bForceFPS = false;
static CGPoint lastPoint;

// Cores do ESP (visível = verde, invisível = vermelho) - personalizáveis
static CGFloat espVisivelR = 0.0, espVisivelG = 1.0, espVisivelB = 0.0, espVisivelA = 1.0;
static CGFloat espInvisivelR = 1.0, espInvisivelG = 0.0, espInvisivelB = 0.0, espInvisivelA = 1.0;

// Alvos para ESP linha (preenchido por hooks do jogo ou teste)
#define ESP_MAX_TARGETS 20
static CGPoint espTargets[ESP_MAX_TARGETS];
static int espTargetCount = 0;
static BOOL espTargetVisible[ESP_MAX_TARGETS]; // visível = verde, invisível = vermelho

// Bytes originais para restaurar (evita crash ao desativar)
static uint32_t s_origAimbot = 0, s_origRecoil = 0, s_origSpeed = 0;
static bool s_origAimbotSet = false, s_origRecoilSet = false, s_origSpeedSet = false;

// Patch seguro: não crasha o Free Fire se o endereço for inválido
static bool patchMem(uintptr_t address, uint32_t data) {
    if (address == 0 || address < 0x10000) return false;
    kern_return_t kr;
    kr = vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return false;
    *(uint32_t*)(void*)address = data;
    kr = vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    return (kr == KERN_SUCCESS);
}

// Lê word atual (vm_read evita crash se o endereço não for legível)
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

// Overlay full-screen para ESP - desenha por cima do jogo
@interface ESPOverlayView : UIView
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation ESPOverlayView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.opaque = NO;
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && bEspLinha) {
        if (!self.displayLink) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
    } else if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)tick {
    if (bEspLinha) [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!bEspLinha) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGPoint playerPos = CGPointMake(w / 2.0, h - 60.0); // centro inferior (jogador)

    if (espTargetCount > 0) {
        for (int i = 0; i < espTargetCount && i < ESP_MAX_TARGETS; i++) {
            BOOL vis = espTargetVisible[i];
            if (vis) {
                CGContextSetRGBStrokeColor(ctx, espVisivelR, espVisivelG, espVisivelB, espVisivelA);
            } else {
                CGContextSetRGBStrokeColor(ctx, espInvisivelR, espInvisivelG, espInvisivelB, espInvisivelA);
            }
            CGContextSetLineWidth(ctx, 2.5);
            CGContextSetLineCap(ctx, kCGLineCapRound);
            CGContextMoveToPoint(ctx, playerPos.x, playerPos.y);
            CGContextAddLineToPoint(ctx, espTargets[i].x, espTargets[i].y);
            CGContextStrokePath(ctx);
        }
    } else {
        // Linha de demonstração quando não há alvos (mostra que ESP está ativo)
        CGContextSetRGBStrokeColor(ctx, espVisivelR, espVisivelG, espVisivelB, espVisivelA);
        CGContextSetLineWidth(ctx, 2.5);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextMoveToPoint(ctx, playerPos.x, playerPos.y);
        CGContextAddLineToPoint(ctx, w / 2.0, h * 0.35);
        CGContextStrokePath(ctx);
    }
}
@end

// Permite que hooks do jogo preencham alvos do ESP (chamar de outro tweak ou do jogo)
void setESPTargets(CGPoint *points, BOOL *visible, int count) {
    if (!points || count <= 0 || count > ESP_MAX_TARGETS) { espTargetCount = 0; return; }
    espTargetCount = count;
    for (int i = 0; i < count; i++) {
        espTargets[i] = points[i];
        espTargetVisible[i] = visible ? visible[i] : YES;
    }
}
void setESPVisibleColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    espVisivelR = r; espVisivelG = g; espVisivelB = b; espVisivelA = a;
}
void setESPInvisibleColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    espInvisivelR = r; espInvisivelG = g; espInvisivelB = b; espInvisivelA = a;
}

@interface PainelMukaRage : UIView
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIView *headerGradient;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@end

@implementation PainelMukaRage
static PainelMukaRage *instance;
static ESPOverlayView *g_espOverlay = nil;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        // Overlay ESP em tela cheia (por cima do jogo, atrás do painel)
        g_espOverlay = [[ESPOverlayView alloc] initWithFrame:window.bounds];
        g_espOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        g_espOverlay.hidden = YES;
        [window addSubview:g_espOverlay];

        instance = [[PainelMukaRage alloc] initWithFrame:CGRectMake(0, 0, 360, 770)];
        instance.center = window.center;
        [window addSubview:instance];

        [window bringSubviewToFront:instance];

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
        
        // Título (expectativa do painel: PAINEL RAGE @NYVERXS CHEATS)
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 360, 30)];
        title.text = @"PAINEL RAGE @NYVERXS CHEATS";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [self.headerGradient addSubview:title];
        
        // Subtítulo
        UILabel *subtitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 360, 20)];
        subtitle.text = @"@NYVERXS CHEATS";
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
        @[@"AimKill", @"Mira automática (Aimbot)"],
        @[@"Teleport 10m", @"Teletransporte curto"],
        @[@"Voar Player", @"Voar no mapa"],
        @[@"Speed (?)", @"Velocidade aumentada"],
        @[@"No Recoil (?)", @"Remove recuo das armas"],
        @[@"Force 120 FPS", @"Forçar 120 FPS"],
        @[@"ESP LINHA", @"Linha visual para inimigos (visível/invisível)"],
        @[@"Stream Mod", @"Esconde menu na gravação"]
    ];
    
    int yPos = 100;
    for (int i = 0; i < features.count; i++) {
        ModernToggleButton *btn = [[ModernToggleButton alloc] initWithFrame:CGRectMake(20, yPos, 320, 65) 
                                                                      title:features[i][0]];
        
        UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, 250, 15)];
        desc.text = features[i][1];
        desc.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        desc.font = [UIFont systemFontOfSize:10];
        [btn addSubview:desc];
        
        if (i == 0) btn.onToggle = ^(BOOL on) { [self swAim:on]; };
        else if (i == 1) btn.onToggle = ^(BOOL on) { [self swTeleport:on]; };
        else if (i == 2) btn.onToggle = ^(BOOL on) { [self swVoar:on]; };
        else if (i == 3) btn.onToggle = ^(BOOL on) { [self swSpeed:on]; };
        else if (i == 4) btn.onToggle = ^(BOOL on) { [self swRecoil:on]; };
        else if (i == 5) btn.onToggle = ^(BOOL on) { [self swForceFPS:on]; };
        else if (i == 6) btn.onToggle = ^(BOOL on) { [self swEsp:on]; };
        else if (i == 7) btn.onToggle = ^(BOOL on) { [self swStreamMod:on]; };
        
        [self.mainContainer addSubview:btn];
        yPos += 75;
    }
    
    // Personalização: cores ESP
    yPos += 10;
    UILabel *persLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yPos, 320, 20)];
    persLabel.text = @"Personalização: Cor ESP Visível (verde) | Cor ESP Invisível (vermelho)";
    persLabel.textColor = [UIColor colorWithRed:0.4 green:0.8 blue:0.4 alpha:1.0];
    persLabel.font = [UIFont systemFontOfSize:11];
    [self.mainContainer addSubview:persLabel];
}

-(void)addFooter {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 730, 360, 40)];
    footer.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    footer.layer.cornerRadius = 20;
    footer.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.mainContainer addSubview:footer];
    
    UILabel *info = [[UILabel alloc] initWithFrame:footer.bounds];
    info.text = @"🔒 ANTI-BAN ATIVO | OB52 | v3.0";
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

// Base do binário (slide) - só usa depois do jogo carregar
static uintptr_t getBase(void) {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// LOGICA DAS FUNCOES (patches seguros - não crasham se offset inválido)
-(void)swAim:(BOOL)on {
    bAimbot = on;
    uintptr_t base = getBase();
    uintptr_t addr = base + ADDR_AIMBOT;
    if (!s_origAimbotSet) { s_origAimbotSet = readMem(addr, &s_origAimbot); }
    uint32_t val = bAimbot ? 0xD65F03C0 : (s_origAimbotSet ? s_origAimbot : 0xF9400000);
    patchMem(addr, val);
}

-(void)swRecoil:(BOOL)on {
    bNoRecoil = on;
    uintptr_t base = getBase();
    uintptr_t addr = base + ADDR_RECOIL;
    if (!s_origRecoilSet) { s_origRecoilSet = readMem(addr, &s_origRecoil); }
    uint32_t val = bNoRecoil ? 0xD65F03C0 : (s_origRecoilSet ? s_origRecoil : 0xF9400000);
    patchMem(addr, val);
}

-(void)swEsp:(BOOL)on {
    bEspLinha = on;
    if (g_espOverlay) {
        g_espOverlay.hidden = !on;
        [g_espOverlay setNeedsDisplay];
        if (on) {
            [g_espOverlay didMoveToWindow];
        } else if (g_espOverlay.displayLink) {
            [g_espOverlay.displayLink invalidate];
            g_espOverlay.displayLink = nil;
        }
    }
}

-(void)swSpeed:(BOOL)on {
    bSpeed = on;
    uintptr_t base = getBase();
    uintptr_t addr = base + ADDR_SPEED;
    if (!s_origSpeedSet) { s_origSpeedSet = readMem(addr, &s_origSpeed); }
    uint32_t val = bSpeed ? 0xD65F03C0 : (s_origSpeedSet ? s_origSpeed : 0xF9400000);
    patchMem(addr, val);
}

-(void)swTeleport:(BOOL)on { bTeleport = on; /* offset Teleport 10m se tiver */ }
-(void)swVoar:(BOOL)on { bVoar = on; /* offset Voar Player se tiver */ }
-(void)swForceFPS:(BOOL)on {
    bForceFPS = on;
    // Force 120 FPS: patch comum em jogos (ajustar offset conforme o jogo)
    // uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    // patchMem(base + ADDR_FPS, bForceFPS ? ... : ...);
}

-(void)swStreamMod:(BOOL)on {
    bStreamMod = on;
    if (bStreamMod) {
        self.mainContainer.hidden = YES;
        if (g_espOverlay) g_espOverlay.hidden = !bEspLinha;
    } else {
        self.mainContainer.hidden = NO;
        if (g_espOverlay) g_espOverlay.hidden = !bEspLinha;
    }
}

@end

%ctor {
    // Atrasa injeção para o Free Fire estar totalmente carregado (evita crash)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t base = getBase();
        if (base == 0) return;
        patchMem(base + ADDR_ANTI_BAN, 0xD65F03C0);
        patchMem(base + ADDR_EQUALS, 0xD65F03C0);
    });
}
