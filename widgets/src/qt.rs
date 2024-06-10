use crate::lua_module::*;
use mlua::prelude::*;
use qt_core::{QBox, QCoreApplication, QCoreApplicationArgs};
use qt_widgets::{QApplication, QLineEdit, QVBoxLayout, QWidget};

struct App(QBox<QApplication>);
impl LuaUserData for App {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("process_events", |_, _this, ()| unsafe {
            QCoreApplication::process_events_0a();
            Ok(())
        });
        methods.add_method("exec", |_, _, ()| unsafe {
            QApplication::exec();
            Ok(())
        });
    }
}

AddMethods!(QBox<QWidget>,methods=>{
    // unsafe{
    //   ParamlessCall!(methods,show)
    // }
    methods.add_method("show",|_,this,()| unsafe {
        println!("show");
        this.show();
        Ok(())
    });
    methods.add_method("set_layout",|_,this,layout:usize| unsafe {
        println!("add layout:{}",layout);
        let layout = QBox::from_raw(layout as *const QVBoxLayout);
        println!("ptr: {}",layout.as_raw_ptr() as usize);
        // let layout =    QVBoxLayout::new_0a();
        let line = QLineEdit::new();
        layout.add_widget(&line);
        println!("will call set_layout");

        this.set_layout(&layout);
        Ok(())
    });
});

AddMethods!(QBox<QLineEdit>,methods=>{
    methods.add_method("as_ptr",|_,this,()| unsafe {
        let ptr = this.as_raw_ptr() as usize;
        println!("[r] ptr:{}",ptr);
        Ok(ptr)
    });

});

AddMethods!(QBox<QVBoxLayout>,methods=>{

    methods.add_method("as_ptr",|_,this,()| unsafe {
        let ptr = this.as_raw_ptr() as usize;
        println!("[r] ptr:{}",ptr);
        Ok(ptr)
    });
    methods.add_method("add_widget",|_,this,ptr:usize| unsafe {
        let child = QBox::from_raw(ptr as *const QLineEdit);
        println!("add child");
        this.add_widget(&child);
        Ok(())
    });
});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        unsafe {
            let mut args = QCoreApplicationArgs::new();
            let (argc, argv) = args.get();
            let app = QApplication::new_2a(argc, argv);
            App(app)
        },
        "win",
        unsafe {
            let win = QWidget::new_0a();
            LuaWrapper(win)
        },
        "vbox",
        unsafe { LuaWrapper(QVBoxLayout::new_0a()) },
        "line_edit",
        unsafe { LuaWrapper(QLineEdit::new()) },
    )
}
