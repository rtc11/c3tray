module objc @if(env::DARWIN);
import std::os::macos::objc;
import std::io;
import std::math;

def SendBool = fn void*(void*, ObjcSelector, bool);
def SendContentRec = fn void*(void*, ObjcSelector, NSRect, long, long, bool);
def SendDequeueEvent = fn void*(void*, ObjcSelector, long, void*, ObjcId, bool);
def SendDouble = fn void*(void*, ObjcSelector, double);
def SendEvent = fn void*(void*, ObjcSelector, NSEvent);
def SendId = fn void*(void*, ObjcSelector, ObjcId);
def SendIdId = fn void*(void*, ObjcSelector, ObjcId, ObjcId);
def SendInt = fn void*(void*, ObjcSelector, int);
def SendPtr = fn void*(void*, ObjcSelector, void*);
def SendSelector = fn void*(void*, ObjcSelector, ObjcSelector);
def SendSize = fn void*(void*, ObjcSelector, NSSize);
def SendString = fn void*(void*, ObjcSelector, ZString);
def GetInt = fn int(void*, ObjcSelector);
def GetPoint = fn NSPoint(void*, ObjcSelector);

fault ObjcFault {
    UNKNOWN_EVENT,
    CLASS_NOT_FOUND,
    IVAR_NOT_SET,
    IVAR_NOT_FOUND,
    METHOD_NOT_SET,
    CLASS_INSTANTIATED,
}

struct NSObject {
    ObjcClass cls;
    ObjcId *id;
}

def NSApplication = NSObject;
def NSStatusBar = NSObject;
def NSImage = NSObject;
def NSMenu = NSObject;
def NSMenuItem = NSObject;
def NSString = NSObject;
def NSWindow = NSObject;
def NSAutoreleasePool = NSObject;
def NSValue = NSObject;
def NSDate = NSObject;
distinct NSEvent = void*;
distinct NSStatusBarItem = void*;

// TODO: wait for @operator(construct) to be available (0.6.6?)
// fn NSApplication NSApplication.new() @operator(construct)
// {
//     self.cls = get_class("NSApplication");
//     return self;
// }

// DEPRECATED 
def SendVoid = fn void*(void*, ObjcSelector);
// DEPRECATED 
extern fn ObjcClass allocateClassPair(ObjcClass cls, ZString name, uint extraBytes) @extern("objc_allocateClassPair");
// DEPRECATED 
extern fn bool class_addMethod(ObjcClass cls, ObjcSelector name, void* imp, ZString types);
// DEPRECATED 
extern fn ObjcIvar getInstanceVariable(ObjcId id, ZString name, void* outValue) @extern("object_getInstanceVariable");
// DEPRECATED 
extern fn ObjcIvar setInstanceVariable(ObjcId id, ZString name, void* value) @extern("object_setInstanceVariable");
// DEPRECATED 
extern fn bool class_addIvar(ObjcClass cls, ZString name, int size, double alignment, ZString types);

macro NSObject.call(&self, $FunctionType, ZString $selector, ...)
{
	return (($FunctionType)&objc::msgSend)((ObjcId)self.id, objc::sel_getUid($selector), $vasplat);
}

macro ObjcId.call(ObjcId self, $FunctionType, ZString $selector, ...)
{
	return (($FunctionType)&objc::msgSend)(self, objc::sel_getUid($selector), $vasplat);
}

fn void NSObject.alloc_class_pair(&self, ZString name, uint extra_bytes) {
    self.cls = allocateClassPair(self.cls, name, extra_bytes);
}

