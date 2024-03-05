use crate::lua_module::*;
use mlua::prelude::*;
AddMethods!(gtk4::CssProvider,methods=>{});

fn load_css(css: &str) -> gtk4::CssProvider {
    let provider = gtk4::CssProvider::new();
    provider.load_from_string(css);
    gtk4::style_context_add_provider_for_display(
        &gtk4::gdk::Display::default().expect("Could not connect to a display"),
        &provider,
        gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
    );
    provider.connect_parsing_error(|_,css_section,err|{
        println!("Css parsing error: {:?} {:?}",css_section,err);
    });

    provider
}
fn remove_css_provider(provider: &gtk4::CssProvider) {
    gtk4::style_context_remove_provider_for_display(
        &gtk4::gdk::Display::default().expect("Could not connect to a display"),
        provider,
    );
}
pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "load_css",
        lua.create_function(|_, str: String| Ok(LuaWrapper(load_css(str.as_str()))))?,
    )?;
    table.set(
        "remove_css_provider",
        lua.create_function(|_, value: LuaValue| {
            match value {
                LuaValue::UserData(data) => {
                    let provider = data.borrow::<LuaWrapper<gtk4::CssProvider>>().unwrap();
                    remove_css_provider(&provider.0);
                }
                _ => {
                    panic!("Expect LuaWrapper<CssProvider>")
                }
            }
            Ok(())
        })?,
    )?;
    Ok(table)
}
