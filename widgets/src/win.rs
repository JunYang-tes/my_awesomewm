use std::{cell::RefCell, sync::Arc};

use cairo::*;
use mlua::prelude::*;
use once_cell::sync::Lazy;
use xcb::x;
struct Win {
    window: xcb::x::Window,
    root: RefCell<Option<std::rc::Rc<crate::widgets::Node>>>,
}
struct Context {
    connection: std::sync::Arc<xcb::Connection>,
    screen_num: i32,
    event_loop: std::thread::JoinHandle<()>,
}

impl Context {
    fn new() -> Context {
        let (conn, screen_num) = xcb::Connection::connect(None).unwrap();
        let connection = Arc::new(conn);
        let conn = connection.clone();
        println!("create context");

        let event_loop = std::thread::spawn(move || {
            println!("Event loop started");
            let setup = conn.get_setup();
            let screen = setup.roots().nth(screen_num as usize).unwrap();
            loop {
                let event = match conn.wait_for_event() {
                    Ok(event) => event,
                    Err(_) => {
                        return;
                    }
                };
                match event {
                    xcb::Event::X(x::Event::Expose(e)) => {
                        let visual = find_visual(&conn, screen.root_visual()).unwrap();
                        unsafe {
                            let raw_conn = conn.get_raw_conn();
                            let xcb_conn =
                                XCBConnection::from_raw_full(std::mem::transmute(raw_conn));
                            let drawable = XCBDrawable(xcb::Xid::resource_id(&e.window()));
                            let xcb_visual =
                                XCBVisualType::from_raw_full(std::mem::transmute(&visual));
                            draw_on_win(&xcb_conn, &drawable, &xcb_visual, 150, 150).unwrap();
                            conn.flush().unwrap();
                        }
                        println!("Expose")
                    }
                    _ => {}
                }
            }
        });
        Context {
            connection,
            screen_num,
            event_loop,
        }
    }
}

static CONTEXT: Lazy<Context> = Lazy::new(|| Context::new());

fn find_visual<'a>(
    conn: &'a xcb::Connection,
    visual: xcb::x::Visualid,
) -> Option<xcb::x::Visualtype> {
    let setup = conn.get_setup();
    for screen in setup.roots() {
        let d_iter = screen.allowed_depths();
        for depth in d_iter {
            for vis in depth.visuals() {
                if visual == vis.visual_id() {
                    println!("Found visual");
                    return Some((*vis).clone());
                }
            }
        }
    }
    None
}
fn draw_on_win(
    conn: &XCBConnection,
    drawable: &XCBDrawable,
    visual: &XCBVisualType,
    width: i32,
    height: i32,
) -> Result<()> {
    let surface = cairo::XCBSurface::create(conn, drawable, visual, width, height)?;
    let cr = cairo::Context::new(&surface)?;
    cr.set_source_rgb(0.0, 1.0, 0.0);
    cr.move_to(0.0, 0.0);
    cr.line_to(100.0, 100.0);
    cr.stroke()?;
    surface.flush();
    //cr.paint()?;
    println!("DONE");
    Ok(())
}

impl LuaUserData for Win {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        let _ = fields;
    }

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("set_root", |_, this, value: LuaValue| match value {
            LuaValue::UserData(node) => {
                let root: std::rc::Rc<crate::widgets::Node> =
                    std::rc::Rc::clone(&node.borrow().unwrap());
                let _ = this.root.borrow_mut().insert(root);
                Ok(())
            }
            _ => panic!(""),
        });
        methods.add_method("check", |_, this, _: ()| {
            println!("Is some:{}", this.root.borrow().is_some());
            this.root.borrow().as_ref().map(|root| {
                println!("Count:{}", std::rc::Rc::strong_count(&root));
            });
            Ok(())
        });
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
        Win {
            window,
            root: None.into(),
        }
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
