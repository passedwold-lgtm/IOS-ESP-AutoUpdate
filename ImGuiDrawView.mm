#import "Esp/ImGuiDrawView.h"
#import "Init/IL2CPPInit.h"
#import "UIKitMenu.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include "IMGUI/imgui.h"
#include "IMGUI/imgui_internal.h"
#include "IMGUI/imgui_impl_metal.h"
#include "IMGUI/imgui_impl_metal.h"
#import "Resources/Fonts/IconsFontAwesome6.h"
#import "Resources/Fonts/IconsFontAwesome6_Bytes.h"
#import "Resources/Fonts/din_alternate.hpp"
#include "IMGUI/Il2cpp.h"
#include <vector>
#include <string>
#define oxorany(x) x
#include "IL2CPP/Vector3.h"
#include "IL2CPP/Vector2.h"
#include "IL2CPP/Vector4.h"
#include "IL2CPP/Quaternion.h"
#include "IL2CPP/Matrix4x4.h"
#include "IL2CPP/Monostring.h"
#include "ESPConfig.h"

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

#include "IL2CPP/Hooks.h"
#include "Resources/Textures/Logo/LogoData.h"
#include "DrawHelpers.mm"

// ImGui Color Variables - custom dark theme
static const ImVec4 COLOR_WINDOW_BG = ImVec4(0.08f, 0.08f, 0.08f, 1.00f);    // #141414
static const ImVec4 COLOR_FRAME_BG = ImVec4(0.08f, 0.08f, 0.08f, 1.00f);       // Match window background
static const ImVec4 COLOR_CHILD_BG = ImVec4(0.09f, 0.09f, 0.09f, 1.00f);       // Original column background
static const ImVec4 COLOR_BUTTON = ImVec4(0.08f, 0.08f, 0.08f, 1.00f);        // Match window background
static const ImVec4 COLOR_BUTTON_HOVERED = ImVec4(0.12f, 0.12f, 0.12f, 1.00f);  // Darker hover
static const ImVec4 COLOR_BUTTON_ACTIVE = ImVec4(0.15f, 0.15f, 0.15f, 1.00f);   // Darker active
static const ImVec4 COLOR_TITLE_BG = ImVec4(0.09f, 0.09f, 0.09f, 1.00f);       // #171717
static const ImVec4 COLOR_TITLE_BG_ACTIVE = ImVec4(0.12f, 0.12f, 0.12f, 1.00f); // Darker active
static const ImVec4 COLOR_CHECK_MARK = ImVec4(1.00f, 0.00f, 0.28f, 1.00f);     // 255, 0, 72
static const ImVec4 COLOR_SLIDER_GRAB = ImVec4(1.00f, 0.00f, 0.28f, 1.00f);       // 255, 0, 72
static const ImVec4 COLOR_TEXT = ImVec4(0.92f, 0.92f, 0.92f, 1.00f);           // Light text
static const ImVec4 COLOR_BORDER = ImVec4(0.20f, 0.20f, 0.20f, 0.50f);         // Border
static const ImVec4 COLOR_SEPARATOR = ImVec4(0.20f, 0.20f, 0.20f, 0.50f);      // Separator
static const ImVec4 COLOR_HEADER = ImVec4(0.09f, 0.09f, 0.09f, 1.00f);        // #171717
static const ImVec4 COLOR_HEADER_HOVERED = ImVec4(0.12f, 0.12f, 0.12f, 1.00f); // Darker hover
static const ImVec4 COLOR_HEADER_ACTIVE = ImVec4(0.15f, 0.15f, 0.15f, 1.00f);  // Darker active
#import <Foundation/Foundation.h>
#import <os/log.h>
#import "pthread.h"
#include <math.h>
#include <deque>
#include <vector>
#include <fstream>

#include <vector>
#import <dlfcn.h>
#include <map>
#include <set>
#include <algorithm>
#include <string>
#import <QuartzCore/QuartzCore.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#include <unistd.h>
#include <string.h>
#include <float.h>


ImFont* verdana_smol;
#define kScale [UIScreen mainScreen].scale

static void* selectedCamera = nullptr;
static bool espInitialized = false;

// Non-static: UIKitMenu.mm (separate TU) needs extern access to these.
bool esp_enabled = false;
bool esp_line = false;
bool esp_distance_enabled = false;
bool esp_skeleton = false;
bool esp_box_2d = false;
bool esp_box_3d = false;
bool esp_corners = false;
static int esp_line_position = 0;
static float ui_scale = 0.70f;


void* getMainCamera() {
    if (!selectedCamera) {
        selectedCamera = Camera_get_main();
    }
    return selectedCamera;
}


void updateESPVariables(bool line, bool distance, bool skeleton, int linePos, bool box2d, bool box3d, bool corners) {
    esp_line = line;
    esp_distance_enabled = distance;
    esp_skeleton = skeleton;
    esp_line_position = linePos;
    esp_box_2d = box2d;
    esp_box_3d = box3d;
    esp_corners = corners;
}




