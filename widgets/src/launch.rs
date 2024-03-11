use gtk4::gio::prelude::*;
use gtk4::gio::DesktopAppInfo;
use mlua::prelude::*;
use gtk4::prelude::*;
fn launch_desktop_file(str: String) {
    let app = DesktopAppInfo::from_filename(str.as_str());
    if let Some(app) = app {
        let ctx = gtk4::gdk::Display::default().unwrap().app_launch_context();
        app.launch(&[], Some(&ctx))
            .expect(format!("Unable to launch {}", str).as_str());
    } else {
        println!("Does this file exist: {}", str);
    }
}
pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set("launch_desktop_file",
              lua.create_function(|_,path:String|{
                  launch_desktop_file(path);
                  Ok(())
              })?)?;
    Ok(table)
}
