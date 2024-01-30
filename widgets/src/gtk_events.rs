use mlua::prelude::*;
use crate::lua_module::*;
AddMethods!(gtk::gdk::EventKey,methods=>{
    Getter!(methods,time,is_modifier);
    Getter!(methods, keyval i => LuaWrapper(i));
    Getter!(methods, state i => i.bits() as u32);
});
AddMethods!(gtk::gdk::keys::Key,methods => {
    Getter!(methods,
            name i=>i.map(|s|String::from(s.as_str())),
            to_unicode i=>i.map(|c|c as i32));
    Getter!(methods,is_upper,is_lower);
});
AddMethods!(gtk::gdk::EventButton,methods => {
    Getter!(methods,
            time,
            button,
            root,
            position);
    Getter!(methods, state i => i.bits() as u32);

});