struct PlayerData {
    void* object;
    void* gameObject;
    void* transform;
    Vector3 position;
    Vector3 w2sPosition;
    bool isVisible;
    
    PlayerData() : object(nullptr), gameObject(nullptr), transform(nullptr), isVisible(false) {}
};

#import <vector>
#import <string>
#import <set>

// Dynamic ESP Targeting
static std::string selected_assembly = PLAYER_ASSEMBLY_NAME;
static std::string selected_class = PLAYER_CLASS_NAME;
static std::vector<std::string> available_assemblies;
static std::vector<std::string> available_classes;
static int assembly_idx = -1;
static int class_idx = -1;

void UpdateAssemblies() {
    available_assemblies.clear();
    void* domain = IL2Cpp::il2cpp_domain_get();
    if (!domain) return;
    
    size_t size = 0;
    void** assemblies = IL2Cpp::il2cpp_domain_get_assemblies(domain, &size);
    if (!assemblies) return;
    
    std::set<std::string> assemblyNames;
    for (size_t i = 0; i < size; i++) {
        void* assembly = assemblies[i];
        if (!assembly) continue;
        void* image = (void*)IL2Cpp::il2cpp_assembly_get_image(assembly);
        if (!image) continue;
        const char* name = IL2Cpp::il2cpp_image_get_name(image);
        if (name) assemblyNames.insert(name);
    }
    
    for (const auto& name : assemblyNames) {
        available_assemblies.push_back(name);
        if (name == selected_assembly) {
            assembly_idx = available_assemblies.size() - 1;
        }
    }
}

void UpdateClasses(const std::string& assemblyName) {
    available_classes.clear();
    void* image = IL2Cpp::GetImage(assemblyName.c_str());
    if (!image) return;
    
    size_t count = IL2Cpp::il2cpp_image_get_class_count(image);
    std::set<std::string> classNames;
    
    for (size_t i = 0; i < count; i++) {
        void* klass = IL2Cpp::il2cpp_image_get_class(image, i);
        if (!klass) continue;
        
        const char* name = IL2Cpp::il2cpp_class_get_name(klass);
        const char* namespaze = IL2Cpp::il2cpp_class_get_namespace(klass);
        
        if (name) {
            std::string fullName = (namespaze && strlen(namespaze) > 0) ? (std::string(namespaze) + "." + std::string(name)) : std::string(name);
            classNames.insert(fullName);
        }
    }
    
    for (const auto& name : classNames) {
        available_classes.push_back(name);
        if (name == selected_class) {
            class_idx = available_classes.size() - 1;
        }
    }
}