fn void NSApplication.sharedApplication(&self) {
    self.id = objc::msg_send(self.cls, SendVoid, "sharedApplication"); 
}
fn void NSApplication.setDelegate(self, NSObject delegate) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    objc::msg_send(self.id, SendId, "setDelegate:", delegate.id);
}
fn void NSApplication.terminate(&self) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    objc::msg_send(self.id, SendId, "terminate:", self.id);
}
fn void NSApplication.activateIgnoringOtherApps(&self, bool flag) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    objc::msg_send(self.id, SendBool, "activateIgnoringOtherApps:", flag);
}
fn NSEvent NSApplication.nextEventMatchingMask(&self, long mask, void* until_date, NSObject in_mode, bool dequeue) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    return (NSEvent)objc::msg_send(self.id, SendDequeueEvent, "nextEventMatchingMask:untilDate:inMode:dequeue:", mask, until_date, in_mode.id, dequeue);
}
fn void NSApplication.finishLaunching(&self) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    objc::msg_send(self.id, SendVoid, "finishLaunching");
}
fn void NSApplication.updateWindows(&self) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    objc::msg_send(self.id, SendVoid, "updateWindows");
}

fn NSPoint NSEvent.locationInWindow(self) {
    return objc::msg_send(self, GetPoint, "locationInWindow");
}
fn int NSEvent.get_type(self) {
    return objc::msg_send(self, GetInt, "type");
}
fn int NSEvent.get_modifierFlags(self) {
    return objc::msg_send(self, GetInt, "modifierFlags");
}

fn void NSApplication.sendEvent(&self, NSEvent event) {
    if (!self.id) io::printfn("NSApplication is not initialized");
    objc::msg_send(self.id, SendEvent, "sendEvent:", event);
}
fn void NSApplication.setActivationPolicy(&self, ApplicationActivationPolicy policy) { 
    objc::msg_send(self.id, SendInt, "setActivationPolicy:", policy.val);
}

fn void NSStatusBar.systemStatusBar(&self) {
    self.id = objc::msg_send(self.cls, SendVoid, "systemStatusBar");
}

macro NSStatusBarItem NSStatusBar.statusItemWithLength(NSStatusBar self, StatusItemLength length)  {
    if (!self.id) io::printfn("NSStatusBar is not initialized");
    return (NSStatusBarItem)objc::msg_send(self.id, SendDouble, "statusItemWithLength:", length.val);
}
fn void NSStatusBarItem.setImage(self, NSImage img) {
    objc::msg_send(self, SendId, "setImage:", img.id);
}
fn void NSStatusBarItem.setMenu(self, NSMenu menu) {
    objc::msg_send(self, SendId, "setMenu:", menu.id);
}
fn void NSImage.initWithContentsOfFile(&self, NSString str) {
    if (!self.id) io::printfn("cant init before you alloc");
    self.id = objc::msg_send(self.id, SendId, "initWithContentsOfFile:", str.id);
}
fn void NSImage.setSize(&self, NSSize size) {
    if (!self.id) io::printfn("NSImage is not initialized");
    objc::msg_send(self.id, SendSize, "setSize:", size);
}

fn void NSObject.init(&self) {
    if (!self.id) io::printfn("cant init before you alloc");
    self.id = objc::msg_send(self.id, SendVoid, "init");
}
fn void NSMenu.setAutoenablesItems(&self, bool flag) {
    if (!self.id) io::printfn("NSMenu is not initialized");
    objc::msg_send(self.id, SendBool, "setAutoenablesItems:", flag);
}
fn void NSMenu.addItem(&self, NSMenuItem item) {
    if (!self.id) io::printfn("NSMenu is not initialized");
    objc::msg_send(self.id, SendId, "addItem:", item.id);
}
fn void NSMenu.setSubmenu(&self, NSMenu menu, NSMenuItem item) {
    if (!self.id) io::printfn("NSMenu is not initialized");
    objc::msg_send(self.id, SendIdId, "setSubmenu:forItem:", menu.id, item.id);
}
fn void NSMenuItem.separatorItem(&self) {
    self.id = objc::msg_send(self.cls, SendVoid, "separatorItem");
}
fn void NSMenuItem.setRepresentedObject(&self, NSValue value) {
    if (!self.id) io::printfn("NSMenuItem is not initialized");
    objc::msg_send(self.id, SendId, "setRepresentedObject:", value.id);
}
fn void NSMenuItem.setState(&self, bool flag) {
    if (!self.id) io::printfn("NSMenuItem is not initialized");
    objc::msg_send(self.id, SendInt, "setState:", flag ? 1 : 0);
}
fn void NSMenuItem.setEnabled(&self, bool flag) {
    if (!self.id) io::printfn("NSMenuItem is not initialized");
    objc::msg_send(self.id, SendBool, "setEnabled:", flag);
}
fn void NSMenuItem.setTitle(&self, NSString title) {
    if (!self.id) io::printfn("NSMenuItem is not initialized");
    objc::msg_send(self.id, SendId, "setTitle:", title.id);
}
fn void NSMenuItem.setAction(&self, ObjcSelector action) {
    if (!self.id) io::printfn("NSMenuItem is not initialized");
    objc::msg_send(self.id, SendSelector, "setAction:", action);
}

