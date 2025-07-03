import std::os::macos::objc, objc;
import std::io;
import std::math;

bool running = true;

fn void main()
{
    NSObject object = objc::new("NSObject"); 
    object.add_method("windowShouldClose:", &on_close)!!;

    NSApplication app = { .cls = objc::getClass("NSApplication") };
    app.sharedApplication();
    app.setActivationPolicy(ApplicationActivationPolicy.REGULAR);

    NSWindow win = objc::new("NSWindow");
    win.alloc();
    ulong window_style = WindowStyleMask.CLOSABLE.val | WindowStyleMask.MINIATURIZABLE.val | BackingStore.BUFFERED.val | WindowStyleMask.TITLED.val | WindowStyleMask.RESIZABLE.val;
    win.initWithContentRect({{200.0, 200.0}, {200.0, 200.0}}, window_style, window_style, false);

    NSObject delegate = objc::new("NSObject");
    delegate.alloc_class_pair("WindowDelegate", 0);
    delegate.add_ivar("NSWindow", $sizeof(win), math::log2($sizeof(win)), "L")!!;
    delegate.add_method("windowWillResize:toSize:", &resize_window, "{NSSize=ff}@:{NSSize=ff}")!!;
    delegate.alloc();
    delegate.init();
    delegate.setInstanceVariable("NSWindow", win);
    win.setDelegate(delegate);
    win.makeKeyAndOrderFront(null);
    win.setIsVisible(true);
    app.activateIgnoringOtherApps(true);
    app.finishLaunching();

    while(running) {
        NSAutoreleasePool pool = objc::new("NSAutoreleasePool"); 
        pool.alloc();
        pool.init();

        NSString loop = objc::new("NSString");
        loop.stringWithUTF8String("kCFRunLoopDefaultMode");

        NSDate until; 
        // NSDate until = objc::new("NSDate"); 
        // until.distantFuture();
        NSEvent event = app.nextEventMatchingMask(long.max, until, loop, true);
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
        pool.release();
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