void drawPlayerRootESP(ImDrawList* draw_list) {
    if (!esp_line && !esp_distance_enabled && !esp_skeleton && !esp_box_2d && !esp_box_3d && !esp_corners) return;
    
    void* camera = Camera_get_main();
    if (!camera) return;
    
    Vector3 cameraPosition = Transform_get_position(GameObject_get_transform(Component_get_gameObject(camera)));
    
    static void* playerType = nullptr;
    static std::string lastClass = "";
    static std::string lastAssembly = "";

    if (!playerType || lastClass != selected_class || lastAssembly != selected_assembly) {
        std::string fullType = selected_class + ", " + selected_assembly;
        playerType = Type_GetType(String_CreateString(fullType.c_str()));
        lastClass = selected_class;
        lastAssembly = selected_assembly;
    }

    if (!playerType) return;
    
    monoArray<void**>* players = Object_FindObjectsOfType(playerType);
    if (!players || players->getLength() == 0) return;

    for (int i = 0; i < players->getLength(); i++) {
        void* object = players->getPointer()[i];
        if (!object) continue;
        
        void* gameObject = Component_get_gameObject(object);
        if (!gameObject || !GameObject_get_activeInHierarchy(gameObject)) continue;
        
        void* transform = Component_get_transform(object);
        if (!transform) continue;
        
        Vector3 position = Transform_get_position(transform);
        if (position.x == 0 && position.y == 0 && position.z == 0) continue;
        
        float distToCamera = Vector3::Distance(cameraPosition, position);
        if (distToCamera > ESP_MAX_DISTANCE) continue;

        Vector3 w2sPosition;
        bool isVisible;
        WorldToScreen(camera, position, w2sPosition, isVisible);
        if (!isVisible) continue;

        // --- Bounds & Skeleton Collection ---
        float minX = FLT_MAX, maxX = -FLT_MAX, minY = FLT_MAX, maxY = -FLT_MAX;
        bool hasSkeletonBounds = false;
        void* foundRenderer = nullptr;

        static void* componentType = nullptr;
        if (!componentType) componentType = Type_GetType(String_CreateString(CREATE_TYPE_STRING(COMPONENT_CLASS_NAME, COMPONENT_ASSEMBLY_NAME)));
        
        monoArray<void**>* components = GameObject_GetComponentsInternal(gameObject, componentType, false, false, false, false, nullptr);
        
        if (components) {
            for (int j = 0; j < components->getLength(); j++) {
                void* comp = components->getPointer()[j];
                if (!comp) continue;
                Il2CppClassMetadata* meta = *(Il2CppClassMetadata**)comp;
                if (!meta->name) continue;
                
                if (strstr(meta->name, "SkinnedMeshRenderer") || strstr(meta->name, "MeshRenderer")) {
                    foundRenderer = comp;
                    if (strstr(meta->name, "SkinnedMeshRenderer")) {
                        monoArray<void**>* bones = SkinnedMeshRenderer_get_bones(comp);
                        if (bones && bones->getLength() > MIN_BONE_COUNT) {
                            for (int b = 0; b < bones->getLength(); b++) {
                                void* bone = bones->getPointer()[b];
                                if (!bone) continue;
                                Vector3 bPos = Transform_get_position(bone);
                                Vector3 bSc; bool bVis;
                                WorldToScreen(camera, bPos, bSc, bVis);
                                if (bVis) {
                                    minX = std::min(minX, bSc.x); maxX = std::max(maxX, bSc.x);
                                    minY = std::min(minY, bSc.y); maxY = std::max(maxY, bSc.y);
                                    hasSkeletonBounds = true;
                                }
                            }
                        }
                    }
                    if (foundRenderer) break;
                }
            }
        }

        ImVec2 pts[8]; bool cornerVisible[8]; int visibleCorners = 0;
        if (!hasSkeletonBounds || esp_box_3d) {
            Vector3 center = position; center.y += 0.9f;
            Vector3 extent(0.4f, 0.9f, 0.4f);
            
            if (foundRenderer) {
                Bounds bounds = Renderer_get_bounds(foundRenderer);
                if (bounds.m_Extents.x > 0.01f) { center = bounds.m_Center; extent = bounds.m_Extents; }
            }
            
            Vector3 worldCorners[8] = {
                Vector3(center.x - extent.x, center.y - extent.y, center.z - extent.z),
                Vector3(center.x + extent.x, center.y - extent.y, center.z - extent.z),
                Vector3(center.x + extent.x, center.y - extent.y, center.z + extent.z),
                Vector3(center.x - extent.x, center.y - extent.y, center.z + extent.z),
                Vector3(center.x - extent.x, center.y + extent.y, center.z - extent.z),
                Vector3(center.x + extent.x, center.y + extent.y, center.z - extent.z),
                Vector3(center.x + extent.x, center.y + extent.y, center.z + extent.z),
                Vector3(center.x - extent.x, center.y + extent.y, center.z + extent.z)
            };
            
            for (int k = 0; k < 8; k++) {
                Vector3 sp; bool vis; WorldToScreen(camera, worldCorners[k], sp, vis);
                pts[k] = ImVec2(sp.x, sp.y); cornerVisible[k] = vis;
                if (vis) {
                    visibleCorners++;
                    if (!hasSkeletonBounds) {
                        minX = std::min(minX, sp.x); maxX = std::max(maxX, sp.x);
                        minY = std::min(minY, sp.y); maxY = std::max(maxY, sp.y);
                    }
                }
            }
        }

        if (!hasSkeletonBounds && visibleCorners < 3) continue;

        float dynamicThickness = std::max(0.8f, 1.2f - (distToCamera * 0.02f));
        ImU32 themePink = ESP_LINE_COLOR;

        if (esp_line) {
            ImVec2 start;
            switch (esp_line_position) {
                case 0: start = ImVec2(kWidth * 0.5f, 0.0f); break; 
                case 1: start = ImVec2(kWidth * 0.5f, kHeight * 0.5f); break; 
                default: start = ImVec2(kWidth * 0.5f, kHeight); break;
            }
            DrawESPLine(draw_list, start, ImVec2(w2sPosition.x, w2sPosition.y), themePink, ESP_LINE_THICKNESS);
        }

        if (esp_box_2d) DrawESPBox2D(draw_list, ImVec2(minX, minY), ImVec2(maxX, maxY), themePink, dynamicThickness);
        if (esp_box_3d) DrawESPBox3D(draw_list, pts, cornerVisible, themePink, dynamicThickness);
        if (esp_corners) DrawESPCorners(draw_list, ImVec2(minX, minY), ImVec2(maxX, maxY), std::max(8.0f, std::min(maxX-minX, maxY-minY)*0.25f), themePink, dynamicThickness);
        if (esp_distance_enabled) DrawESPDistance(draw_list, ImVec2(w2sPosition.x, w2sPosition.y), distToCamera, ESP_DISTANCE_COLOR);
    }
    if (esp_skeleton) DrawESPSkeleton(draw_list, camera, (void*)1, cameraPosition, 0.0f);
}


