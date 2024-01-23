macro_rules! LuaUserDataWrapper {
    ($name:ident, $t:ty) => {
        //#[derive(Debug)]
        struct $name($t);
        impl Deref for $name {
            type Target = $t;
            fn deref(&self) -> &Self::Target {
                &self.0
            }
        }
        impl DerefMut for $name {
            fn deref_mut(&mut self) -> &mut Self::Target {
                &mut self.0
            }
        }
    };
}
macro_rules! exports {
    ($lua:ident,$($name:literal,$value:expr),*,) => {
        {
            let exports = $lua.create_table()?;
            $(exports.set($name,$lua.create_function(|_,()|Ok($value))?)?;)*
            Ok(exports)
        }
    }
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
    ($methods:ident,$($name:ident $lua_type:ty : $input:ident => $out:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,$input:$lua_type|{
            w.$name($out);
            Ok(())
        }))*
    };
    ($methods:ident,$($name:ident,$lua_type:ty,
                      $input:ident => $out:expr),*) => {
        $($methods.add_method_mut(stringify!($name),|_,w,$input:$lua_type|{
            w.$name($out);
            Ok(())
        }))*
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
pub(crate) use exports;
pub(crate) use Getter;
pub(crate) use LuaUserDataWrapper;
pub(crate) use ParamlessCall;
pub(crate) use Setter;
