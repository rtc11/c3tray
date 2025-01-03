import std::os::macos::objc, objc;
import std::io;

def Callback = fn void(Menu *item);
def SendSize = fn void*(void*, ObjcSelector, Size);
def SendInitWithTitle = fn void*(void*, ObjcSelector, ObjcId title, ObjcSelector action, ZString keyEquivalent);
def Getd = fn ObjcId(void*, ObjcSelector);

struct Tray {
    ZString icon;
    Menu[] menu;
}

struct Menu {
    ZString text;
    bool disabled;
    bool checked;
    bool checkbox;
    Callback cb;
    void *context;
    Menu[] *sub_menu;
}

const ZString TRAY_ICON = "icon.png";
ObjcId status_item;
ObjcId app;

fn ObjcId ns_menu(Menu[] ms)
{
    ObjcId menu = objc::msg_send(objc::alloc(objc::getClass("NSMenu")), SendVoid, "init");
    objc::msg_send(menu, SendBool, "setAutoenablesItems:", false);
    foreach(m: ms) {
        if (m.text == "-") {
            ObjcId separator;
            objc::object_getIVar(menu, "separatorItem", &separator);
            objc::msg_send(menu, SendId, "addItem:", separator);
        } else {
            ObjcSelector menu_cb = objc::sel_registerName("menuCallback:");
            ObjcClass menu_item_cls = objc::getClass("NSMenuItem");
            objc::class_addMethod(menu_item_cls, menu_cb, &m.cb, ""); // is this how we use the callbacks?
            ObjcId menu_item = objc::msg_send(objc::alloc(menu_item_cls), SendVoid, "init");
            ObjcId title = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", m.text);
            objc::msg_send(menu_item, SendId, "title:", title);
            objc::msg_send(menu_item, SendSelector, "action:", menu_cb);
            objc::msg_send(menu_item, SendBool, "setEnabled:", m.disabled);
            objc::msg_send(menu_item, SendInt, "setState:", m.checked ? 1 : 0);
            ObjcId value = objc::msg_send(objc::getClass("NSValue"), SendPtr, "valueWithPointer:", &m);
            objc::msg_send(menu_item, SendId, "setRepresentedObject:", value);
            objc::msg_send(menu, SendId, "addItem:", menu_item);
            if (m.sub_menu) {
                objc::msg_send(menu, SendId, "setSubmenu:", ns_menu(*m.sub_menu));
            }
        }
    }
    return menu;
}

// todo: why is the tray icon not showing?
fn bool Tray.init(&self)
{
    ObjcClass app_delegate = objc::allocateClassPair(objc::getClass("NSObject"), "AppDelegate", 0);
    ObjcId delegate = objc::msg_send(objc::alloc(app_delegate), SendVoid, "init");
    /*
        todo: how to do this in c3

        @interface AppDelegate: NSObject <NSApplicationDelegate>
            - (IBAction)menuCallback:(id)sender;
        @end
        @implementation AppDelegate{}
            - (IBAction)menuCallback:(id)sender
            {
                struct tray_menu *m = [[sender representedObject] pointerValue];
                if (m != NULL && m->cb != NULL) {
                    m->cb(m);
                }
            }
        @end
    */

    app = objc::msg_send(objc::getClass("NSApplication"), SendVoid, "sharedApplication");
    objc::msg_send(app, SendId, "setDelegate:", delegate);

    ObjcId status_bar = objc::msg_send(objc::getClass("NSStatusBar"), SendVoid, "systemStatusBar");
    status_item = objc::msg_send(status_bar, SendDouble, "statusItemWithLength:", StatusItemLength.VARIABLE.val);
    self.update();
    objc::msg_send(app, SendBool, "activateIgnoringOtherApps:", true);
    return true;
}

fn bool Tray.loop(&self)
{
    ObjcId loop = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", "kCFRunLoopDefaultMode");
    ObjcClass* event = objc::msg_send(app, SendDequeueEvent, "nextEventMatchingMask:untilDate:inMode:dequeue:", long.max, null, loop, true);
    objc::msg_send(app, SendId, "sendEvent:", event);
    int type = objc::msg_send(event, GetInt, "type");

    if (type != 0) {
        io::printfn("Event [type=%s]", objc::event_type_from(type)!!);
    }

    return true; // true
}

fn void Tray.update(&self)
{
    ObjcId img_init = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", self.icon);
    ObjcId img = objc::msg_send(objc::alloc(objc::getClass("NSImage")), SendId, "initWithContentsOfFile:", img_init);
    objc::msg_send(img, SendSize, "setSize:", Size {16, 16});
    ObjcClass button;
    objc::object_getIVar(status_item, "button", &button);
    objc::object_setIVar(&button, "image", img);
    objc::object_setIVar(status_item, "button", &button);
    // objc::msg_send(status_item, SendId, "setMenu:", ns_menu(self.menu));

}

fn void Tray.exit(&self)
{
    objc::msg_send(app, SendId, "terminate", app);
}

fn void cb_hello(Menu *item)
{
    io::printfn("hello callback");
    tray.icon = TRAY_ICON;
    tray.update();
}

fn void cb_toggle(Menu *item)
{
    io::printfn("toggle callback");
    item.checked = !item.checked;
    tray.update();
}

fn void cb_quit(Menu *item)
{
    io::printfn("quit callback");
    tray.exit();
}

fn void cb_sub_menu(Menu *item)
{
    io::printfn("sub menu clicked on %s", item.text);
    tray.update();
}

Tray tray = {
    .icon = TRAY_ICON,
    .menu = Menu[] {
        { .text = "Status", .cb = &cb_hello },
        { .text = "Checked", .checked = true, .cb = &cb_toggle },
        { .text = "Disabled", .disabled = true },
        { .text = "-" },
        { .text = "SubMenu", .sub_menu = &&Menu[] {
            { .text = "First", .checked = true, .cb = &cb_sub_menu },
            { .text = "Second", .sub_menu = &&Menu[] {
                { .text = "Third", .sub_menu = &&Menu[] {
                    { .text = "7", .cb = &cb_sub_menu },
                    { .text = "-" },
                    { .text = "8", .cb = &cb_sub_menu },
                    // { .text = null },
                }},
                { .text = "Fourth", .sub_menu = &&Menu[] {
                    { .text = "5", .cb = &cb_sub_menu },
                    { .text = "6", .cb = &cb_sub_menu },
                    // { .text = null },
                }},
                // { .text = null },
            }}
        }},
        { .text = "-" },
        { .text = "Quit", .cb = &cb_quit },
        // { .text = null },
    }
};

fn void main()
{
    @pool() {
        tray.init();
        while(tray.loop()) {
            // io::printfn("iter");
        }
    };
}

