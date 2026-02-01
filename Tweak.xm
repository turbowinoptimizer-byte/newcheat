#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// OFFSETS OB52 - CONFIGURADAS
#define ADDR_ANTI_BAN    0x66FFC38 
#define ADDR_EQUALS      0x62294D4
#define ADDR_AIMBOT      0x3462558 
#define ADDR_RECOIL      0x68BA0D4 

// Variáveis de Estado
static bool bAimbot = false, bNoRecoil = false, bStreamMode = false;
static int targetBone = 0; // 0=Cabeça, 1=Pescoço, 2=Peito

@interface PainelRage : UIView
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIView *sideBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation PainelRage

static PainelRage *instance;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        } else { window = [UIApplication sharedApplication].keyWindow; }
        
        instance = [[PainelRage alloc] initWithFrame:window.bounds];
        [window addSubview:instance];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(toggleMenu)];
        tap.numberOfTouchesRequired = 3; tap.numberOfTapsRequired = 2;
        [window addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        
        // Container Principal (Igual à foto)
        self.mainContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 450, 280)];
        self.mainContainer.center = self.center;
        self.mainContainer.backgroundColor = [UIColor blackColor];
        self.mainContainer.layer.cornerRadius = 10;
        self.mainContainer.layer.masksToBounds = YES;
        self.mainContainer.layer.borderWidth = 1;
        self.mainContainer.layer.borderColor = [UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0].CGColor;
        self.mainContainer.hidden = YES;
        [self addSubview:self.mainContainer];
        
        // Barra Superior Azul
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 450, 35)];
        header.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0];
        [self.mainContainer addSubview:header];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 450, 35)];
        self.titleLabel.text = @"PAINEL RAGE @MUKAWX._";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [header addSubview:self.titleLabel];

        // Barra Lateral
        self.sideBar = [[UIView alloc] initWithFrame:CGRectMake(5, 40, 60, 235)];
        [self.mainContainer addSubview:self.sideBar];
        [self setupSideBarButtons];

        // Área de Conteúdo
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(70, 40, 370, 230)];
        [self.mainContainer addSubview:self.contentView];
        [self showRageTab];
    }
    return self;
}

- (void)setupSideBarButtons {
    NSArray *icons = @[@"🎯", @"👁️", @"⚙️", @"🪪"];
    for (int i = 0; i < icons.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, i * 55, 55, 50);
        btn.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0];
        btn.layer.cornerRadius = 8;
        [btn setTitle:icons[i] forState:UIControlStateNormal];
        btn.tag = i;
        [btn addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventTouchUpInside];
        [self.sideBar addSubview:btn];
    }
}

- (void)tabChanged:(UIButton*)sender {
    for (UIView *v in self.contentView.subviews) [v removeFromSuperview];
    if (sender.tag == 0) [self showRageTab];
    else if (sender.tag == 1) [self showEspTab];
    else if (sender.tag == 2) [self showSettingsTab];
}

- (void)showRageTab {
    UILabel *secTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 200, 20)];
    secTitle.text = @"⚠️ Funções Rage";
    secTitle.textColor = [UIColor whiteColor];
    [self.contentView addSubview:secTitle];
    
    // Switch Aimbot
    UISwitch *swAim = [[UISwitch alloc] initWithFrame:CGRectMake(10, 35, 0, 0)];
    swAim.on = bAimbot;
    [swAim addTarget:self action:@selector(toggleAim:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:swAim];
    
    UILabel *lAim = [[UILabel alloc] initWithFrame:CGRectMake(70, 35, 100, 30)];
    lAim.text = @"Aimbot"; lAim.textColor = [UIColor whiteColor];
    [self.contentView addSubview:lAim];

    // Switch No Recoil
    UISwitch *swRec = [[UISwitch alloc] initWithFrame:CGRectMake(180, 35, 0, 0)];
    swRec.on = bNoRecoil;
    [swRec addTarget:self action:@selector(toggleRecoil:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:swRec];
    
    UILabel *lRec = [[UILabel alloc] initWithFrame:CGRectMake(240, 35, 100, 30)];
    lRec.text = @"No Recoil"; lRec.textColor = [UIColor whiteColor];
    [self.contentView addSubview:lRec];

    // Seletor de Ossos
    UISegmentedControl *bones = [[UISegmentedControl alloc] initWithItems:@[@"Head", @"Neck", @"Chest"]];
    bones.frame = CGRectMake(10, 80, 250, 30);
    bones.selectedSegmentIndex = targetBone;
    [bones addTarget:self action:@selector(boneChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:bones];
}

- (void)showEspTab {
    UILabel *secTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 200, 20)];
    secTitle.text = @"🟢 Personalização ESP";
    secTitle.textColor = [UIColor whiteColor];
    [self.contentView addSubview:secTitle];

    NSArray *options = @[@"ESP Linha", @"ESP Box", @"ESP Nome"];
    for (int i = 0; i < options.count; i++) {
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(10, 40 + (i*40), 150, 30)];
        lab.text = options[i]; lab.textColor = [UIColor whiteColor];
        [self.contentView addSubview:lab];
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(180, 40 + (i*40), 0, 0)];
        [self.contentView addSubview:sw];
    }
}

- (void)showSettingsTab {
    UILabel *secTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 200, 20)];
    secTitle.text = @"⚙️ Configurações";
    secTitle.textColor = [UIColor whiteColor];
    [self.contentView addSubview:secTitle];

    UILabel *lStream = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 150, 30)];
    lStream.text = @"Stream Mode"; lStream.textColor = [UIColor whiteColor];
    [self.contentView addSubview:lStream];

    UISwitch *swStream = [[UISwitch alloc] initWithFrame:CGRectMake(180, 40, 0, 0)];
    swStream.on = bStreamMode;
    [swStream addTarget:self action:@selector(toggleStream:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:swStream];
}

- (void)toggleMenu {
    self.mainContainer.hidden = !self.mainContainer.hidden;
    self.userInteractionEnabled = !self.mainContainer.hidden;
}

- (void)boneChanged:(UISegmentedControl*)sender { targetBone = (int)sender.selectedSegmentIndex; }

- (void)toggleStream:(UISwitch*)sender {
    bStreamMode = sender.isOn;
    // Otimização: Se stream mode on, reduz opacidade para dificultar detecção em captura
    self.mainContainer.alpha = bStreamMode ? 0.05 : 1.0;
}

- (void)toggleRecoil:(UISwitch*)sender {
    bNoRecoil = sender.isOn;
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    *(float*)(base + ADDR_RECOIL) = bNoRecoil ? 0.0f : 1.0f;
}

- (void)toggleAim:(UISwitch*)sender {
    bAimbot = sender.isOn;
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    uint32_t op = (targetBone == 0) ? 0xD65F03C0 : (targetBone == 1 ? 0xD65F03C1 : 0xD65F03C2);
    if (bAimbot) {
        *(uint32_t*)(base + ADDR_AIMBOT) = op;
    }
}

@end

// ANTI-BAN AUTOMÁTICO
%ctor {
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    unsigned char ret[] = {0xC0, 0x03, 0x5F, 0xD6};
    vm_write(mach_task_self(), base + ADDR_ANTI_BAN, (vm_offset_t)ret, 4);
    vm_write(mach_task_self(), base + ADDR_EQUALS, (vm_offset_t)ret, 4);
}
