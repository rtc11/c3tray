import std::os::macos::objc, objc;
import std::io, std::collections::list;

def Callback = fn void(Menu *item);

struct Tray {
    ZString icon;
    Menu*[] menu;
}

struct Menu {
    Menu*[] sub_menu;
    ZString text;
    bool disabled;
    bool checked;
    bool checkbox;
    Callback cb;
}

const ZString ICON_GREEN = "circle_green.png";
const ZString ICON_RED = "circle_red.png";
Tray tray;
NSApplication app;
NSStatusBarItem status_item;
bool running = true;

fn void menu_callback(ObjcId self, ObjcSelector sel, ObjcId sender)
{
    ObjcId representedObject = sender.call(SendVoid, "representedObject");
    ObjcId pointerValue = representedObject.call(SendVoid, "pointerValue");
    ZString title = (ZString)(char*) sender.call(SendVoid, "title").call(SendVoid, "UTF8String");
    if(pointerValue) {
        Menu* menu = (Menu*) pointerValue;
        if(menu.cb) {
            menu.cb(menu);
        }
    }
}

fn bool Tray.setup(&self)
{
    app = NSApplication{ .cls = objc::getClass("NSApplication") }; // TODO: change to NSApplication.new();
    app.sharedApplication();
    app.activateIgnoringOtherApps(true);

    NSObject delegate = NSObject { .cls = objc::getClass("NSObject") };
    delegate.alloc_class_pair("AppDelegate", 0);
    delegate.add_method("menuCallback:", &menu_callback, "V@:@")!!;
    delegate = objc::alloc(delegate);
    delegate.init();
    app.setDelegate(delegate);

    NSStatusBar status_bar = NSStatusBar{ .cls = objc::getClass("NSStatusBar") };
    status_bar.systemStatusBar(); 
    status_item = status_bar.statusItemWithLength(StatusItemLength.VARIABLE);
    self.update();
    return true;
}

fn void Tray.update(&self)
{
    NSString icon_str = NSString { .cls = objc::getClass("NSString")};
    icon_str.stringWithUTF8String(self.icon);
    NSImage img = NSImage { .cls = objc::getClass("NSImage") };
    img = objc::alloc(img);
    img.initWithContentsOfFile(icon_str);
    img.setSize(NSSize {16, 16});
    status_item.setImage(img); // deprecated
    status_item.setMenu(ns_menu(self.menu));
}

fn bool Tray.loop(&self, bool blocking = true)
{
    NSDate date = NSDate { .cls = objc::getClass("NSDate")}; 
    blocking ? date.distantFuture() : date.distantPast();
    NSString loop = NSString { .cls = objc::getClass("NSString") };
    loop.stringWithUTF8String("kCFRunLoopDefaultMode");
    NSEvent event = app.nextEventMatchingMask(long.max, date, loop, true);
    if (event) {
        app.sendEvent(event);
    }

    return true;
}

fn NSMenu ns_menu(Menu*[] ms)
{
    DString indent;
    NSMenu menu = NSMenu { .cls = objc::getClass("NSMenu") };
    menu = objc::alloc(menu);
    menu.init();
    menu.setAutoenablesItems(false);

    foreach(m: ms) {
        if (m.text.str_view() == "-") {
            NSMenuItem separator = NSMenuItem { .cls = objc::getClass("NSMenuItem")};
            separator.separatorItem();
            menu.addItem(separator);
        } else { 
            NSString title = NSString { .cls = objc::getClass("NSString")};
            title.stringWithUTF8String(m.text);
            NSMenuItem menu_item = NSMenuItem { .cls = objc::getClass("NSMenuItem")};
            menu_item = objc::alloc(menu_item);
            menu_item.init();
            menu_item.setTitle(title);
            menu_item.setAction(objc::sel_registerName("menuCallback:"));
            menu_item.setEnabled(!m.disabled);
            menu_item.setState(m.checked);
            NSValue value = NSValue { .cls = objc::getClass("NSValue")};
            value.valueWithPointer(m);
            menu_item.setRepresentedObject(value);
            menu.addItem(menu_item);
            if (m.sub_menu) {
                menu.setSubmenu(ns_menu(m.sub_menu), menu_item);
            }
        }
    }
    return menu;
}

fn void cb_icon(Menu *item)
{
    if (tray.icon == ICON_RED) {
        tray.icon = ICON_GREEN;
    } else {
        tray.icon = ICON_RED;
    }
    tray.update();
}

fn void cb_toggle(Menu *item)
{
    item.checked = !item.checked;
    tray.update();
}

fn void cb_quit(Menu *item)
{
    running = false;
    app.terminate();
    foreach(ptr: ptrs) {
        (void)free(ptr);
    }
}

fn void cb_sub_menu(Menu *item)
{
    io::printn("sub menu");
    tray.update();
}

List(<void*>) ptrs;
fn Menu* save(Menu* ptr) {
    ptrs.push(ptr);
    return ptr;
}

fn void main()
{
    @pool() {
        Menu* separator = save(mem::new(Menu, { .text = "-" }));
        tray = Tray {
            .icon = ICON_GREEN,
            .menu = Menu*[] { 
                save(mem::new(Menu, { .text = "Change icon", .cb = &cb_icon })),
                save(mem::new(Menu, { .text = "Checked", .checked = true, .cb = &cb_toggle })),
                save(mem::new(Menu, { .text = "Disabled", .disabled = true })),
                separator,
                save(mem::new(Menu, { .text = "SubMenu", .sub_menu = Menu*[]{ 
                    save(mem::new(Menu, { .text = "First", .checked = true, .cb = &cb_toggle })),
                    save(mem::new(Menu, { .text = "Second", .sub_menu = Menu*[]{ 
                        save(mem::new(Menu, { .text = "7", .cb = &cb_sub_menu })),
                        save(mem::new(Menu, { .text = "8", .cb = &cb_sub_menu })),
                    }})),
                    save(mem::new(Menu, { .text = "Fourth", .sub_menu = Menu*[]{ 
                        save(mem::new(Menu, { .text = "5", .cb = &cb_sub_menu })),
                        save(mem::new(Menu, { .text = "6", .cb = &cb_sub_menu })),
                    }})),
                }})),
                separator,
                save(mem::new(Menu, { .text = "Quit", .cb = &cb_quit })),
            }
        };

        tray.setup();
        while (tray.loop() && running) {
            // do stuff
        };
    };
}