fn void NSValue.valueWithPointer(&self, void* ptr) {
    self.id = objc::msg_send(self.cls, SendPtr, "valueWithPointer:", ptr);
}
fn void NSString.stringWithUTF8String(&self, ZString str) {
    self.id = objc::msg_send(self.cls, SendString, "stringWithUTF8String:", str);
}

fn void NSDate.distantFuture(&self) {
    self.id = objc::msg_send(self.cls, SendVoid, "distantFuture");
}

fn void NSWindow.initWithContentRect(&self, NSRect rect, ulong style_mask, ulong backing, bool is_defer) {
    if (!self.id) io::printfn("NSWindow not initialized"); 
    self.id = objc::msg_send(self.id, SendContentRec, "initWithContentRect:styleMask:backing:defer:", rect, style_mask, backing, is_defer);
}
fn void NSWindow.makeKeyAndOrderFront(&self, ObjcSelector sel) {
    if (!self.id) io::printfn("WARN: NSWindow not initialized"); 
    objc::msg_send(self.id, SendSelector, "makeKeyAndOrderFront:", sel);
}
fn void NSWindow.setIsVisible(&self, bool flag) {
    if (!self.id) io::printfn("WARN: NSWindow not initialized"); 
    objc::msg_send(self.id, SendBool, "setIsVisible:", flag);
}

fn NSObject alloc(NSObject object) {
    object.id = objc::msg_send(object.cls, SendVoid, "alloc");
    return object;
}
fn void release(NSObject object) {
    objc::msg_send(object.cls, SendVoid, "release");
}

macro void! NSObject.add_method(NSObject self, ZString name, void* imp, ZString types = "")
{
    if(self.id) return ObjcFault.CLASS_INSTANTIATED?;
    if(!class_addMethod(self.cls, objc::sel_registerName(name), imp, types)) return ObjcFault.METHOD_NOT_SET?;
}

macro ObjcClass! ObjcClass.add_method(ObjcClass self, ZString name, void* imp, ZString types = "") 
{
    if(!class_addMethod(self, register_name(name), imp, types)) return ObjcFault.METHOD_NOT_SET?;
    return self;
}

macro NSObject! NSObject.add_ivar(NSObject self, ZString name, int size, double alignment, ZString types) 
{
    if(!class_addIvar(self.cls, name, size, alignment, types)) return ObjcFault.IVAR_NOT_SET?;
    return self;
}

macro ObjcIvar! ObjcId.get_ivar(ObjcId self, ZString name)
{
    ObjcIvar out;
    if(!getInstanceVariable(self, name, &out)) return ObjcFault.IVAR_NOT_FOUND?; 
    return out;
}

macro void NSObject.setInstanceVariable(NSObject self, ZString name, NSObject out)
{
    setInstanceVariable(self.id, name, out.id);
}

struct NSPoint {
    double x;
    double y;
}

struct NSSize {
    double width;
    double height;
}

struct NSRect {
    NSPoint origin;
    NSSize size;
}


