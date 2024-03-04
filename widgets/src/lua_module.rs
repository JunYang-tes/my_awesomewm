use mlua::prelude::*;
#[allow(unused)]
macro_rules! exports {
    ($lua:ident,$($name:literal,$value:expr),*,) => {
        {
            let exports = $lua.create_table()?;
            $(exports.set($name,$lua.create_function(|_,()|Ok($value))?)?;)*
            Ok(exports)
        }
    }
}
macro_rules! Call {
    ($method:ident,
     $name:ident,
     // lua value to value
     $lua_args:ident:$lua_args_type:ty=> $value:expr,
     // return type
     $ret:ident=> $ret_value:expr
    ) => {
        $method.add_method_mut(stringify!($name), |_, obj, $lua_args: $lua_args_type| {
            let args = $value;
            let $ret = obj.$name(args);
            $ret_value
        });
    };
}
macro_rules! ReturnlessCall {
    ($methods:ident,$($name:ident $input:ident:$lua_type:ty => $out:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,$input:$lua_type|{
            w.$name($out);
            Ok(())
        });)*
    };
}
macro_rules! Setter {
    ($methods:ident,$($name:ident,$type:ty),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,v:$type|{
            w.$name(v);
            Ok(())
        });)*
    };
    ($methods:ident,$($name:ident $type:ty),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,v:$type|{
            w.$name(v);
            Ok(())
        });)*
    };
    ($methods:ident,$($name:ident $input:ident:$lua_type:ty => $out:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,$input:$lua_type|{
            w.$name($out);
            Ok(())
        });)*
    };
    ($methods:ident,$($name:ident,$lua_type:ty,
                      $input:ident => $out:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,$input:$lua_type|{
            w.$name($out);
            Ok(())
        });)*
    }
}

macro_rules! ParamlessCall {
    ($methods:ident,$($name:ident),*) => {
        $($methods.add_method_mut(stringify!($name), |_, self_, ()| {
            self_.$name();
            Ok(())
        });)*
    };
}
macro_rules! Getter {
    ($methods:ident,$($name:ident),*) => {
        $($methods.add_method_mut(stringify!($name),|_,self_,()|{
            Ok(self_.$name())
        });)*
    };
    ($methods:ident,$($name:ident $i:ident => $cvt:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,self_,()|{
            let $i = self_.$name();
            Ok($cvt)
        });)*
    }
}
pub struct LuaWrapper<T>(pub(crate) T);
impl<T> Deref for LuaWrapper<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
// impl<T> DerefMut for LuaWrapper<T> {
//     fn deref_mut(&mut self) -> &mut Self::Target {
//         &mut self.0
//     }
// }
impl<T> DerefMut for LuaWrapper<&T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        todo!()
    }
}
macro_rules! AddMethods {
    ($type:ty, $methods:ident => $block:block) => {
        impl LuaUserData for LuaWrapper<$type> {
            fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>($methods: &mut M) {
                $block;
            }
        }
        impl LuaUserData for LuaWrapper<&$type> {
            fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>($methods: &mut M) {
                $block;
            }
        }
    };
}

macro_rules! MatchLuaUserData {
    ($data:ident,
     $item: ident => $exp : block,
     $($type:ty),+ $(,)?) => {
        $(
        if $data.is::<$type>() {
            let $item = $data.borrow::<$type>().unwrap();
            $exp;
        }
         )*
    };
}
macro_rules! Table {
    ($lua:ident,$($key:ident=>$val:expr,)*) => {
        {
        let table = $lua.create_table();
        if let Ok(table) = table {
            $(let _=table.set(stringify!($key),$val);)*
            Ok(table)
        } else {
            table
        }
        }
    };
}

use std::ops::{Deref, DerefMut};

pub(crate) use exports;
pub(crate) use AddMethods;
pub(crate) use Call;
pub(crate) use Getter;
pub(crate) use MatchLuaUserData;
pub(crate) use ParamlessCall;
pub(crate) use ReturnlessCall;
pub(crate) use Setter;
pub(crate) use Table;
