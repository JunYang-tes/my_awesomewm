use std::cell::RefCell;
use std::collections::VecDeque;
use std::ops::{Deref, DerefMut};
use std::rc::Rc;

use cairo::glib::clone::Downgrade;
use mlua::prelude::*;
use taffy::prelude::Layout as TaffyLayout;
use taffy::prelude::Style as LayoutStyle;
use taffy::{
    compute_cached_layout, compute_flexbox_layout, compute_root_layout, prelude::*, Cache,
    LayoutInput, LayoutOutput,
};

#[derive(Debug)]
pub struct WidgetStyle {
    background: i32,
    color: i32,
}

#[derive(Debug)]
pub enum NodeType {
    Box(Vec<NodeInCell>),
    Img,
    Text,
}
pub struct Node {
    node_type: NodeType,
    cache: Cache,
    final_layout: TaffyLayout,
    unrounded_layout: TaffyLayout,
    style: WidgetStyle,
    layout_style: LayoutStyle,
    root: std::rc::Weak<RefCell<Root>>,
}
#[derive(Debug)]
pub struct NodeInCell(Rc<RefCell<Node>>);
impl Deref for NodeInCell {
    type Target = Rc<RefCell<Node>>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for NodeInCell {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}
impl NodeInCell {
    fn node_from_id(&self, node_id: NodeId) -> NodeInCell {
        let idx = usize::from(node_id);
        if idx == usize::MAX {
            NodeInCell(self.0.clone())
        } else {
            let node = &*self.borrow();
            match &node.node_type {
                NodeType::Box(children) => NodeInCell(children[idx].0.clone()),
                _ => NodeInCell(self.0.clone()),
            }
        }
    }
    pub fn compute_layout(&mut self, available_space: Size<AvailableSpace>) {
        println!("style of root {:?}",self.borrow().layout_style);
        compute_root_layout(self, NodeId::from(usize::MAX), available_space);
    }

    // fn node_from_id_mut(&mut self, node_id: NodeId) -> &mut NodeInCell {
    //     let idx = usize::from(node_id);
    //     if idx == usize::MAX {
    //         self
    //     } else {
    //         let mut node_ref = self.borrow_mut();
    //         let node = &mut *node_ref;
    //         match node.node_type {
    //             NodeType::Box(children)=> &mut children[idx],
    //             _ => self
    //         }
    //     }
    // }
}

impl std::fmt::Debug for Node {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(
            format!(
                "node_type:{:?}\n final_layout:{:?}\n style:{:?}",
                self.node_type, self.final_layout, self.style
            )
            .as_str(),
        )
    }
}

impl Node {
    pub fn new_box() -> Node {
        Node {
            node_type: NodeType::Box(vec![]),
            cache: Cache::new(),
            unrounded_layout: Layout::with_order(0),
            final_layout: Layout::with_order(0),
            style: WidgetStyle {
                background: 0,
                color: 0,
            },
            layout_style: Default::default(),
            root: std::rc::Weak::new(),
        }
    }
    // fn node_from_id(&self, node_id: NodeId) -> &Node {
    //     let idx = usize::from(node_id);
    //     if idx == usize::MAX {
    //         self
    //     } else if let NodeType::Box(children) = &self.node_type {
    //         &children[idx]
    //     } else {
    //         self
    //     }
    // }
    // fn node_from_id_mut(&mut self, node_id: NodeId) -> &mut Node {
    //     let idx = usize::from(node_id);
    //     if idx == usize::MAX {
    //         return self;
    //     }
    //     let s = self as *const Node;
    //     match &mut self.node_type {
    //         NodeType::Box(ref mut child) => &mut child[idx],
    //         _ => unsafe { std::mem::transmute(s) },
    //     }
    // }
}

pub struct ChildIter(std::ops::Range<usize>);
impl Iterator for ChildIter {
    type Item = NodeId;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.next().map(|idx| NodeId::from(idx))
    }
}

impl taffy::TraversePartialTree for NodeInCell {
    type ChildIter<'a> = ChildIter;

    fn child_ids(&self, parent_node_id: NodeId) -> Self::ChildIter<'_> {
        let node_ref = self.borrow();
        let node = &*node_ref;
        match &node.node_type {
            NodeType::Box(children) => ChildIter(0..children.len()),
            _ => ChildIter(0..0),
        }
    }

    fn child_count(&self, parent_node_id: NodeId) -> usize {
        let node_ref = self.borrow();
        let node = &*node_ref;
        match &node.node_type {
            NodeType::Box(children) => children.len(),
            _ => 0,
        }
    }

    fn get_child_id(&self, parent_node_id: NodeId, child_index: usize) -> NodeId {
        NodeId::from(child_index)
    }
}
impl taffy::LayoutPartialTree for NodeInCell {
    fn get_style(&self, node_id: NodeId) -> &Style {
        let node_in_cell = self.node_from_id(node_id);
        let node_ref = node_in_cell.borrow();
        let node = &*node_ref;
        let style = &node.layout_style as *const Style;
        unsafe { std::mem::transmute(style) }
    }

