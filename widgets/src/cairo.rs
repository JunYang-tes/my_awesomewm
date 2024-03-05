use std::io::Write;

use crate::lua_module::*;
use mlua::prelude::*;
AddMethods!(cairo::ImageSurface,methods=>{});
AddMethods!(gtk4::gdk::MemoryTexture,methods=>{});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "from_ptr",
        lua.create_function(|_, ptr: usize| {
            let surface =
                unsafe { cairo::ImageSurface::from_raw_none(std::mem::transmute(ptr)).unwrap() };

            let fmt = match surface.format() {
                cairo::Format::ARgb32 => gtk4::gdk::MemoryFormat::B8g8r8a8,//but why ?
                cairo::Format::Rgb24 => gtk4::gdk::MemoryFormat::R8g8b8,
                cairo::Format::A8 => gtk4::gdk::MemoryFormat::A8,
                _ => {
                    panic!("Unsupported")
                }
            };
            let width = surface.width();
            let height = surface.height();
            let stride = surface.stride() as usize;
            let mut img_data = Vec::with_capacity((width * height * 4) as usize);
            surface.with_data(|data| {
                img_data.write(data).unwrap();
            }).unwrap();
            let data = gtk4::glib::Bytes::from(img_data.as_slice());
            let texture = gtk4::gdk::MemoryTexture::new(width, height, fmt, &data, stride as usize);
            Ok(LuaWrapper(texture))
        })?,
    )?;
    Ok(table)
}
