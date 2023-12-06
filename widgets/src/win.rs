use mlua::prelude::*;
use once_cell::sync::Lazy;
use xcb::x;
struct Win {
    window: xcb::x::Window,
}
struct Context {
    connection: xcb::Connection,
    screen_num: i32,
}

impl Context {
    fn new() -> Context {
        let (conn, screen_num) = xcb::Connection::connect(None).unwrap();
        println!("create context");
        Context {
            connection: conn,
            screen_num,
        }
    }
}

static CONTEXT: Lazy<Context> = Lazy::new(|| Context::new());

impl LuaUserData for Win {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        let _ = fields;
    }

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("show", |_, this, ()| {
            CONTEXT.connection.send_request(&x::MapWindow {
                window: this.window,
            });
            CONTEXT.connection.flush().unwrap();
            println!("show");
            Ok(())
        })
    }
}

impl Win {
    fn new() -> Win {
        let conn = &CONTEXT.connection;
        let screen_num = CONTEXT.screen_num;
        let setup = conn.get_setup();
        let screen = setup.roots().nth(screen_num as usize).unwrap();
        let window: xcb::x::Window = conn.generate_id();
        conn.send_request(&xcb::x::CreateWindow {
            depth: x::COPY_FROM_PARENT as u8,
            wid: window,
            parent: screen.root(),
            x: 0,
            y: 0,
            width: 350,
            height: 350,
            border_width: 10,
            class: x::WindowClass::InputOutput,
            visual: screen.root_visual(),
            value_list: &[
                x::Cw::BackPixel(screen.white_pixel()),
                x::Cw::EventMask(x::EventMask::EXPOSURE | x::EventMask::KEY_PRESS),
            ],
        });
        Win { window }
    }
}
fn new(_: &Lua, _: ()) -> LuaResult<Win> {
    Ok(Win::new())
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("new", lua.create_function(new)?)?;
    Ok(exports)
}
