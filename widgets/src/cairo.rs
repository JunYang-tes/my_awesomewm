use crate::lua_module::*;
use mlua::prelude::*;
AddMethods!(cairo::ImageSurface,methods=>{});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "from_ptr",
        lua.create_function(|_, ptr: usize| {
            Ok(LuaWrapper(
                    unsafe{
                        cairo::ImageSurface::from_raw_none( std::mem::transmute(ptr)).unwrap()
                    }
            ))
        })?,
    )?;
    Ok(table)
}
