import std::os::macos::objc, objc;
import std::io;
import std::math;

bool running = true;

fn void main()
{
    objc::class_addMethod(objc::getClass("NSObject"), objc::sel_registerName("windowShouldClose:"), &on_close, "");
    ObjcClass* app = objc::msg_send(objc::getClass("NSApplication"), SendVoid, "sharedApplication");
    objc::msg_send(app, SendInt, "setActivationPolicy:", ApplicationActivationPolicy.REGULAR.val);  
    ulong macArgs = WindowStyleMask.CLOSABLE.val | WindowStyleMask.MINIATURIZABLE.val | BackingStore.BUFFERED.val | WindowStyleMask.TITLED.val | WindowStyleMask.RESIZABLE.val;
    ObjcClass* win = objc::msg_send(objc::alloc(objc::getClass("NSWindow")), SendContentRec, "initWithContentRect:styleMask:backing:defer:", Rect {{200.0, 200.0}, {200.0, 200.0}}, macArgs, macArgs, false);
    ObjcClass delegate_cls = objc::allocateClassPair(objc::getClass("NSObject"), "WindowDelegate", 0);
    objc::class_addIvar(delegate_cls, "NSWindow", $sizeof(win), math::log2($sizeof(win)), "L");
    objc::class_addMethod(delegate_cls, objc::sel_registerName("windowWillResize:toSize:"), &resize_window, "{NSSize=ff}@:{NSSize=ff}");
    ObjcId delegate = objc::msg_send(objc::alloc(delegate_cls), SendVoid, "init");
    objc::object_setInstanceVariable(delegate, "NSWindow", win);
    objc::msg_send(win, SendId, "setDelegate:", delegate);
    objc::msg_send(app, SendBool, "activateIgnoringOtherApps:", true);
    objc::msg_send(win, SendSelector, "makeKeyAndOrderFront:", null);
    objc::msg_send(win, SendBool, "setIsVisible:", true);
    objc::msg_send(app, SendVoid, "finishLaunching");

    while(running) {
        ObjcId pool = objc::msg_send(objc::alloc(objc::getClass("NSAutoreleasePool")), SendVoid, "init");
        ObjcId loop = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", "kCFRunLoopDefaultMode");
        ObjcClass* e = objc::msg_send(app, SendDequeueEvent, "nextEventMatchingMask:untilDate:inMode:dequeue:", long.max, null, loop, true);
        int type = objc::msg_send(e, GetInt, "type");
        Point p = objc::msg_send(e, GetPoint, "locationInWindow");

        if (type != 0) {
			io::printfn("Event [type=%s location={%d, %d} modifierFlags={%s}]", 
                objc::event_type_from(type)!!, 
                p.x, p.y, 
                objc::modifier_to_str(objc::msg_send(e, GetInt, "modifierFlags")));
        }

        objc::msg_send(win, SendId, "sendEvent:", e);
        objc::msg_send(app, SendVoid, "updateWindows");
        objc::msg_send(pool, SendVoid, "release"); 
    }
}

fn bool on_close(void* self)
{
    io::printn("closing window..");
    ObjcClass* win;
    objc::object_getInstanceVariable(self, "NSWindow", &win);
    if (win == null) return true;
    running = false;
    return true;
}

fn Size resize_window(void* self, Size frame)
{
    ObjcClass* win;
    objc::object_getInstanceVariable(self, "NSWindow", &win);
    if (win == null) return frame;
	io::printfn("window resized to %f %f", frame.width, frame.height);
    return frame;
}

