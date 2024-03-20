use crate::lua_module::*;
use fuzzy_matcher::FuzzyMatcher;
use mlua::prelude::*;
AddMethods!(fuzzy_matcher::clangd::ClangdMatcher,methods=>{
    methods.add_method("match",|_,matcher,(src,pattern):(String,String)|{
        if let Some((score,indices))=matcher.fuzzy_indices(src.as_str(),pattern.as_str()) {
            Ok((score,indices))
        } else {
            Ok((0,Vec::new()))
        }

    });
    methods.add_method("sort",|lua,matcher,(list,pattern):(Vec<String>,String)|{
        let mut list:Vec<_> = list.iter()
            .enumerate()
            .map(|(index,src)|(matcher.fuzzy_indices(src.as_str(),pattern.as_str()),src,index))
            .filter(|(m,_,_)|m.is_some())
            .map(|(m,src,index)|{
                let (score,indices) = m.unwrap();
                (src,indices,index,score)
            })
            .collect();
        list.sort_by_key(|(_,_,_,score)|*score * -1);

        Ok(list.iter().map(|(src,indices,index,score)|{
            // [src,indices,index,score]
            let table = lua.create_table().unwrap();
            table.push(
                lua.create_string(src.as_bytes()).unwrap()
            ).unwrap();
            let indices_table = lua.create_table().unwrap();
            for match_idx in indices {
                indices_table.push(*match_idx+1).unwrap()
            }
            table.push(indices_table).unwrap();
            // lua index starts from 1
            table.push(*index+1).unwrap();
            table.push(*score).unwrap();
            table
        }).collect::<Vec<_>>())
    });
});
pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "matcher",
        lua.create_function(|_, ()| {
            Ok(LuaWrapper(fuzzy_matcher::clangd::ClangdMatcher::default()))
        })?,
    )?;
    Ok(table)
}
