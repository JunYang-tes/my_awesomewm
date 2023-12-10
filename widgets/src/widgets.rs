use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use taffy::prelude::Style as LayoutStyle;
use taffy::prelude::*;

#[derive(Debug)]
pub struct Style {
    background: i32,
    color: i32,
}

#[derive(Debug)]
pub enum NodeType {
    Box(Vec<Rc<RefCell<Node>>>),
    Img,
    Text,
}
#[derive(Debug)]
pub struct Node {
    node_type: NodeType,
    pub layout: LayoutStyle,
    pub layout_node: Option<taffy::node::Node>,
    style: Style,
}
impl Node {
    pub fn new_box() -> Node {
        Node {
            node_type: NodeType::Box(vec![]),
            layout_node: None,
            layout: LayoutStyle {
                ..Default::default()
            },
            style: Style {
                background: 0,
                color: 0,
            },
        }
    }
}
impl LuaUserData for Node {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {}

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("add_child", |_, this, child: LuaValue| {
            match child {
                LuaValue::UserData(node) => {
                    let root: std::rc::Rc<RefCell<crate::widgets::Node>> =
                        std::rc::Rc::clone(&node.borrow().unwrap());
                    if let NodeType::Box(children) = &mut this.node_type {
                        children.push(root);
                    }
                }
                _ => panic!("Not a valid child"),
            }
            Ok(())
        });
    }
}

fn draw_box<'a, F: Fn(&'a taffy::node::Node) -> &'a taffy::layout::Layout>(
    node: &'a Node,
    cr: &cairo::Context,
    layout: &F,
) {
    println!("@draw_box");
    if let Some(layout_node) = node.layout_node.as_ref() {
        let layout = layout(layout_node);
        println!("draw!box! {:?}", layout);
        cr.set_source_rgb(1.0, 0.0, 0.0);
        cr.set_line_width(2.0);
        cr.rectangle(
            layout.location.x as f64,
            layout.location.y as f64,
            layout.size.width as f64,
            layout.size.height as f64,
        );
        let _ = cr.stroke();
    }
}

pub fn draw<'a, F: Fn(&'a taffy::node::Node) -> &'a taffy::layout::Layout>(
    node: &'a Node,
    cr: &cairo::Context,
    layout: &F,
) -> () {
    match &node.node_type {
        NodeType::Box(children) => {
            draw_box(node, cr, layout);
            for child in children.iter() {
                let child = child.borrow();
                let child_ref = &*child as *const Node;
                unsafe { draw(unsafe { std::mem::transmute(child_ref) }, cr, layout) }
            }
        }
        _ => {}
    }
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "box",
        lua.create_function(|_, _: ()| Ok(std::rc::Rc::new(RefCell::new(Node::new_box()))))?,
    )?;
    Ok(table)
}
