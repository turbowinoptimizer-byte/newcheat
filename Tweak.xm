#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h> // Importação necessária corrigida

// --- OFFSETS OB52 (Seu Arquivo) ---
#define ADDR_ANTI_BAN 0x66FFC38 
#define ADDR_AIMBOT   0x3462558 
#define ADDR_RECOIL   0x68BA0D4 

@interface MeuPainel : UIView
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UISwitch *aimSwitch;
@end

@implementation MeuPainel

static MeuPainel *instance;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Correção do keyWindow para iOS moderno
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        instance = [[MeuPainel alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [window addSubview:instance];
        
        // Gesto: 3 Dedos, 2 Toques
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:instance action:@selector(toggleMenu)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 2;
        [window addGestureRecognizer:tap];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 350)];
        self.menuView.center = self.center;
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        self.menuView.layer.cornerRadius = 15;
        self.menuView.layer.borderWidth = 2;
        self.menuView.layer.borderColor = [UIColor cyanColor].CGColor;
        self.menuView.hidden = YES;
        [self addSubview:self.menuView];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 280, 30)];
        title.text = @"PAINEL VIP OB52";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [self.menuView addSubview:title];
        
        self.aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(210, 60, 0, 0)];
        [self.aimSwitch addTarget:self action:@selector(ativarAimbot) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:self.aimSwitch];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 180, 30)];
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
    // Correção da declaração da base
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    if (self.aimSwitch.isOn) {
        // Aplica Patch na Memória
        *(uint32_t*)(base + ADDR_AIMBOT) = 0xD65F03C0; 
        *(float*)(base + ADDR_RECOIL) = 0.0f;
    }
}

@end

// --- BYPASS AUTOMÁTICO (ANTI-BAN) ---
%ctor {
    uintptr_t base = _dyld_get_image_vmaddr_slide(0);
    unsigned char patch[] = {0xC0, 0x03, 0x5F, 0xD6};
    // Bypass na offset Finalize enviada
    vm_write(mach_task_self(), base + ADDR_ANTI_BAN, (vm_offset_t)patch, 4);
}
