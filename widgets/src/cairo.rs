use std::{ffi::c_void, io::Write};

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
                cairo::Format::ARgb32 => gtk4::gdk::MemoryFormat::B8g8r8a8, //but why ?
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
            surface
                .with_data(|data| {
                    img_data.write(data).unwrap();
                })
                .unwrap();
            let data = gtk4::glib::Bytes::from(img_data.as_slice());
            let texture = gtk4::gdk::MemoryTexture::new(width, height, fmt, &data, stride as usize);
            Ok(LuaWrapper(texture))
        })?,
    )?;
    table.set(
        "from_file",
        lua.create_function(|_, path: String| {
            let img = image::open(&path);
            if let Ok(img) = img {
                let rgb = img.to_rgb8();
                let surface = cairo::ImageSurface::create(
                    cairo::Format::Rgb24,
                    img.width() as i32,
                    img.height() as i32,
                );
                if let Ok(mut surface) = surface {
                    {
                        let mut surface_data = surface.data().unwrap();
                        for y in 0..img.height() {
                            for x in 0..img.width() {
                                let index = (y * img.width() * 3 + x) as usize;
                                unsafe {
                                    surface_data[index] = *rgb.get_unchecked(index);
                                    surface_data[index + 1] = *rgb.get_unchecked(index + 1);
                                    surface_data[index + 2] = *rgb.get_unchecked(index + 2);
                                }
                            }
                        }
                    }

                    let ptr = surface.to_raw_none();
                    std::mem::forget(surface);
                    Ok(LuaValue::LightUserData(LuaLightUserData(
                        ptr as *mut c_void,
                    )))
                } else {
                    Err(LuaError::RuntimeError(format!(
                        "Failed to create image surface: {:?}",
                        surface
                    )))
                }
            } else {
                Err(LuaError::RuntimeError(format!("Invalid Image {:?}", path)))
            }
        })?,
    )?;
    Ok(table)
}
