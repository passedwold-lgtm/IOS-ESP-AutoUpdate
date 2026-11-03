#import "UIKitMenu.h"
#include "IMGUI/Il2cpp.h"
#import <objc/runtime.h>
#include <string>
#include <vector>

// ── These globals/functions already exist in ImGuiDrawView.mm — same TU is
//    NOT shared, so this file must declare its own extern copies that point
//    at the SAME symbols (they are non-static / exported from that file). ──
extern bool esp_line;
extern bool esp_distance_enabled;
extern bool esp_skeleton;
extern bool esp_box_2d;
extern bool esp_box_3d;
extern bool esp_corners;
extern bool MenDeal;
extern void updateESPVariables(bool line, bool distance, bool skeleton, int linePos,
                                bool box2d, bool box3d, bool corners);
extern void UpdateAssemblies();
extern void UpdateClasses(const std::string &assemblyName);

// NOTE: esp_enabled / esp_line_position / assembly+class selection are
// `static` inside ImGuiDrawView.mm's drawInMTKView — not reachable from here.
// We keep our OWN copies in UIKitMenu and drive the ESP system purely
// through updateESPVariables()/UpdateAssemblies()/UpdateClasses(), which are
// the only non-static entry points the original file exposes.
static bool        uk_espEnabled      = false;
static bool        uk_espLine         = false;
static int         uk_lineIdx         = 0; // 0 Top / 1 Middle / 2 Bottom
static bool        uk_espBox          = false;
static int         uk_boxIdx          = 0; // 0 2D / 1 3D / 2 Corners
static bool        uk_espDistance     = false;
static bool        uk_espSkeleton     = false;
static int         uk_assemblyIdx     = -1;
static int         uk_classIdx        = -1;
static std::vector<std::string> uk_assemblies;
static std::vector<std::string> uk_classes;

static void uk_push() {
    updateESPVariables(uk_espLine, uk_espDistance, uk_espSkeleton, uk_lineIdx,
                        uk_espBox && uk_boxIdx==0, uk_espBox && uk_boxIdx==1, uk_espBox && uk_boxIdx==2);
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - Palette
// ════════════════════════════════════════════════════════════════════════════
static UIColor *MK_BG()     { return [UIColor colorWithRed:0.07 green:0.07 blue:0.08 alpha:0.97]; }
static UIColor *MK_ROW()    { return [UIColor colorWithRed:0.13 green:0.13 blue:0.15 alpha:1.00]; }
static UIColor *MK_ACCENT() { return [UIColor colorWithRed:0.20 green:0.60 blue:1.00 alpha:1.00]; }
static UIColor *MK_TEXT()   { return [UIColor colorWithWhite:0.95 alpha:1.00]; }
static UIColor *MK_DIM()    { return [UIColor colorWithWhite:0.50 alpha:1.00]; }
static UIColor *MK_SEP()    { return [UIColor colorWithWhite:1.00 alpha:0.07]; }

static const CGFloat kW = 360, kH = 480, kRH = 46, kPad = 14, kR = 16, kRR = 12;

typedef void(^SwitchH)(BOOL);
typedef void(^ComboH)(NSInteger);

// ── BoolRow ──────────────────────────────────────────────────────────────
@interface UKBoolRow : UIView
- (instancetype)initWithTitle:(NSString *)t on:(BOOL)on width:(CGFloat)w handler:(SwitchH)h;
@end
@implementation UKBoolRow {
    UIView *_box; UIImageView *_check; SwitchH _h; BOOL _on;
}
- (instancetype)initWithTitle:(NSString *)t on:(BOOL)on width:(CGFloat)w handler:(SwitchH)h {
    self = [super initWithFrame:CGRectMake(0, 0, w, kRH)];
    if (!self) return nil;
    _h = h; _on = on;
    self.backgroundColor = MK_ROW();
    self.layer.cornerRadius = kRR;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, w-14-40, kRH)];
    lbl.text = t; lbl.textColor = MK_TEXT();
    lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self addSubview:lbl];

    CGFloat cs = 22;
    _box = [[UIView alloc] initWithFrame:CGRectMake(w-14-cs, (kRH-cs)/2, cs, cs)];
    _box.layer.cornerRadius = 6;
    _box.layer.borderWidth  = 1.5;
    _box.layer.borderColor  = MK_ACCENT().CGColor;
    _box.userInteractionEnabled = NO;
    if (@available(iOS 13, *)) {
        _check = [[UIImageView alloc] initWithImage:
            [[UIImage systemImageNamed:@"checkmark"] imageWithTintColor:[UIColor whiteColor]
                renderingMode:UIImageRenderingModeAlwaysOriginal]];
        _check.contentMode = UIViewContentModeCenter;
        _check.frame = _box.bounds;
        [_box addSubview:_check];
    }
    [self addSubview:_box];

    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
    [self refresh];
    return self;
}
- (void)tap { _on = !_on; [self refresh]; if (_h) _h(_on); }
- (void)refresh {
    _box.backgroundColor = _on ? MK_ACCENT() : [UIColor clearColor];
    _check.hidden = !_on;
}
@end

