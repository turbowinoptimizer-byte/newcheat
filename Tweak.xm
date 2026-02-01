#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// OFFSETS OB52
#define ADDR_ANTI_BAN    0x66FFC38 
#define ADDR_EQUALS      0x62294D4
#define ADDR_AIMBOT      0x3462558 
#define ADDR_RECOIL      0x68BA0D4 

static bool bAimbot = false, bStreamMode = false, bEspLinha = false;
static int targetBone = 0; 

// Função Segura de Escrita
void patchOffset(uintptr_t address, uint32_t data) {
    vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    *(uint32_t*)address = data;
    vm_protect(mach_task_self(), (vm_address_t)address, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

@interface PainelRage : UIView
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, assign) CGPoint lastPoint; // Para arrastar
@end

@implementation PainelRage
static PainelRage *instance;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        instance = [[PainelRage alloc] initWithFrame:CGRectMake(0, 0, 420, 300)];
        instance.center = window.center;
        [window addSubview:instance];
        
        // Gesto de 3 dedos / 2 toques
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(toggleMenu)];
        tap.numberOfTouchesRequired = 3; tap.numberOfTapsRequired = 2;
        [window addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        // Container do Menu (Design da Foto)
        self.mainContainer = [[UIView alloc] initWithFrame:self.bounds];
        self.mainContainer.backgroundColor = [UIColor blackColor];
        self.mainContainer.layer.borderColor = [UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0].CGColor;
        self.mainContainer.layer.borderWidth = 1.5;
        self.mainContainer.layer.cornerRadius = 12;
        self.mainContainer.clipsToBounds = YES;
        self.mainContainer.hidden = YES;
        [self addSubview:self.mainContainer];
        
        // Header com Título
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 420, 35)];
        header.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0];
        [self.mainContainer addSubview:header];
        
        UILabel *title = [[UILabel alloc] initWithFrame:header.bounds];
        title.text = @"PAINEL RAGE @MUKAWX._";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        [header addSubview:title];

        [self setupControls];
    }
    return self;
}

// FUNÇÃO PARA ARRASTAR O PAINEL
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.lastPoint = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint newPoint = [touch locationInView:self.superview];
    self.center = CGPointMake(newPoint.x + (self.frame.size.width/2 - self.lastPoint.x), 
                             newPoint.y + (self.frame.size.height/2 - self.lastPoint.y));
}

-(void)setupControls {
    // Switch Aimbot
    UISwitch *swAim = [[UISwitch alloc] initWithFrame:CGRectMake(20, 50, 0, 0)];
    [swAim addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventValueChanged];
    [self.mainContainer addSubview:swAim];
    
    UILabel *lAim = [[UILabel alloc] initWithFrame:CGRectMake(80, 50, 200, 30)];
    lAim.text = @"Aimbot Rage"; lAim.textColor = [UIColor whiteColor];
    [self.mainContainer addSubview:lAim];

    // Switch Stream Mode (Invisível na Gravação)
    UISwitch *swStream = [[UISwitch alloc] initWithFrame:CGRectMake(20, 100, 0, 0)];
    [swStream addTarget:self action:@selector(toggleStream:) forControlEvents:UIControlEventValueChanged];
    [self.mainContainer addSubview:swStream];

    UILabel *lStream = [[UILabel alloc] initWithFrame:CGRectMake(80, 100, 200, 30)];
    lStream.text = @"Stream Mode (Anti-Rec)"; lStream.textColor = [UIColor cyanColor];
    [self.mainContainer addSubview:lStream];
}

-(void)toggleMenu {
    self.mainContainer.hidden = !self.mainContainer.hidden;
    self.userInteractionEnabled = !self.mainContainer.hidden;
}

-(void)toggleStream:(UISwitch*)sender {
    bStreamMode = sender.isOn;
    // TÉCNICA DE STREAM MODE:
    // O sistema de captura do iOS não grava views que usam filtros de renderização específicos
    if (bStreamMode) {
        self.layer.sublayerTransform = CATransform3DMakeScale(1.0, 1.0, 1.01); 
        // Aumentar levemente o Z-index da camada faz com que alguns gravadores a ignorem
    } else {
        self.layer.sublayerTransform = CATransform3DIdentity;
    }
}

-(void)toggleAim:(UISwitch*)s {
    bAimbot = s.isOn;
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    uint32_t op = (targetBone == 0) ? 0xD65F03C0 : 0xD65F03C1;
    patchOffset(base + ADDR_AIMBOT, bAimbot ? op : 0xF9400000);
}
@end

// BYPASS DE RECONEXÃO
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t base = _dyld_get_image_vmaddr_slide(0);
        patchOffset(base + ADDR_ANTI_BAN, 0xD65F03C0);
        patchOffset(base + ADDR_EQUALS, 0xD65F03C0);
    });
}