    fn set_unrounded_layout(&mut self, node_id: NodeId, layout: &Layout) {
        let node_in_cell = self.node_from_id(node_id);
        let mut node_ref = node_in_cell.borrow_mut();
        let node = &mut *node_ref;
        node.unrounded_layout = *layout;
    }

    fn get_cache_mut(&mut self, node_id: NodeId) -> &mut Cache {
        let node_in_cell = self.node_from_id(node_id);
        let node_ref = node_in_cell.borrow();
        let node = &*node_ref;
        let style = &node.layout_style as *const Style;
        unsafe { std::mem::transmute(style) }
    }

    fn compute_child_layout(&mut self, node_id: NodeId, inputs: LayoutInput) -> LayoutOutput {
        compute_cached_layout(self, node_id, inputs, |parent, node_id, inputs| {
            let mut node_in_cell = parent.node_from_id(node_id);
            let mut node_ref = node_in_cell.borrow_mut();
            let node = &mut *node_ref;
            match node.node_type {
                NodeType::Box(_) => {
                    drop(node_ref);
                    compute_flexbox_layout(&mut node_in_cell, node_id, inputs)
                }
                _ => {
                    todo!()
                }
            }
        })
    }
}

#[derive(Debug)]
pub struct Root {
    pub root: Option<NodeInCell>,
    pub new_node_callback: Option<fn()>,
}

#[derive(Debug)]
pub struct RootCell(pub Rc<RefCell<Root>>);
impl Deref for RootCell {
    type Target = Rc<RefCell<Root>>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
impl DerefMut for RootCell {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl LuaUserData for RootCell {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {}

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("box", |_, this, _: ()| {
            let mut node = Node::new_box();
            node.root = this.downgrade();

            Ok(Rc::new(RefCell::new(node)))
        });
        methods.add_method_mut("set_root_node", |_, this, value: LuaValue| {
            let mut this = this.borrow_mut();
            match value {
                LuaValue::UserData(node) => {
                    this.root
                        .insert(NodeInCell(Rc::clone(&node.borrow().unwrap())));
                    Ok(())
                }
                _ => {
                    panic!("Expect a node")
                }
            }
        });
    }
}

impl LuaUserData for Node {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {}

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("check", |_, this, _: ()| {
            println!("{:?}", this);
            println!("{:?}", this.root.upgrade());
            Ok(())
        });
        methods.add_method_mut("set_width", |_, this, w: LuaValue| {
            println!("set_width {:?}", w);
            match w {
                LuaValue::Integer(w) => {
                    this.layout_style.size.width = Dimension::Length(w as f32)
                }
                LuaValue::Number(w) => {
                    this.layout_style.size.width = Dimension::Length(w as f32)
                }
                _ => {
                    panic!("Expect number")
                }
            }
            Ok(())
        });
        methods.add_method_mut("set_height", |_, this, w: LuaValue| {
            match w {
                LuaValue::Integer(w) => {
                    this.layout_style.size.height = Dimension::Length(w as f32)
                }
                LuaValue::Number(w) => {
                    this.layout_style.size.height = Dimension::Length(w as f32)
                }
                _ => {
                    panic!("Expect number")
                }
            }
            Ok(())
        });
        methods.add_method_mut("add_child", |_, this, child: LuaValue| {
            println!("{:?}", child);
            match child {
                LuaValue::UserData(node) => {
                    let child_node: std::rc::Rc<RefCell<crate::widgets::Node>> =
                        std::rc::Rc::clone(&node.borrow().unwrap());
                    let root = this.root.upgrade();
                    if let Some(root) = root {
                        if let Some(cb) = root.borrow().new_node_callback {
                            cb()
                        }
                    } else {
                        println!("No root found")
                    }
                    if let NodeType::Box(children) = &mut this.node_type {
                        children.push(NodeInCell(child_node));
                    } else {
                        panic!("Not a container")
                    }
                }
                _ => panic!("Not a valid child"),
            }
            Ok(())
        });
    }
}

fn draw_box(node: &Node, cr: &cairo::Context) {
    println!("@draw_box");
    println!("draw!box! {:?}", node.unrounded_layout);
    cr.set_source_rgb(1.0, 0.0, 0.0);
    cr.set_line_width(2.0);
    cr.rectangle(
        node.unrounded_layout.location.x as f64,
        node.unrounded_layout.location.y as f64,
        node.unrounded_layout.size.width as f64,
        node.unrounded_layout.size.height as f64,
    );
    let _ = cr.stroke();
}

pub fn draw(node: &NodeInCell, cr: &cairo::Context) -> () {
    let node = &*node.borrow();
    match &node.node_type {
        NodeType::Box(children) => {
            draw_box(node, cr);
            for child in children.iter() {
                println!("draw child");
                draw(child, cr)
            }
        }
        _ => {}
    }
}

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "root",
        lua.create_function(|_, _: ()| {
            Ok(RootCell(Rc::new(RefCell::new(Root {
                root: None,
                new_node_callback: None,
            }))))
        })?,
    )?;
    // table.set(
    //     "box",
    //     lua.create_function(|_, _: ()| Ok(std::rc::Rc::new(RefCell::new(Node::new_box()))))?,
    // )?;
    Ok(table)
}
