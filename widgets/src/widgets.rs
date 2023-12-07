use mlua::prelude::*;
use taffy::prelude::Style as Layout;
use taffy::prelude::*;

#[derive(Debug)]
pub struct Style {
    background: i32,
    color: i32,
}

#[derive(Debug)]
pub enum NodeType {
    Box(Vec<Node>),
    Img,
    Text,
}
#[derive(Debug)]
pub struct Node {
    node_type: NodeType,
    layout: Layout,
    style: Style,
}
impl Node {
    pub fn new_box() -> Node {
        Node {
            node_type: NodeType::Box(vec![]),
            layout: Layout {
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
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "box",
        lua.create_function(|_, _: ()| Ok(std::rc::Rc::new(Node::new_box())))?,
    )?;
    Ok(table)
}