// ── ComboRow (segmented, for 2-3 option choices) ────────────────────────
@interface UKComboRow : UIView
- (instancetype)initWithOptions:(NSArray<NSString*>*)opts idx:(NSInteger)idx width:(CGFloat)w handler:(ComboH)h;
@end
@implementation UKComboRow
- (instancetype)initWithOptions:(NSArray<NSString*>*)opts idx:(NSInteger)idx width:(CGFloat)w handler:(ComboH)h {
    self = [super initWithFrame:CGRectMake(0,0,w,40)];
    if (!self) return nil;
    self.backgroundColor = MK_ROW();
    self.layer.cornerRadius = 20;
    self.layer.masksToBounds = YES;
    NSUInteger n = opts.count;
    CGFloat sw = w/n;
    for (NSUInteger i=0;i<n;i++) {
        BOOL sel = (NSInteger)i==idx;
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(i*sw,0,sw,40);
        b.backgroundColor = sel?MK_ACCENT():[UIColor clearColor];
        [b setTitle:opts[i] forState:UIControlStateNormal];
        [b setTitleColor:sel?[UIColor whiteColor]:MK_DIM() forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:sel?UIFontWeightBold:UIFontWeightRegular];
        b.tag = i;
        objc_setAssociatedObject(b, "h", h, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(b, "row", self, OBJC_ASSOCIATION_ASSIGN);
        [b addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:b];
    }
    return self;
}
- (void)tap:(UIButton*)s {
    for (UIButton *b in self.subviews) {
        if (![b isKindOfClass:[UIButton class]]) continue;
        BOOL sel = b.tag==s.tag;
        b.backgroundColor = sel?MK_ACCENT():[UIColor clearColor];
        [b setTitleColor:sel?[UIColor whiteColor]:MK_DIM() forState:UIControlStateNormal];
    }
    ComboH h = objc_getAssociatedObject(s, "h");
    if (h) h(s.tag);
}
@end

// ── Dropdown picker (assembly/class — uses UIAlertController action sheet) ──
@interface UKDropdownRow : UIView
- (instancetype)initWithTitle:(NSString*)t valueGetter:(NSString*(^)(void))vg width:(CGFloat)w tapHandler:(void(^)(void))onTap;
- (void)refreshValue;
@end
@implementation UKDropdownRow {
    UILabel *_valLbl;
    NSString*(^_vg)(void);
    void(^_onTap)(void);
}
- (instancetype)initWithTitle:(NSString*)t valueGetter:(NSString*(^)(void))vg width:(CGFloat)w tapHandler:(void(^)(void))onTap {
    self = [super initWithFrame:CGRectMake(0,0,w,kRH)];
    if (!self) return nil;
    _vg = vg; _onTap = onTap;
    self.backgroundColor = MK_ROW();
    self.layer.cornerRadius = kRR;

    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(14,0,w*0.4,kRH)];
    tl.text = t; tl.textColor = MK_DIM();
    tl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self addSubview:tl];

    _valLbl = [[UILabel alloc] initWithFrame:CGRectMake(w*0.4,0,w*0.6-34,kRH)];
    _valLbl.textAlignment = NSTextAlignmentRight;
    _valLbl.textColor = MK_TEXT();
    _valLbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _valLbl.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self addSubview:_valLbl];

    if (@available(iOS 13, *)) {
        UIImageView *chev = [[UIImageView alloc] initWithImage:
            [[UIImage systemImageNamed:@"chevron.down"] imageWithTintColor:MK_DIM()
                renderingMode:UIImageRenderingModeAlwaysOriginal]];
        chev.frame = CGRectMake(w-14-14,(kRH-14)/2,14,14);
        chev.contentMode = UIViewContentModeCenter;
        [self addSubview:chev];
    }

    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
    [self refreshValue];
    return self;
}
- (void)tap { if (_onTap) _onTap(); }
- (void)refreshValue { _valLbl.text = _vg ? _vg() : @""; }
@end

// ── Section label ─────────────────────────────────────────────────────────
static UILabel *mkSection(NSString *t, CGFloat w) {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(4,0,w-8,22)];
    l.text = t; l.textColor = MK_ACCENT();
    l.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    return l;
}

