use std::sync::Arc;

use gtk::{prelude::ApplicationExtManual, Application, ApplicationWindow};
use gtk::{prelude::*, Button};
use gtk4 as gtk;
use mlua::prelude::*;
struct Win {
    win: ApplicationWindow,
}
struct App {
    app: Application,
}
impl LuaUserData for App {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {}

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("connect_activate", |_, this, cb: LuaValue| match cb {
            LuaValue::Function(f) => {
                let g:LuaFunction<'static> = unsafe { std::mem::transmute(f)};
                this.app.connect_activate(move |_| {
                    g.call::<_, ()>(());
                });
                Ok(())
            }
            _ => {
                panic!("unexpected type")
            }
        });
        methods.add_method("win", |_, this, _: ()| {
            println!("new win {}", &this.app);
            Ok(Win::new(&this.app))
        });
        methods.add_method("run", |_, this, _: ()| {
            println!("@run");
            let args: Vec<&str> = vec![];
            let code = this.app.run_with_args(&args);
            Ok(code.value())
        });
    }
}

impl Win {
    fn new(app: &Application) -> Win {
        println!("@Win::new");
        let win = ApplicationWindow::builder()
            .application(app)
            .default_width(100)
            .default_height(100)
            .title("test")
            .build();
        let button = Button::with_label("Click me!");
        button.connect_clicked(|_| {
            eprintln!("Clicked!");
        });
        win.set_child(Some(&button));
        println!("win created");
        Win { win }
    }
}

impl LuaUserData for Win {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {}

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("show", |_, this, _: ()| {
            this.win.present();
            Ok(())
        })
    }
}

fn app(lua: &Lua, cb: LuaValue) -> LuaResult<App> {
    let app = App {
        app: Application::builder()
            .application_id("com.example.FirstGtkApp")
            .build(),
    };
    Ok(app)
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("app", lua.create_function(app)?)?;
    Ok(exports)
}