// DEPRECATED 
enum StatusItemLength : (double val)
{
    VARIABLE = -1.0,
    SQUARE   = -2.0,
}

// DEPRECATED 
enum ApplicationActivationPolicy : (int val)
{
	REGULAR    = 0,
	ACCESSORY  = 1,
	PROHIBITED = 2,
}

// DEPRECATED 
enum WindowStyleMask : (int val)
{
    BORDERLESS                = 0,
    TITLED                    = 1 << 0,
    CLOSABLE                  = 1 << 1,
	MINIATURIZABLE            = 1 << 2,
	RESIZABLE                 = 1 << 3,
	TEXTURED_BACKGROUND       = 1 << 8,
	UNIFIED_TITLE_AND_TOOLBAR = 1 << 12,
	FULL_SCREEN               = 1 << 14,
	FULL_SIZE_CONTENT_VIEW    = 1 << 15,
	UTILITY_WINDOW            = 1 << 4,
	DOC_MODAL_WINDOW          = 1 << 6,
	NONACTIVATING_PANEL       = 1 << 7,
	HUD_WINDOW                = 1 << 13
}

// DEPRECATED 
enum BackingStore : (int val)
{
	RETAINED    = 0,
	NONRETAINED = 1,
	BUFFERED    = 2
}

// DEPRECATED
enum EventType : (long val)
{
	LEFT_MOUSE_DOWN     = 1,
	LEFT_MOUSE_UP       = 2,
	RIGHT_MOUSE_DOWN    = 3,
	RIGHT_MOUSE_UP      = 4,
	MOUSE_MOVED         = 5,
	LEFT_MOUSE_DRAGGED  = 6,
	RIGHT_MOUSE_DRAGGED = 7,
	MOUSE_ENTERED       = 8,
	MOUSE_EXITED        = 9,
	KEY_DOWN            = 10,
	KEY_UP              = 11,
	FLAGS_CHANGED       = 12,
	APPKIT_DEFINED      = 13,
	SYSTEM_DEFINED      = 14,
	APPLICATION_DEFINED = 15,
	PERIODIC            = 16,
	CURSOR_UPDATE       = 17,
	SCROLL_WHEEL        = 22,
	TABLET_POINT        = 23,
	TABLET_PROXIMITY    = 24,
	OTHER_MOUSE_DOWN    = 25,
	OTHER_MOUSE_UP      = 26,
	OTHER_MOUSE_DRAGGED = 27,
	GESTURE             = 29,
	MAGNIFY             = 30,
	SWIPE               = 31,
	ROTATE              = 18,
	BEGIN_GESTURE       = 19,
	END_GESTURE         = 20,
	SMART_MAGNIFY       = 32,
	QUICK_LOOK          = 33,
	PRESSURE            = 34,
	DIRECT_TOUCH        = 37,
	CHANGE_MODE         = 38,
}