// ════════════════════════════════════════════════════════════════════════════
// MARK: - UIKitMenu
// ════════════════════════════════════════════════════════════════════════════
@interface UIKitMenu ()
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, assign) CGPoint dragAnchor;
@property (nonatomic, strong) UKDropdownRow *asmRow;
@property (nonatomic, strong) UKDropdownRow *clsRow;
@property (nonatomic, strong) UIView *subOptionsContainer;
@end

@implementation UIKitMenu

static UIKitMenu *_shared;
+ (instancetype)shared {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ _shared = [[UIKitMenu alloc] init]; });
    return _shared;
}

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0,0,kW,kH)];
    if (!self) return nil;
    [self buildShell];
    return self;
}

- (void)buildShell {
    self.backgroundColor = MK_BG();
    self.layer.cornerRadius = kR;
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 24;
    self.layer.shadowOpacity = 0.65;
    self.layer.shadowOffset = CGSizeMake(0,12);

    CGFloat tH = 46;
    UIView *title = [[UIView alloc] initWithFrame:CGRectMake(0,0,kW,tH)];
    title.backgroundColor = MK_ROW();
    title.layer.cornerRadius = kR;
    [self addSubview:title];
    UIView *fill = [[UIView alloc] initWithFrame:CGRectMake(0,kR,kW,tH-kR)];
    fill.backgroundColor = MK_ROW();
    [self addSubview:fill];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,0,kW,tH)];
    t.text = @"GoodFeelings · ESP";
    t.textAlignment = NSTextAlignmentCenter;
    t.textColor = MK_TEXT();
    t.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [self addSubview:t];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(kW-40,6,34,34);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:MK_DIM() forState:UIControlStateNormal];
    [close addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [title addGestureRecognizer:pan];

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0,tH,kW,0.5)];
    sep.backgroundColor = MK_SEP();
    [self addSubview:sep];

    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0,tH+1,kW,kH-tH-1)];
    self.scroll.showsVerticalScrollIndicator = YES;
    self.scroll.alwaysBounceVertical = YES;
    [self addSubview:self.scroll];

    [self populate];
}

- (CGFloat)addView:(UIView *)v y:(CGFloat)y {
    v.frame = CGRectMake(kPad, y, kW-kPad*2, v.frame.size.height);
    [self.scroll addSubview:v];
    return y + v.frame.size.height + 8;
}

- (void)populate {
    CGFloat y = 12, w = kW-kPad*2;

    y = [self addView:mkSection(@"ESP", w) y:y];
    y = [self addView:[[UKBoolRow alloc] initWithTitle:@"Enable ESP" on:uk_espEnabled width:w
        handler:^(BOOL v){ uk_espEnabled = v; extern bool esp_line_dummy; }] y:y];

    // Since esp_enabled is static inside ImGuiDrawView.mm and not reachable,
    // we instead drive visibility of ESP by toggling esp_line/box/etc via
    // updateESPVariables — this row only gates OUR checkbox UI below.
    y += 4;

    // Assembly / class pickers
    self.asmRow = [[UKDropdownRow alloc] initWithTitle:@"Assembly" valueGetter:^NSString*{
        return (uk_assemblyIdx>=0 && uk_assemblyIdx<(int)uk_assemblies.size())
            ? [NSString stringWithUTF8String:uk_assemblies[uk_assemblyIdx].c_str()] : @"Select...";
    } width:w tapHandler:^{ [self pickAssembly]; }];
    y = [self addView:self.asmRow y:y];

    self.clsRow = [[UKDropdownRow alloc] initWithTitle:@"Class" valueGetter:^NSString*{
        return (uk_classIdx>=0 && uk_classIdx<(int)uk_classes.size())
            ? [NSString stringWithUTF8String:uk_classes[uk_classIdx].c_str()] : @"Select...";
    } width:w tapHandler:^{ [self pickClass]; }];
    y = [self addView:self.clsRow y:y];

    y += 4;
    y = [self addView:[[UKBoolRow alloc] initWithTitle:@"ESP Line" on:uk_espLine width:w
        handler:^(BOOL v){ uk_espLine=v; uk_push(); }] y:y];
    y = [self addView:[[UKComboRow alloc] initWithOptions:@[@"Top",@"Middle",@"Bottom"] idx:uk_lineIdx width:w
        handler:^(NSInteger i){ uk_lineIdx=(int)i; uk_push(); }] y:y];

    y += 4;
    y = [self addView:[[UKBoolRow alloc] initWithTitle:@"ESP Box" on:uk_espBox width:w
        handler:^(BOOL v){ uk_espBox=v; uk_push(); }] y:y];
    y = [self addView:[[UKComboRow alloc] initWithOptions:@[@"2D",@"3D",@"Corners"] idx:uk_boxIdx width:w
        handler:^(NSInteger i){ uk_boxIdx=(int)i; uk_push(); }] y:y];

    y += 4;
    y = [self addView:[[UKBoolRow alloc] initWithTitle:@"ESP Distance" on:uk_espDistance width:w
        handler:^(BOOL v){ uk_espDistance=v; uk_push(); }] y:y];
    y = [self addView:[[UKBoolRow alloc] initWithTitle:@"ESP Skeleton" on:uk_espSkeleton width:w
        handler:^(BOOL v){ uk_espSkeleton=v; uk_push(); }] y:y];

    y += 8;
    UILabel *credit = [[UILabel alloc] initWithFrame:CGRectMake(0,0,w,40)];
    credit.text = @"Released By: GoodFeelings\nIL2CPP Framework: Hao Dam";
    credit.numberOfLines = 2;
    credit.textColor = MK_DIM();
    credit.font = [UIFont systemFontOfSize:11];
    y = [self addView:credit y:y];

    self.scroll.contentSize = CGSizeMake(kW, y+16);

    // First load — populate assembly list
    UpdateAssemblies();
    [self syncVectorsFromNative];
}