@interface ImGuiMTKView : MTKView
@end

@implementation ImGuiMTKView
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Check if any subviews (like our toggle button) handle the touch
    for (UIView *subview in self.subviews) {
        if (!subview.hidden && subview.userInteractionEnabled && [subview pointInside:[self convertPoint:point toView:subview] withEvent:event]) {
            return YES;
        }
    }

    ImGuiContext* Context = ImGui::GetCurrentContext();
    if (Context) {
        const ImVector<ImGuiWindow*>& Windows = Context->Windows;
        for (int i = 0; i < Windows.Size; ++i) {
            ImGuiWindow* CurrentWindow = Windows[i];
            if (!CurrentWindow) continue;

            if (CurrentWindow->Active && !(CurrentWindow->Flags & ImGuiWindowFlags_NoInputs)) {
                CGRect touchableArea = CGRectMake(CurrentWindow->Pos.x, CurrentWindow->Pos.y, CurrentWindow->Size.x, CurrentWindow->Size.y);
                if (CGRectContainsPoint(touchableArea, point)) {
                    return [super pointInside:point withEvent:event];
                }
            }
        }
    }
    return NO;
}
@end

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) UIButton *toggleMenuButton;
@end


@implementation ImGuiDrawView

static bool show_s0 = false;




bool MenDeal = true; // non-static: UIKitMenu.mm references via extern


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    // Custom Classic Theme based on source code
    ImGuiStyle& style = ImGui::GetStyle();
    style.Colors[ImGuiCol_WindowBg] = COLOR_WINDOW_BG;
    style.Colors[ImGuiCol_ChildBg] = COLOR_WINDOW_BG;
    style.Colors[ImGuiCol_PopupBg] = COLOR_WINDOW_BG;
    style.Colors[ImGuiCol_FrameBg] = COLOR_FRAME_BG;
    style.Colors[ImGuiCol_FrameBgHovered] = COLOR_BUTTON_HOVERED;
    style.Colors[ImGuiCol_FrameBgActive] = COLOR_BUTTON_ACTIVE;
    style.Colors[ImGuiCol_TitleBg] = COLOR_TITLE_BG;
    style.Colors[ImGuiCol_TitleBgActive] = COLOR_TITLE_BG_ACTIVE;
    style.Colors[ImGuiCol_TitleBgCollapsed] = COLOR_TITLE_BG;
    style.Colors[ImGuiCol_CheckMark] = COLOR_CHECK_MARK;
    style.Colors[ImGuiCol_SliderGrab] = COLOR_SLIDER_GRAB;
    style.Colors[ImGuiCol_SliderGrabActive] = COLOR_SLIDER_GRAB;
    style.Colors[ImGuiCol_Button] = COLOR_BUTTON;
    style.Colors[ImGuiCol_ButtonHovered] = COLOR_BUTTON_HOVERED;
    style.Colors[ImGuiCol_ButtonActive] = COLOR_BUTTON_ACTIVE;
    style.Colors[ImGuiCol_Header] = COLOR_HEADER;
    style.Colors[ImGuiCol_HeaderHovered] = COLOR_HEADER_HOVERED;
    style.Colors[ImGuiCol_HeaderActive] = COLOR_HEADER_ACTIVE;
    style.Colors[ImGuiCol_Separator] = COLOR_SEPARATOR;
    style.Colors[ImGuiCol_SeparatorHovered] = COLOR_SLIDER_GRAB;
    style.Colors[ImGuiCol_SeparatorActive] = COLOR_SLIDER_GRAB;
    style.Colors[ImGuiCol_ResizeGrip] = COLOR_SLIDER_GRAB;
    style.Colors[ImGuiCol_ResizeGripHovered] = ImVec4(1.00f, 0.00f, 0.35f, 1.00f);
    style.Colors[ImGuiCol_ResizeGripActive] = ImVec4(1.00f, 0.00f, 0.45f, 1.00f);
    style.Colors[ImGuiCol_Text] = COLOR_TEXT;
    style.Colors[ImGuiCol_TextDisabled] = ImVec4(COLOR_TEXT.x, COLOR_TEXT.y, COLOR_TEXT.z, 0.5f);
    style.Colors[ImGuiCol_Border] = COLOR_BORDER;
    style.Colors[ImGuiCol_Tab] = COLOR_TITLE_BG;
    style.Colors[ImGuiCol_TabHovered] = COLOR_CHECK_MARK;
    style.Colors[ImGuiCol_TabActive] = COLOR_CHECK_MARK;
    style.Colors[ImGuiCol_TabUnfocused] = COLOR_TITLE_BG;
    style.Colors[ImGuiCol_TabUnfocusedActive] = COLOR_CHECK_MARK;
    
    // Style settings matching source
    style.WindowRounding = 4.0f;
    style.FrameRounding = 2.0f;
    style.PopupRounding = 2.0f;
    style.ScrollbarRounding = 2.0f;
    style.GrabRounding = 2.0f;
    style.GrabRounding = 2.0f;
    style.TabRounding = 2.0f;
    style.WindowPadding = ImVec2(0.0f, 0.0f);
    
    ImFont* font = io.Fonts->AddFontFromMemoryCompressedTTF((void*)din_alternate_compressed_data, din_alternate_compressed_size, 18.0f, NULL, io.Fonts->GetGlyphRangesVietnamese());
    
    // Add FontAwesome icons as merge font
    static const ImWchar icons_ranges[] = { ICON_MIN_FA, ICON_MAX_16_FA, 0 };
    ImFontConfig fa_config;
    fa_config.MergeMode = true;
    fa_config.PixelSnapH = true;
    fa_config.FontDataOwnedByAtlas = false;
    io.Fonts->AddFontFromMemoryCompressedTTF((void*)fa6_solid_compressed_data, fa6_solid_compressed_size, 16.0f, &fa_config, icons_ranges);
    
    ImGui_ImplMetal_Init(_device);

    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (open) [[UIKitMenu shared] show];
        else      [[UIKitMenu shared] hide];
    });
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{

 

    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    self.view = [[ImGuiMTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.clipsToBounds = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [IL2CPPInit startPrecheck];
    });
    
    // Delay button setup to ensure logo texture is loaded
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupToggleMenuButton];
    });
}


