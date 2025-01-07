import std::os::macos::objc, objc;
import std::io;
import std::math;

bool running = true;

fn void main()
{
    NSObject object = NSObject{ .cls = objc::getClass("NSObject") }; 
    object.add_method("windowShouldClose:", &on_close)!!;

    NSApplication app = NSApplication { .cls = objc::getClass("NSApplication") };
    app.sharedApplication();
    app.setActivationPolicy(ApplicationActivationPolicy.REGULAR);

    NSWindow win = NSWindow { .cls = objc::getClass("NSWindow") };
    win = objc::alloc(win);
    ulong window_style = WindowStyleMask.CLOSABLE.val | WindowStyleMask.MINIATURIZABLE.val | BackingStore.BUFFERED.val | WindowStyleMask.TITLED.val | WindowStyleMask.RESIZABLE.val;
    win.initWithContentRect(NSRect {{200.0, 200.0}, {200.0, 200.0}}, window_style, window_style, false);

    NSObject delegate = NSObject { .cls = objc::getClass("NSObject") };
    delegate.alloc_class_pair("WindowDelegate", 0);
    delegate.add_ivar("NSWindow", $sizeof(win), math::log2($sizeof(win)), "L")!!;
    delegate.add_method("windowWillResize:toSize:", &resize_window, "{NSSize=ff}@:{NSSize=ff}")!!;
    delegate = objc::alloc(delegate);
    delegate.init();
    delegate.setInstanceVariable("NSWindow", win);
    win.setDelegate(delegate);
    win.makeKeyAndOrderFront(null);
    win.setIsVisible(true);
    app.activateIgnoringOtherApps(true);
    app.finishLaunching();

    while(running) {
        NSAutoreleasePool pool = NSAutoreleasePool { .cls = objc::getClass("NSAutoreleasePool") }; 
        pool = objc::alloc(pool);
        pool.init();

        NSString loop = NSString { .cls = objc::getClass("NSString") };
        loop.stringWithUTF8String("kCFRunLoopDefaultMode");

        NSEvent event = app.nextEventMatchingMask(long.max, null, loop, true);
        int type = event.get_type();
        NSPoint pos = event.locationInWindow();

        if (type != 0) {
			io::printfn("Event [type=%s location={%d, %d} modifierFlags={%s}]", 
                objc::event_type_from(type)!!, 
                pos.x, pos.y, 
                objc::modifier_to_str(event.get_modifierFlags()));
        }

        win.sendEvent(event);
        app.updateWindows();
        objc::release(pool);
    }
}

fn bool on_close(ObjcId self)
{
    io::printn("closing window..");
    if (catch self.get_ivar("NSWindow")) return true;
    running = false;
    return true;
}

fn NSSize resize_window(ObjcId self, NSSize frame)
{
    if (catch self.get_ivar("NSWindow")) return frame;
	io::printfn("window resized to %f %f", frame.width, frame.height);
    return frame;
}

