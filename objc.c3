module objc @if(env::DARWIN);
import std::os::macos::objc;
import std::io;
import std::math;

alias SendBool = fn void*(void*, ObjcSelector, bool);
alias SendContentRec = fn void*(void*, ObjcSelector, NSRect, long, long, bool);
alias SendDequeueEvent = fn void*(void*, ObjcSelector, long, void*, ObjcId, bool);
alias SendDouble = fn void*(void*, ObjcSelector, double);
alias SendEvent = fn void*(void*, ObjcSelector, NSEvent);
alias SendId = fn void*(void*, ObjcSelector, ObjcId);
alias SendIdId = fn void*(void*, ObjcSelector, ObjcId, ObjcId);
alias SendInt = fn void*(void*, ObjcSelector, int);
alias SendPtr = fn void*(void*, ObjcSelector, void*);
alias SendSelector = fn void*(void*, ObjcSelector, ObjcSelector);
alias SendSize = fn void*(void*, ObjcSelector, NSSize);
alias SendString = fn void*(void*, ObjcSelector, ZString);
alias GetInt = fn int(void*, ObjcSelector);
alias GetPoint = fn NSPoint(void*, ObjcSelector);

faultdef IVAR_NOT_SET, IVAR_NOT_FOUND, METHOD_NOT_SET;

struct NSObject {
    ObjcClass cls;
    ObjcId *id;
}

alias NSApplication = NSObject;
alias NSStatusBar = NSObject;
alias NSImage = NSObject;
alias NSMenu = NSObject;
alias NSMenuItem = NSObject;
alias NSString = NSObject;
alias NSWindow = NSObject;
alias NSAutoreleasePool = NSObject;
alias NSValue = NSObject;
alias NSDate = NSObject;
typedef NSEvent = void*;
typedef NSStatusBarItem = void*;

macro NSObject new(ZString cls_name = "NSObject")
{
    NSObject self;
    self.cls = objc::getClass(cls_name);
    return self;
}
// macro NSObject NSObject.new() @operator(construct)
// {
//     NSObject self;
//     self.cls = objc::getClass("NSApplication");
//     return self;
// }

<* @require self.id != null `self is not initialized` *>
macro NSObject.call(&self, $FunctionType, ZString $selector, ...)
{
	return (($FunctionType)&objc::msgSend)((ObjcId)self.id, objc::sel_getUid($selector), $vasplat);
}

macro ObjcId.call(ObjcId self, $FunctionType, ZString $selector, ...)
{
	return (($FunctionType)&objc::msgSend)(self, objc::sel_getUid($selector), $vasplat);
}

fn void NSObject.alloc_class_pair(&self, ZString name, uint extra_bytes)
{
    self.cls = objc::allocateClassPair(self.cls, name, extra_bytes);
}

fn void NSApplication.sharedApplication(&self)
{
    self.id = objc::msg_send(self.cls, SendVoid, "sharedApplication"); 
}

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.setDelegate(&self, NSObject delegate)
{
    objc::msg_send(self.id, SendId, "setDelegate:", delegate.id);
}

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.terminate(&self)
{
    objc::msg_send(self.id, SendId, "terminate:", self.id);
}

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.activateIgnoringOtherApps(&self, bool flag)
{
    objc::msg_send(self.id, SendBool, "activateIgnoringOtherApps:", flag);
}

<* @require self.id != null `NSApplication is not initialized` *>
fn NSEvent NSApplication.nextEventMatchingMask(&self, long mask, NSDate until_date, NSObject in_mode, bool dequeue)
{
    return (NSEvent)objc::msg_send(self.id, SendDequeueEvent, "nextEventMatchingMask:untilDate:inMode:dequeue:", mask, until_date.id, in_mode.id, dequeue);
}

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.finishLaunching(&self)
{
    objc::msg_send(self.id, SendVoid, "finishLaunching");
}

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.updateWindows(&self)
{
    objc::msg_send(self.id, SendVoid, "updateWindows");
}

fn NSPoint NSEvent.locationInWindow(self) => objc::msg_send(self, GetPoint, "locationInWindow");
fn int NSEvent.get_type(self) => objc::msg_send(self, GetInt, "type");
fn int NSEvent.get_modifierFlags(self) => objc::msg_send(self, GetInt, "modifierFlags");

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.sendEvent(&self, NSEvent event)
{
    objc::msg_send(self.id, SendEvent, "sendEvent:", event);
}

<* @require self.id != null `NSApplication is not initialized` *>
fn void NSApplication.setActivationPolicy(&self, ApplicationActivationPolicy policy)
{ 
    objc::msg_send(self.id, SendInt, "setActivationPolicy:", policy.val);
}

fn void NSStatusBar.systemStatusBar(&self)
{
    self.id = objc::msg_send(self.cls, SendVoid, "systemStatusBar");
}

<* @require self.id != null `NSStatusBar is not initialized` *>
macro NSStatusBarItem NSStatusBar.statusItemWithLength(NSStatusBar self, StatusItemLength length)
{
    return (NSStatusBarItem)objc::msg_send(self.id, SendDouble, "statusItemWithLength:", length.val);
}

<* @require img.id != null `NSImage is not initialized` *>
fn void NSStatusBarItem.setImage(self, NSImage img)
{
    objc::msg_send(self, SendId, "setImage:", img.id);
}

<* @require menu.id != null `NSMenu is not initialized` *>
fn void NSStatusBarItem.setMenu(self, NSMenu menu)
{
    objc::msg_send(self, SendId, "setMenu:", menu.id);
}

<* 
    @require self.id != null `NSImage is not allocated` 
    @require str.id != null `NSSTring is not initialized` 