- (void)setupToggleMenuButton {
    if (self.toggleMenuButton) return;
    
    CGFloat btnSize = 25.0f;
    self.toggleMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toggleMenuButton.frame = CGRectMake(20, 100, btnSize, btnSize);
    self.toggleMenuButton.layer.cornerRadius = 8.0f;
    self.toggleMenuButton.backgroundColor = [UIColor colorWithRed:0.06f green:0.06f blue:0.06f alpha:0.85f];
    self.toggleMenuButton.layer.borderWidth = 2.0f;
    self.toggleMenuButton.layer.borderColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.28f alpha:1.0f].CGColor;
    self.toggleMenuButton.clipsToBounds = YES;
    
    // Get Logo for Button
    id<MTLTexture> mtlLogo = (__bridge id<MTLTexture>)(void *)getLogoTexture();
    if (mtlLogo) {
        UIImage *logoImg = createUIImageFromMTLTexture(mtlLogo);
        if (logoImg) {
            [self.toggleMenuButton setImage:logoImg forState:UIControlStateNormal];
            self.toggleMenuButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            self.toggleMenuButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        }
    }
    
    [self.toggleMenuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // Add Pan Gesture for dragging
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.toggleMenuButton addGestureRecognizer:panGesture];
    
    [self.view addSubview:self.toggleMenuButton];
}