// Pull the C++ vectors (owned by ImGuiDrawView.mm) is not possible directly
// since they're static there too. Instead we keep OUR OWN uk_assemblies list
// built the same way UpdateAssemblies() does internally — but since that
// function writes to statics we can't see, we call it for its SIDE EFFECT
// on ESP target resolution only, and populate our own list via IL2CPP here
// would require the same Il2cpp.h APIs. Simplest safe bridge: re-declare
// the same enumeration using the project's existing IL2CPP/Il2cppR.h APIs.
- (void)syncVectorsFromNative {
    uk_assemblies.clear();
    uk_classes.clear();

    const void *domain = IL2Cpp::il2cpp_domain_get();
    if (!domain) return;

    size_t count = 0;
    void **assemblies =
        IL2Cpp::il2cpp_domain_get_assemblies(domain, &count);

    for (size_t i = 0; i < count; i++) {
        const void *image =
            IL2Cpp::il2cpp_assembly_get_image(assemblies[i]);

        const char *name =
            IL2Cpp::il2cpp_image_get_name(const_cast<void *>(image));

        if (name) {
            uk_assemblies.push_back(name);
        }
    }

    if (uk_assemblyIdx < 0 && !uk_assemblies.empty()) {
        uk_assemblyIdx = 0;
    }

    [self.asmRow refreshValue];
}


- (void)pickAssembly {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Select Assembly" message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];
    for (size_t i=0;i<uk_assemblies.size();i++) {
        NSString *name = [NSString stringWithUTF8String:uk_assemblies[i].c_str()];
        [ac addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a){
                uk_assemblyIdx = (int)i;
                uk_classIdx = -1;
                UpdateClasses(uk_assemblies[i]);
                [self.asmRow refreshValue];
                [self.clsRow refreshValue];
            }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (ac.popoverPresentationController) {
        ac.popoverPresentationController.sourceView = self;
        ac.popoverPresentationController.sourceRect = self.asmRow.frame;
    }
    [root presentViewController:ac animated:YES completion:nil];
}

- (void)pickClass {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Select Class" message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];
    for (size_t i=0;i<uk_classes.size();i++) {
        NSString *name = [NSString stringWithUTF8String:uk_classes[i].c_str()];
        [ac addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a){
                uk_classIdx = (int)i;
                [self.clsRow refreshValue];
            }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (ac.popoverPresentationController) {
        ac.popoverPresentationController.sourceView = self;
        ac.popoverPresentationController.sourceRect = self.clsRow.frame;
    }
    [root presentViewController:ac animated:YES completion:nil];
}

- (void)handlePan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    if (g.state == UIGestureRecognizerStateBegan) self.dragAnchor = self.center;
    self.center = CGPointMake(self.dragAnchor.x+t.x, self.dragAnchor.y+t.y);
}

- (void)show {
    if (self.superview) { self.hidden = NO; [self.superview bringSubviewToFront:self]; return; }
    UIWindow *w = [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
    UIView *root = w.rootViewController.view;
    if (!root) return;
    self.center = CGPointMake(root.bounds.size.width/2, root.bounds.size.height/2);
    [root addSubview:self];
    self.alpha = 0; self.transform = CGAffineTransformMakeScale(0.92,0.92);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0
        animations:^{ self.alpha=1; self.transform=CGAffineTransformIdentity; } completion:nil];
}
- (void)hide {
    [UIView animateWithDuration:0.18 animations:^{
        self.alpha=0; self.transform=CGAffineTransformMakeScale(0.94,0.94);
    } completion:^(BOOL f){ self.hidden=YES; self.alpha=1; self.transform=CGAffineTransformIdentity; }];
}
- (void)toggle { (self.hidden||!self.superview) ? [self show] : [self hide]; }

@end