// DEPRECATED
fn EventType! event_type_from(int val)
{
    switch(val) {
        case EventType.LEFT_MOUSE_DOWN.val:     return LEFT_MOUSE_DOWN;
        case EventType.LEFT_MOUSE_UP.val:       return LEFT_MOUSE_UP;
        case EventType.RIGHT_MOUSE_DOWN.val:    return RIGHT_MOUSE_DOWN;
        case EventType.RIGHT_MOUSE_UP.val:      return RIGHT_MOUSE_UP;
        case EventType.MOUSE_MOVED.val:         return MOUSE_MOVED;
        case EventType.LEFT_MOUSE_DRAGGED.val:  return LEFT_MOUSE_DRAGGED;
        case EventType.RIGHT_MOUSE_DRAGGED.val: return RIGHT_MOUSE_DRAGGED;
        case EventType.MOUSE_ENTERED.val:       return MOUSE_ENTERED;
        case EventType.MOUSE_EXITED.val:        return MOUSE_EXITED;
        case EventType.KEY_DOWN.val:            return KEY_DOWN;
        case EventType.KEY_UP.val:              return KEY_UP;
        case EventType.FLAGS_CHANGED.val:       return FLAGS_CHANGED;
        case EventType.APPKIT_DEFINED.val:      return APPKIT_DEFINED;
        case EventType.SYSTEM_DEFINED.val:      return SYSTEM_DEFINED;
        case EventType.APPLICATION_DEFINED.val: return APPLICATION_DEFINED;
        case EventType.PERIODIC.val:            return PERIODIC;
        case EventType.CURSOR_UPDATE.val:       return CURSOR_UPDATE;
        case EventType.SCROLL_WHEEL.val:        return SCROLL_WHEEL;
        case EventType.TABLET_POINT.val:        return TABLET_POINT;
        case EventType.TABLET_PROXIMITY.val:    return TABLET_PROXIMITY;
        case EventType.OTHER_MOUSE_DOWN.val:    return OTHER_MOUSE_DOWN;
        case EventType.OTHER_MOUSE_UP.val:      return OTHER_MOUSE_UP;
        case EventType.OTHER_MOUSE_DRAGGED.val: return OTHER_MOUSE_DRAGGED;
        case EventType.GESTURE.val:             return GESTURE;
        case EventType.MAGNIFY.val:             return MAGNIFY;
        case EventType.SWIPE.val:               return SWIPE;
        case EventType.ROTATE.val:              return ROTATE;
        case EventType.BEGIN_GESTURE.val:       return BEGIN_GESTURE;
        case EventType.END_GESTURE.val:         return END_GESTURE;
        case EventType.SMART_MAGNIFY.val:       return SMART_MAGNIFY;
        case EventType.QUICK_LOOK.val:          return QUICK_LOOK;
        case EventType.PRESSURE.val:            return PRESSURE;
        case EventType.DIRECT_TOUCH.val:        return DIRECT_TOUCH;
        case EventType.CHANGE_MODE.val:         return CHANGE_MODE;
        default: return ObjcFault.UNKNOWN_EVENT?;
    }
}

// DEPRECATED
enum EventModifierFlag : (int val)
{
	CAPS_LOCK   = 1 << 16,
	SHIFT       = 1 << 17,
	CONTROL     = 1 << 18,
	OPTION      = 1 << 19,
	COMMAND     = 1 << 20,
	NUMERIC_PAD = 1 << 21,
    FUNCTION    = 1 << 23,
	HELP        = 1 << 22,
}

// DEPRECATED
fn String modifier_to_str(int modifier) 
{
    DString result;
	if ((modifier & EventModifierFlag.CAPS_LOCK.val) == EventModifierFlag.CAPS_LOCK.val) result.append(string::tformat("%s", "CapsLock, "));
	if ((modifier & EventModifierFlag.SHIFT.val) == EventModifierFlag.SHIFT.val) result.append(string::tformat("%s", "NShift, "));
	if ((modifier & EventModifierFlag.CONTROL.val) == EventModifierFlag.CONTROL.val) result.append(string::tformat("%s", "Control, "));
	if ((modifier & EventModifierFlag.OPTION.val) == EventModifierFlag.OPTION.val) result.append(string::tformat("%s", "Option, "));
	if ((modifier & EventModifierFlag.COMMAND.val) == EventModifierFlag.COMMAND.val) result.append(string::tformat("%s", "Command, "));
	if ((modifier & EventModifierFlag.NUMERIC_PAD.val) == EventModifierFlag.NUMERIC_PAD.val) result.append(string::tformat("%s", "NumericPad, "));
	if ((modifier & EventModifierFlag.HELP.val) == EventModifierFlag.HELP.val) result.append(string::tformat("%s", "Help, "));
	if ((modifier & EventModifierFlag.FUNCTION.val) == EventModifierFlag.FUNCTION.val) result.append(string::tformat("%s", "Function, "));
    // remove last ", " if present
    return result.len() == 0 ? result.str_view() : result.str_view()[..^3]; 
}

