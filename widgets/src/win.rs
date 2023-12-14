use std::ops::{Deref, DerefMut};
use std::thread::JoinHandle;
use std::{cell::RefCell, rc::Rc, sync::Arc, sync::Mutex};

use crate::widgets::*;
use cairo::*;
use mlua::prelude::*;
use once_cell::sync::Lazy;
use xcb::x;
struct Win {
    window: xcb::x::Window,
    drawable: XCBDrawable,
    surface: XCBSurface,
    connection: Arc<xcb::Connection>,
    cairo_context: cairo::Context,
    root: Option<Rc<RefCell<Root>>>,
    event_loop: Option<JoinHandle<()>>,
}
unsafe impl Sync for Win {}
unsafe impl Send for Win {}
struct MutexWin(Mutex<Win>);
impl Deref for MutexWin {
    type Target = Mutex<Win>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

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

impl LuaUserData for MutexWin {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        let _ = fields;
    }

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("set_root", |_, mutex_win, value: LuaValue| {
            println!("set_root {:?}", value);
            let mut this = mutex_win.lock().unwrap();
            match value {
                LuaValue::UserData(node) => {
                    println!("UserData {:?}", node);
                    let root: std::cell::Ref<'_, RootCell> = node.borrow().unwrap();
                    let _ = root.0.borrow_mut().new_node_callback.insert(move || {
                        //mutex_win.lock().unwrap();
                        println!("NEW");
                        println!("CHILD");
                    });
                    this.root = Some(Rc::clone(&root.0));
                    Ok(())
                }
                _ => panic!("Not a node"),
            }
        });
        // methods.add_method("check", |_, this, _: ()| {
        //     let mut this = this.lock().unwrap();
        //     let a: &mut Win = this.deref_mut();
        //     let root = &a.root;
        //     let layout = &mut a.layout;
        //     if let Some(root) = root.as_ref() {
        //         println!("Count:: {}", Rc::strong_count(root));
        //         if let Some(layout_node) = root.borrow().layout_node {
        //             layout
        //                 .compute_layout(layout_node, Size::MAX_CONTENT)
        //                 .unwrap();
        //             let _ = layout.layout(layout_node).map(|r| {
        //                 println!("{:?}", r);
        //             });
        //         }
        //     }
        //     Ok(())
        // });
        methods.add_method("draw", |_, this, _: ()| {
            let win = this.lock().unwrap();
            win.draw().map_err(LuaError::RuntimeError)
        });
        methods.add_method("show", |_, this, ()| {
            let win = this.lock().unwrap();
            win.connection
                .send_request(&x::MapWindow { window: win.window });
            win.connection.flush().unwrap();
            Ok(())
        });
    }
}

impl Win {
    fn draw(&self) -> std::result::Result<(), String> {
        // let layout = &self.layout;
        // if let Some(root) = self.root.as_ref() {
        //     if let Some(root_node) = &root.borrow().root {
        //         crate::widgets::draw(
        //             &*root_node.borrow(),
        //             &self.cairo_context,
        //             &(|n| layout.layout(n.clone()).unwrap()),
        //         );
        //         self.surface.flush();
        //     }
        //     Ok(())
        // } else {
        //     Err("No root set".into())
        // }
        todo!()
    }
    fn new() -> Arc<MutexWin> {
        let (conn, screen_num) = xcb::Connection::connect(None).unwrap();
        let setup = conn.get_setup();
        let window: xcb::x::Window = conn.generate_id();

        let screen = setup.roots().nth(screen_num as usize).unwrap();
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
        let visual = find_visual(&conn, screen.root_visual()).unwrap();
        let (drawable, surface, cairo_context) = unsafe {
            let raw_conn = conn.get_raw_conn();
            let xcb_conn = XCBConnection::from_raw_full(std::mem::transmute(raw_conn));
            let drawable = XCBDrawable(xcb::Xid::resource_id(&window));
            let xcb_visual = XCBVisualType::from_raw_full(std::mem::transmute(&visual));
            let surface =
                cairo::XCBSurface::create(&xcb_conn, &drawable, &xcb_visual, 150, 150).unwrap();
            let cr = cairo::Context::new(&surface).unwrap();
            (drawable, surface, cr)
        };
        let connection = Arc::new(conn);
        let conn = connection.clone();

        let win = Win {
            connection,
            window,
            drawable,
            surface,
            root: None.into(),
            cairo_context,
            event_loop: None,
        };
        let win = MutexWin(Mutex::new(win));
        let win = Arc::new(win);

        let win1 = win.clone();
        let event_loop = std::thread::spawn(move || {
            println!("Event loop started");
            loop {
                let event = match conn.wait_for_event() {
                    Ok(event) => event,
                    Err(_) => {
                        return;
                    }
                };
                match event {
                    xcb::Event::X(x::Event::Expose(e)) => {
                        let w = win1.0.lock().unwrap();
                        let _ = w.draw();
                        let _ = w.connection.flush();
                        println!("Expose")
                    }
                    _ => {}
                }
            }
        });
        let _ = win.lock().unwrap().event_loop.insert(event_loop);
        win
    }
}
fn new(_: &Lua, _: ()) -> LuaResult<Arc<MutexWin>> {
    Ok(Win::new())
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("new", lua.create_function(new)?)?;
    Ok(exports)
}
