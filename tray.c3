import std::os::macos::objc, objc;
import std::io;

def Callback = fn void(Menu *item);
def SendSize = fn void*(void*, ObjcSelector, Size);
def SendIdId = fn void*(void*, ObjcSelector, ObjcId, ObjcId);

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
    Menu[] *sub_menu;
}

const ZString TRAY_ICON = "icon.png";
ObjcId status_item;
ObjcId app;

fn void menu_callback(ObjcId self, ObjcSelector sel, ObjcId sender)
{
    ObjcId representedObject = objc::msg_send(sender, SendVoid, "representedObject");
    ObjcId pointerValue = objc::msg_send(representedObject, SendVoid, "pointerValue");
    ZString title = (ZString)(char*) objc::msg_send(objc::msg_send(sender, SendVoid, "title"), SendVoid, "UTF8String");

    if(pointerValue) {
        Menu* menu = (Menu*) pointerValue;
        io::printfn("%s [disabled:%d, checked:%d, checkbox:%d, cb:%s, sub_menu:%s]", title, menu.disabled, menu.checked, menu.checkbox, menu.cb, menu.sub_menu);
        menu.cb(menu);
    }
}

fn bool Tray.init(&self)
{
    ObjcClass delegate_cls = objc::allocateClassPair(objc::getClass("NSObject"), "AppDelegate", 0);
    objc::class_addMethod(delegate_cls , objc::sel_registerName("menuCallback:"), &menu_callback, "V@:@");
    ObjcId delegate = objc::msg_send(objc::alloc(delegate_cls), SendVoid, "init");

    app = objc::msg_send(objc::getClass("NSApplication"), SendVoid, "sharedApplication");
    objc::msg_send(app, SendId, "setDelegate:", delegate);

    ObjcId status_bar = objc::msg_send(objc::getClass("NSStatusBar"), SendVoid, "systemStatusBar");
    status_item = objc::msg_send(status_bar, SendDouble, "statusItemWithLength:", StatusItemLength.VARIABLE.val);
    self.update();
    objc::msg_send(app, SendBool, "activateIgnoringOtherApps:", true);
    return true;
}

fn void Tray.update(&self)
{
    ObjcId ns_str = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", self.icon);
    ObjcId img = objc::msg_send(objc::alloc(objc::getClass("NSImage")), SendId, "initWithContentsOfFile:", ns_str);
    objc::msg_send(img, SendSize, "setSize:", Size {16, 16});
    objc::msg_send(status_item, SendId, "setImage:", img); // deprecated
    objc::msg_send(status_item, SendId, "setMenu:", ns_menu(self.menu));
}

fn bool Tray.loop(&self)
{
    ObjcId loop = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", "kCFRunLoopDefaultMode");
    ObjcClass* event = objc::msg_send(app, SendDequeueEvent, "nextEventMatchingMask:untilDate:inMode:dequeue:", long.max, null, loop, true);
    objc::msg_send(app, SendId, "sendEvent:", event);

    // int type = objc::msg_send(event, GetInt, "type");
    // if (type != 0) io::printfn("Event [type=%s]", objc::event_type_from(type)!!);

    return true;
}

fn ObjcId ns_menu(Menu[] ms)
{
    DString indent;
    ObjcId menu = objc::msg_send(objc::alloc(objc::getClass("NSMenu")), SendVoid, "init");
    objc::msg_send(menu, SendBool, "setAutoenablesItems:", false);

    foreach(m: ms) {
        if (m.text.str_view() == "-") {
            ObjcId separator = objc::msg_send(objc::getClass("NSMenuItem"), SendVoid, "separatorItem");
            objc::msg_send(menu, SendId, "addItem:", separator);
        } else { 
            ObjcClass menu_item_cls = objc::getClass("NSMenuItem");
            ObjcId title = objc::msg_send(objc::getClass("NSString"), SendString, "stringWithUTF8String:", m.text);
            ObjcId menu_item = objc::msg_send(objc::alloc(menu_item_cls), SendVoid, "init");
            objc::msg_send(menu_item, SendId, "setTitle:", title);
            objc::msg_send(menu_item, SendSelector, "setAction:", objc::sel_registerName("menuCallback:"));
            objc::msg_send(menu_item, SendBool, "setEnabled:", !m.disabled);
            objc::msg_send(menu_item, SendInt, "setState:", m.checked ? 1 : 0);
            ObjcId value = objc::msg_send(objc::getClass("NSValue"), SendPtr, "valueWithPointer:", &m);
            objc::msg_send(menu_item, SendId, "setRepresentedObject:", value);
            objc::msg_send(menu, SendId, "addItem:", menu_item);
            if (m.sub_menu) {
                objc::msg_send(menu, SendIdId, "setSubmenu:forItem:", ns_menu(*m.sub_menu), menu_item);
            }
        }
    }
    return menu;
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
    objc::msg_send(app, SendId, "terminate", app);
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
        while(tray.loop());
    };
}

