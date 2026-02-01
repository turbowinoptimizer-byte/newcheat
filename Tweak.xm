#import <UIKit/UIKit.h>
#import <substrate.h>

// --- OFFSETS OB52 (Seu Arquivo) ---
#define ADDR_ANTI_BAN 0x66FFC38 // Finalize
#define ADDR_AIMBOT   0x3462558 // AimRotation
#define ADDR_RECOIL   0x68BA0D4 // ScatterSpeed

// Interface do Painel
@interface MeuPainel : UIView
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UISwitch *aimSwitch;
@end

@implementation MeuPainel

static MeuPainel *instance;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        instance = [[MeuPainel alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:instance];
        
        // Gesto: 3 Dedos, 2 Toques
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(toggleMenu)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 2;
        [[UIApplication sharedApplication].keyWindow addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO; // Transparente para cliques quando fechado
        
        // Criando o design do Painel
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 350)];
        self.menuView.center = self.center;
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        self.menuView.layer.cornerRadius = 15;
        self.menuView.hidden = YES; // Começa escondido
        [self addSubview:self.menuView];
        
        // Título
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 280, 30)];
        title.text = @"PAINEL VIP OB52";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:title];
        
        // Botão Aimbot (Exemplo)
        self.aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 60, 0, 0)];
        [self.aimSwitch addTarget:self action:@selector(ativarAimbot) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:self.aimSwitch];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 150, 30)];
        label.text = @"Aimbot + No Recoil";
        label.textColor = [UIColor whiteColor];
        [self.menuView addSubview:label];
    }
    return self;
}

- (void)toggleMenu {
    self.menuView.hidden = !self.menuView.hidden;
    self.userInteractionEnabled = !self.menuView.hidden;
}

- (void)ativarAimbot {
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    if (self.aimSwitch.isOn) {
        // Aplica as Offsets do seu arquivo
        *(uint32_t*)(base + ADDR_AIMBOT) = 0xD65F03C0; // RET
        *(float*)(base + ADDR_RECOIL) = 0.0f;
    }
}

@end

// --- BYPASS AUTOMÁTICO (ANTI-BAN) ---
%ctor {
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    // Aplica o bypass no Finalize (0x66FFC38) logo no início
    unsigned char patch[] = {0xC0, 0x03, 0x5F, 0xD6};
    vm_write(mach_task_self(), base + ADDR_ANTI_BAN, (vm_offset_t)patch, 4);
}