*>
fn void NSImage.initWithContentsOfFile(&self, NSString str)
{
    self.id = objc::msg_send(self.id, SendId, "initWithContentsOfFile:", str.id);
}

<* @require self.id != null `NSImage is not initialized` *>
fn void NSImage.setSize(&self, NSSize size)
{
    objc::msg_send(self.id, SendSize, "setSize:", size);
}

<* @require self.id != null `NSObject is not allocated` *>
fn void NSObject.init(&self)
{
    self.id = objc::msg_send(self.id, SendVoid, "init");
}

<* @require self.id != null `NSMenu is not initialized` *>
fn void NSMenu.setAutoenablesItems(&self, bool flag)
{
    objc::msg_send(self.id, SendBool, "setAutoenablesItems:", flag);
}

<* @require self.id != null `NSMenu is not initialized` *>
fn void NSMenu.addItem(&self, NSMenuItem item)
{
    objc::msg_send(self.id, SendId, "addItem:", item.id);
}

<* @require self.id != null `NSMenu is not initialized` *>
fn void NSMenu.setSubmenu(&self, NSMenu menu, NSMenuItem item)
{
    objc::msg_send(self.id, SendIdId, "setSubmenu:forItem:", menu.id, item.id);
}

fn void NSMenuItem.separatorItem(&self)
{
    self.id = objc::msg_send(self.cls, SendVoid, "separatorItem");
}

<* 
    @require self.id != null `NSMenuItem is not initialized` 
    @require value.id != null `NSValue is not initialized` 
*>
fn void NSMenuItem.setRepresentedObject(&self, NSValue value) {
    objc::msg_send(self.id, SendId, "setRepresentedObject:", value.id);
}

<* @require self.id != null `NSMenuItem is not initialized` *>
fn void NSMenuItem.setState(&self, bool flag)
{
    objc::msg_send(self.id, SendInt, "setState:", flag ? 1 : 0);
}

<* @require self.id != null `NSMenuItem is not initialized` *>
fn void NSMenuItem.setEnabled(&self, bool flag)
{
    objc::msg_send(self.id, SendBool, "setEnabled:", flag);
}

<* 
    @require self.id != null `NSMenuItem is not initialized` 
    @require title.id != null `NSString is not initialized` 
*>
fn void NSMenuItem.setTitle(&self, NSString title)
{
    objc::msg_send(self.id, SendId, "setTitle:", title.id);
}

<* @require self.id != null `NSMenuItem is not initialized` *>
fn void NSMenuItem.setAction(&self, ObjcSelector action)
{
    objc::msg_send(self.id, SendSelector, "setAction:", action);
}

fn void NSValue.valueWithPointer(&self, void* ptr)
{
    self.id = objc::msg_send(self.cls, SendPtr, "valueWithPointer:", ptr);
}

fn void NSString.stringWithUTF8String(&self, ZString str)
{
    self.id = objc::msg_send(self.cls, SendString, "stringWithUTF8String:", str);
}

fn void NSDate.distantFuture(&self)
{
    self.id = objc::msg_send(self.cls, SendVoid, "distantFuture");
}

fn void NSDate.distantPast(&self)
{
    self.id = objc::msg_send(self.cls, SendVoid, "distantPast");
}

<* @require self.id != null `NSWindow is not initialized` *>
fn void NSWindow.initWithContentRect(&self, NSRect rect, ulong style_mask, ulong backing, bool is_defer)
{
    self.id = objc::msg_send(self.id, SendContentRec, "initWithContentRect:styleMask:backing:defer:", rect, style_mask, backing, is_defer);
}

<* @require self.id != null `NSWindow is not initialized` *>
fn void NSWindow.makeKeyAndOrderFront(&self, ObjcSelector sel)
{
    objc::msg_send(self.id, SendSelector, "makeKeyAndOrderFront:", sel);
}

<* @require self.id != null `NSWindow is not initialized` *>
fn void NSWindow.setIsVisible(&self, bool flag)
{
    objc::msg_send(self.id, SendBool, "setIsVisible:", flag);
}

fn void NSObject.alloc(&self)
{
    self.id = objc::msg_send(self.cls, SendVoid, "alloc");
}

<* @require self.id != null `NSObject is not allocated` *>
fn void NSObject.release(&self)
{
    objc::msg_send(self.id, SendVoid, "release");
}

<* @require self.id == null `NSObject is already initialized` *>
macro NSObject? NSObject.add_method(NSObject self, ZString name, void* imp, ZString types = "")
{
    if(!objc::class_addMethod(self.cls, objc::sel_registerName(name), imp, types)) return METHOD_NOT_SET?;
    return self;
}

macro ObjcClass? ObjcClass.add_method(ObjcClass self, ZString name, void* imp, ZString types = "") 
{
    if(!objc::class_addMethod(self, register_name(name), imp, types)) return METHOD_NOT_SET?;
    return self;
}

macro NSObject? NSObject.add_ivar(NSObject self, ZString name, int size, double alignment, ZString types) 
{
    if(!objc::class_addIvar(self.cls, name, size, alignment, types)) return IVAR_NOT_SET?;
    return self;
}

macro ObjcIvar? ObjcId.get_ivar(ObjcId self, ZString name)
{
    ObjcIvar out;
    if(!objc::getInstanceVariable(self, name, &out)) return IVAR_NOT_FOUND?; 
    return out;
}

<* @require self.id != null `NSObject is not initialized` *>
macro void NSObject.setInstanceVariable(NSObject self, ZString name, NSObject out)
{
    objc::setInstanceVariable(self.id, name, out.id);
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

