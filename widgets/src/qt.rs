use std::{cell::RefCell, mem::forget, ops::Deref, rc::Rc};

use crate::lua_module::*;
use cpp_core::{CppBox, Ptr, StaticUpcast};
use mlua::prelude::*;
use qt_core::{qs, QBox, QCoreApplication, QCoreApplicationArgs, QObject, SlotNoArgs};
use qt_widgets::{
    q_list_view::LayoutMode, QApplication, QHBoxLayout, QLabel, QLayout, QLineEdit, QListWidget, QListWidgetItem, QPushButton, QVBoxLayout, QWidget
};

struct App {
    qapp: QBox<QApplication>,
    args: QCoreApplicationArgs,
}
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
impl StaticUpcast<QObject> for LuaWrapper<QBox<QWidget>> {
    unsafe fn static_upcast(ptr: Ptr<Self>) -> Ptr<QObject> {
        ptr.as_ptr().static_upcast()
    }
}
macro_rules! WidgetBaseMethods {
    ($methods:ident) => {
        $methods.add_method("as_ptr", |_, w, ()| unsafe { Ok(w.as_raw_ptr() as usize) });
    };
}
macro_rules! AddMethods {
    ($type:ty, $methods:ident => $block:block) => {
        impl LuaUserData for LuaWrapper<$type> {
            fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>($methods: &mut M) {
                $block;
            }
        }
    };
}
macro_rules! Events {
    ($methods:ident, $name:ident) => {
        println!("eee:{}", concat!("on_", stringify!($name)));
        $methods.add_method(
            concat!("on_", stringify!($name)),
            |lua, this, f: LuaValue| match f {
                LuaValue::Function(f) => unsafe {
                    let w = Rc::clone(this);
                    let g: mlua::Function<'static> = std::mem::transmute(f);
                    let l: &'static mlua::Lua = std::mem::transmute(lua);
                    let p: mlua::AnyUserData<'static> =
                        l.create_userdata(LuaWrapper(Rc::clone(&w))).unwrap();
                    let slot = SlotNoArgs::new(this.widget.as_ptr(), move || {
                        if let Err(err) = g.call::<&mlua::AnyUserData<'static>, ()>(&p) {
                            println!("Failled to call lua function:{:?}", err);
                        }
                    });
                    this.$name().connect(slot.as_ptr());
                    this.push_slot(slot);
                    Ok(())
                },
                _ => Err(LuaError::runtime("Expect function")),
            },
        );
    };
}
macro_rules! Layout {
    ($methods:ident)=>{
        $methods.add_method("add_widget",|_,this,ptr:usize| unsafe {
            let child = QBox::from_raw(ptr as *const QWidget);
            this.add_widget(&child);
            // child not own by us, dont drop it
            std::mem::forget(child);
            Ok(())
        });
    }
}
AddMethods!(QBox<QWidget>,methods=>{
    unsafe{
      ParamlessCall!(methods,show)
    }
    WidgetBaseMethods!(methods);
    methods.add_method("set_layout",|_,this,layout:usize| unsafe {
        let layout = QBox::from_raw(layout as *const QLayout);
        this.set_layout(&layout);
        std::mem::forget(layout);
        this.show();
        Ok(())
    });
});

struct QWidgetsWrapper<T> {
    widget: T,
    slots: RefCell<Vec<QBox<SlotNoArgs>>>,
}
impl<T> QWidgetsWrapper<T> {
    fn new(w: T) -> Self {
        Self {
            widget: w,
            slots: RefCell::new(Vec::new()),
        }
    }
    fn push_slot(&self, slot: QBox<SlotNoArgs>) {
        self.slots.borrow_mut().push(slot);
    }
}
impl<T> Deref for QWidgetsWrapper<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.widget
    }
}

AddMethods!(Rc<QWidgetsWrapper<QBox<QPushButton>>>,methods=>{
    WidgetBaseMethods!(methods);
    unsafe {
        Getter!(methods,is_visible);
        Setter!(methods,set_text txt:String=>&qs(txt));
    }
    Events!(methods,clicked);
});

AddMethods!(Rc<QWidgetsWrapper<QBox<QLineEdit>>>,methods=>{
    WidgetBaseMethods!(methods);
    Events!(methods,text_edited);

});

AddMethods!(Rc<QWidgetsWrapper<QBox<QListWidget>>>,methods=>{
    WidgetBaseMethods!(methods);
    unsafe {
        ParamlessCall!(methods,clear)
    }
    methods.add_method("add_item",|_,this,widget:usize| unsafe {
        let item = QListWidgetItem::new();
        let widget = QBox::from_raw(widget as * const QWidget);
        //item.set_size_hint(widget.minimum_size_hint().as_ref());
        this.add_item_q_list_widget_item(&item);
        this.set_item_widget(&item,&widget);
        forget(widget);
        // it seams item will be deted by list
        forget(item);
        Ok(())
    });

});
AddMethods!(CppBox<QListWidgetItem>,methods=>{
    methods.add_method("as_ptr",|_,this,()|Ok(this.as_raw_ptr() as usize
    ));

});

AddMethods!(QBox<QVBoxLayout>,methods=>{
    WidgetBaseMethods!(methods);
    Layout!(methods);
});

AddMethods!(QBox<QLabel>,methods=>{
    WidgetBaseMethods!(methods);
    unsafe {
        ParamlessCall!(methods,clear);
        Setter!(methods,
                set_text txt:String=>&qs(txt),
                set_word_wrap b:bool=>b
        );
    }
});

AddMethods!(QBox<QHBoxLayout>,methods=>{
    WidgetBaseMethods!(methods);
    Layout!(methods);
});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    exports!(
        lua,
        "app",
        unsafe {
            let mut args = QCoreApplicationArgs::new();
            let (argc, argv) = args.get();
            let app = QApplication::new_2a(argc, argv);
            App { qapp: app, args }
        },
        "win",
        unsafe {
            let win = QWidget::new_0a();
            LuaWrapper(win)
        },
        "vbox",
        unsafe {
            let vbox = QVBoxLayout::new_0a();
            LuaWrapper(vbox)
        },
        "hbox", unsafe {
            LuaWrapper(QHBoxLayout::new_0a())
        },
        "line_edit",
        unsafe {
            let line_edit = QLineEdit::new();
            LuaWrapper(Rc::new(QWidgetsWrapper::new(line_edit)))
        },
        "button",
        unsafe {
            let btn = QPushButton::new();
            LuaWrapper(Rc::new(QWidgetsWrapper::new(btn)))
        },
        "list",
        unsafe {
            let list = Rc::new(QWidgetsWrapper::new(QListWidget::new_0a()));
            list.set_layout_mode(LayoutMode::Batched);
            LuaWrapper(list)
        },
        "list_item",
        unsafe { LuaWrapper(QListWidgetItem::new()) },
        "label",
        unsafe { LuaWrapper(QLabel::new()) },
    )
}