- (void)toggleMenu {
    MenDeal = !MenDeal;
    NSLog(@"[GF] Toggle Menu - MenDeal is now: %d", MenDeal);
    [[UIKitMenu shared] toggle];

    // Ensure button stays on top and interactive
    [self.view bringSubviewToFront:self.toggleMenuButton];
    self.toggleMenuButton.userInteractionEnabled = YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)pangesture {
    CGPoint translation = [pangesture translationInView:self.view];
    CGPoint newCenter = CGPointMake(pangesture.view.center.x + translation.x, pangesture.view.center.y + translation.y);
    
    // Keep within bounds
    newCenter.x = MAX(pangesture.view.frame.size.width/2, MIN(self.view.frame.size.width - pangesture.view.frame.size.width/2, newCenter.x));
    newCenter.y = MAX(pangesture.view.frame.size.height/2, MIN(self.view.frame.size.height - pangesture.view.frame.size.height/2, newCenter.y));
    
    pangesture.view.center = newCenter;
    [pangesture setTranslation:CGPointZero inView:self.view];
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

#pragma mark - Initialization Overlay

- (void)drawInitializationOverlay {
    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImVec2(kWidth, kHeight));
    ImGui::SetNextWindowBgAlpha(0.0f);
    
    ImGuiWindowFlags window_flags = ImGuiWindowFlags_NoTitleBar | 
                                   ImGuiWindowFlags_NoResize | 
                                   ImGuiWindowFlags_NoMove | 
                                   ImGuiWindowFlags_NoScrollbar | 
                                   ImGuiWindowFlags_NoScrollWithMouse |
                                   ImGuiWindowFlags_NoCollapse |
                                   ImGuiWindowFlags_NoSavedSettings;
    
    if (ImGui::Begin("InitializationOverlay", nullptr, window_flags)) {
        ImVec2 center = ImGui::GetMainViewport()->GetCenter();
        ImGui::SetNextWindowPos(center, ImGuiCond_Always, ImVec2(0.5f, 0.5f));
        ImGui::SetNextWindowSize(ImVec2(320, 160), ImGuiCond_Always);
        
        ImGuiWindowFlags panel_flags = ImGuiWindowFlags_NoTitleBar | 
                                      ImGuiWindowFlags_NoResize | 
                                      ImGuiWindowFlags_NoMove | 
                                      ImGuiWindowFlags_NoScrollbar | 
                                      ImGuiWindowFlags_NoScrollWithMouse |
                                      ImGuiWindowFlags_NoCollapse |
                                      ImGuiWindowFlags_NoSavedSettings;
        
        if (ImGui::Begin("InitPanel", nullptr, panel_flags)) {
            ImGui::TextColored(ImVec4(0.0f, 0.0f, 0.0f, 1.0f), "Checking IL2CPP functions and symbols...");
            ImGui::Spacing();
            
            float progress = [IL2CPPInit getInitializationProgress];
            ImGui::ProgressBar(progress, ImVec2(-1, 0), "");
            ImGui::Spacing();
            
            const char* currentLabel = [IL2CPPInit getCurrentCheckLabel];
            int dotCount = [IL2CPPInit getDotCount];
            std::string dots(dotCount, '.');
            std::string labelText = std::string("Checking: ") + currentLabel + dots;
            ImGui::TextColored(ImVec4(0.0f, 0.0f, 0.0f, 1.0f), "%s", labelText.c_str());
            
            static float spinnerAngle = 0.0f;
            spinnerAngle += 0.1f;
            if (spinnerAngle > 6.28f) spinnerAngle = 0.0f;
            
            ImVec2 spinnerPos = ImGui::GetCursorScreenPos();
            ImGui::GetWindowDrawList()->AddText(
                ImVec2(spinnerPos.x + 150, spinnerPos.y + 20),
                ImGui::GetColorU32(ImVec4(0.0f, 0.0f, 0.0f, 1.0f)),
                "⟳"
            );
        }
        ImGui::End();
    }
    ImGui::End();
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView*)view
{
   
    
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    // NOTE: esp_box_2d/3d/corners are now the FILE-SCOPE globals declared
    // above (non-static) — the old local `static bool esp_box_2d` etc. that
    // used to shadow them here has been removed so UIKitMenu's writes via
    // updateESPVariables() actually reach drawPlayerRootESP().
        
        if ([IL2CPPInit isInitializationComplete]) {
            [self.view setUserInteractionEnabled:YES];
        }

        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        if (renderPassDescriptor != nil)
        {
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"ImGui Jane"];

            ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui::NewFrame();
            
            [IL2CPPInit updateInitializationProgress];
            if ([IL2CPPInit isShowingInitOverlay] && ![IL2CPPInit isInitializationComplete]) {
                [self drawInitializationOverlay];
            }
            
            ImFont* font = ImGui::GetFont();
            
            // Render ESP with fixed font scale (ignoring user settings)
            if (font && font->FontSize > 0) {
                font->Scale = 12.f / 18.0f; // Fixed scale for ESP
            }
            
            CGFloat x = (([UIScreen mainScreen].bounds.size.width) - 360) / 2;
            CGFloat y = (([UIScreen mainScreen].bounds.size.height) - 300) / 2;
            
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
            ImGui::SetNextWindowSize(ImVec2(400, 300), ImGuiCond_FirstUseEver);
            
            // ImGui menu window disabled — UIKitMenu.mm now draws the UI.
            // ESP overlay drawing below (drawPlayerRootESP) still runs every frame.
            if (false && MenDeal == true && [IL2CPPInit isInitializationComplete])
            {            
                // Set font scale to user preference for the main menu content
                if (font) font->Scale = ui_scale;

                ImGui::Begin("GoodFeelings | https://goodfeelings.cc", &MenDeal, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoCollapse);

                ImDrawList* drawList = ImGui::GetWindowDrawList();
                ImVec2 windowPos = ImGui::GetWindowPos();
                ImVec2 windowSize = ImGui::GetWindowSize();
                float headerHeight = 25.0f;
                float footerHeight = 25.0f; // Define footer height here for calculation
                float contentPadding = 10.0f; // Padding for content
                
                // Draw Header Background
                drawList->AddRectFilled(windowPos, ImVec2(windowPos.x + windowSize.x, windowPos.y + headerHeight), ImGui::ColorConvertFloat4ToU32(COLOR_TITLE_BG), ImGui::GetStyle().WindowRounding, ImDrawFlags_RoundCornersTop);
                drawList->AddLine(ImVec2(windowPos.x, windowPos.y + headerHeight), ImVec2(windowPos.x + windowSize.x, windowPos.y + headerHeight), ImGui::ColorConvertFloat4ToU32(COLOR_BORDER));

                // Title Text on the Left
                const char* leftText = "GoodFeelings";
                ImVec2 leftTextSize = ImGui::CalcTextSize(leftText);
                drawList->AddText(ImVec2(windowPos.x + 10, windowPos.y + (headerHeight - leftTextSize.y) * 0.5f), ImGui::ColorConvertFloat4ToU32(COLOR_CHECK_MARK), leftText);
                
                // Title Text on the Right
                const char* titleText = "Unity ESP Auto Update";
                ImVec2 textSize = ImGui::CalcTextSize(titleText);
                drawList->AddText(ImVec2(windowPos.x + windowSize.x - textSize.x - 10, windowPos.y + (headerHeight - textSize.y) * 0.5f), ImGui::ColorConvertFloat4ToU32(COLOR_CHECK_MARK), titleText);

                // Centered Logo
                ImTextureID logoTex = getLogoTexture();
                if (logoTex) {
                     float logoW = getLogoImageWidth();
                     float logoH = getLogoImageHeight();
                     
                     // Keep logo aspect ratio, fit within header height with some padding
                     float maxLogoH = headerHeight - 4.0f; 
                     float scale = maxLogoH / logoH;
                     float drawW = logoW * scale;
                     float drawH = logoH * scale;

                     float logoX = windowPos.x + (windowSize.x - drawW) * 0.5f;
                     float logoY = windowPos.y + (headerHeight - drawH) * 0.5f;

                     drawList->AddImage(logoTex, ImVec2(logoX, logoY), ImVec2(logoX + drawW, logoY + drawH));
                }

                // Drag Area (Invisible Button)
                ImGui::SetCursorPos(ImVec2(0, 0));
                ImGui::InvisibleButton("##HeaderDrag", ImVec2(windowSize.x - 30, headerHeight));
                if (ImGui::IsItemActive()) {
                    ImVec2 delta = ImGui::GetIO().MouseDelta;
                    ImGui::SetWindowPos(ImVec2(windowPos.x + delta.x, windowPos.y + delta.y));
                }

                // --- CONTENT CHILD WINDOW START ---
                // Positioning the content with padding, below header and above footer
                ImGui::SetCursorPos(ImVec2(contentPadding, headerHeight + contentPadding));
                float contentHeight = windowSize.y - headerHeight - footerHeight - (contentPadding * 2);
                float contentWidth = windowSize.x - (contentPadding * 2);
                
                if (ImGui::BeginChild("##MainContent", ImVec2(contentWidth, contentHeight), false, ImGuiWindowFlags_NoBackground))
                {
                    // --- TAB BAR START ---
                    if (ImGui::BeginTabBar("MainTabBar"))
                    {
                        if (ImGui::BeginTabItem(ICON_FA_EYE " ESP"))
                        {
                        ImGui::Checkbox(ICON_FA_EYE " ESP Enable", &esp_enabled);
                        ImGui::Separator();
                        
                        if (esp_enabled) {
                            // --- Target Selection ---
                            static bool firstInit = true;
                            if (firstInit) {
                                UpdateAssemblies();
                                if (assembly_idx != -1) UpdateClasses(available_assemblies[assembly_idx]);
                                firstInit = false;
                            }

                            if (ImGui::BeginCombo("Target Assembly", assembly_idx != -1 ? available_assemblies[assembly_idx].c_str() : "Select Assembly...")) {
                                for (int i = 0; i < (int)available_assemblies.size(); i++) {
                                    bool is_selected = (assembly_idx == i);
                                    if (ImGui::Selectable(available_assemblies[i].c_str(), is_selected)) {
                                        assembly_idx = i;
                                        selected_assembly = available_assemblies[i];
                                        UpdateClasses(selected_assembly);
                                        class_idx = -1; // Reset class when assembly changes
                                    }
                                }
                                ImGui::EndCombo();
                            }

                            if (ImGui::BeginCombo("Target Class", class_idx != -1 ? available_classes[class_idx].c_str() : "Select Class...")) {
                                for (int i = 0; i < (int)available_classes.size(); i++) {
                                    bool is_selected = (class_idx == i);
                                    if (ImGui::Selectable(available_classes[i].c_str(), is_selected)) {
                                        class_idx = i;
                                        selected_class = available_classes[i];
                                    }
                                }
                                ImGui::EndCombo();
                            }
                            ImGui::Separator();

                            ImGui::Checkbox(ICON_FA_MINUS " ESP Line", &esp_line);
                            if (esp_line) {
                                static int esp_line_selection = 0;
                                const char* esp_line_items[] = { "Top", "Middle", "Bottom" };
                                
                                if (ImGui::BeginCombo("Line Position", esp_line_items[esp_line_selection])) {
                                    for (int i = 0; i < IM_ARRAYSIZE(esp_line_items); i++) {
                                        bool is_selected = (esp_line_selection == i);
                                        if (ImGui::Selectable(esp_line_items[i], is_selected)) {
                                            esp_line_selection = i;
                                        }
                                        if (is_selected) {
                                            ImGui::SetItemDefaultFocus();
                                        }
                                    }
                                    ImGui::EndCombo();
                                }
                                
                                esp_line_position = esp_line_selection;
                            }
                            
                            static bool esp_box_enabled = false;
                            ImGui::Checkbox(ICON_FA_SQUARE " ESP Box", &esp_box_enabled);
                            if (esp_box_enabled) {
                                static int esp_box_selection = 0;
                                const char* esp_box_items[] = { "2D Box", "3D Box", "Corners Box" };
                                
                                if (ImGui::BeginCombo("Box Type", esp_box_items[esp_box_selection])) {
                                    for (int i = 0; i < IM_ARRAYSIZE(esp_box_items); i++) {
                                        bool is_selected = (esp_box_selection == i);
                                        if (ImGui::Selectable(esp_box_items[i], is_selected)) {
                                            esp_box_selection = i;
                                        }
                                        if (is_selected) {
                                            ImGui::SetItemDefaultFocus();
                                        }
                                    }
                                    ImGui::EndCombo();
                                }
                                
                                esp_box_2d = (esp_box_selection == 0);
                                esp_box_3d = (esp_box_selection == 1);
                                esp_corners = (esp_box_selection == 2);
                            } else {
                                esp_box_2d = false;
                                esp_box_3d = false;
                                esp_corners = false;
                            }
                            
                            ImGui::Checkbox(ICON_FA_RULER " ESP Distance", &esp_distance_enabled);
                            
                            ImGui::Checkbox(ICON_FA_BONE " ESP Skeleton", &esp_skeleton);
                            
                            updateESPVariables(esp_line, esp_distance_enabled, esp_skeleton, esp_line_position, esp_box_2d, esp_box_3d, esp_corners);
                        }
                        
                        ImGui::Spacing();
                        ImGui::Separator();
                        
                        ImGui::TextColored(COLOR_CHECK_MARK, "Credits:");
                        ImGui::Text("Released By: GoodFeelings");
                        ImGui::Text("IL2CPP Framework: Hao Dam (damduchao)");
                        ImGui::EndTabItem();
                    }
                    
                    
                ImGui::EndTabBar();
                }
                } // Closes BeginChild
                ImGui::EndChild(); // End MainContent
                // --- CONTENT CHILD WINDOW END ---

                // Custom Footer
                ImVec2 footerPos = ImVec2(windowPos.x, windowPos.y + windowSize.y - footerHeight);
                // Footer Background
                drawList->AddRectFilled(footerPos, ImVec2(windowPos.x + windowSize.x, footerPos.y + footerHeight), ImGui::ColorConvertFloat4ToU32(COLOR_TITLE_BG), ImGui::GetStyle().WindowRounding, ImDrawFlags_RoundCornersBottom);
                // Top border of footer
                drawList->AddLine(footerPos, ImVec2(footerPos.x + windowSize.x, footerPos.y), ImGui::ColorConvertFloat4ToU32(COLOR_BORDER));

                static char footerTime[64];
                time_t now = time(0);
                struct tm tstruct;
                tstruct = *localtime(&now);
                strftime(footerTime, sizeof(footerTime), "%Y-%m-%d %H:%M:%S", &tstruct);

                NSString *gameNameStr = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] infoDictionary][@"CFBundleName"] ?: @"Game";
                NSString *bundleIDStr = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.unknown.game";
                NSString *versionStr = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: @"1.0";
                
                const char* gameInfo = [[NSString stringWithFormat:@"%@ | v%@", gameNameStr, versionStr] UTF8String];
                const char* urlStr = "https://goodfeelings.cc";

                float centerY = footerPos.y + (footerHeight - ImGui::GetTextLineHeight()) * 0.5f;

                // Left: Time
                drawList->AddText(ImVec2(footerPos.x + 10, centerY), ImGui::ColorConvertFloat4ToU32(ImVec4(0.6f, 0.6f, 0.6f, 1.0f)), footerTime);

                // Center: URL
                float urlWidth = ImGui::CalcTextSize(urlStr).x;
                drawList->AddText(ImVec2(footerPos.x + (windowSize.x - urlWidth) * 0.5f, centerY), ImGui::ColorConvertFloat4ToU32(COLOR_CHECK_MARK), urlStr);

                // Right: Game Info
                float infoWidth = ImGui::CalcTextSize(gameInfo).x;
                drawList->AddText(ImVec2(footerPos.x + windowSize.x - infoWidth - 10, centerY), ImGui::ColorConvertFloat4ToU32(ImVec4(0.6f, 0.6f, 0.6f, 1.0f)), gameInfo);

                ImGui::End();
                
                // --- DEBUG OVERLAY REMOVED ---
                
            }
            ImDrawList* draw_list = ImGui::GetBackgroundDrawList();

            if (esp_enabled) {
                drawPlayerRootESP(draw_list);
            }



            ImGui::Render();
            ImDrawData* draw_data = ImGui::GetDrawData();
            ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
          
            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];

            [commandBuffer presentDrawable:view.currentDrawable];
        }

        [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}

@end

