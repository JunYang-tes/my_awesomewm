use crate::lua_module::*;
use gtk::prelude::ButtonExt as _;
use gtk::prelude::CssProviderExt;
use gtk::prelude::StyleContextExt;
use mlua::prelude::*;
AddMethods!(gtk::StyleContext,methods => {
    ParamlessCall!(methods,save,restore);
    Getter!(methods,scale);
    Getter!(methods,list_classes i=>i
            .iter()
            .map(|gstr|String::from(gstr.as_str()))
            .collect::<Vec<_>>());
    Setter!(methods,
            set_scale i32: i=>i,
            add_class String:i=>i.as_str());
    Call!(methods,
          has_class,
          cls_name:String => cls_name.as_str(),
          i => Ok(i));
    Call!(methods,
          remove_class,
          cls_name:String => cls_name.as_str(),
          i => Ok(i));
    methods.add_method("add_provider",|_,ctx,(provider,priority):(LuaValue,u32)|{
        match provider {
            LuaValue::UserData(data)=>{
                if data.is::<LuaWrapper<gtk::CssProvider>>(){
                    let provider = data.borrow::<LuaWrapper<gtk::CssProvider>>().unwrap();
                    ctx.add_provider(&provider.0,priority)
                } else if data.is::<LuaWrapper<&gtk::CssProvider>>() {
                    let provider = data.borrow::<LuaWrapper<&gtk::CssProvider>>().unwrap();
                    ctx.add_provider(provider.0,priority)
                }
            },
            _=>{}
        }
        Ok(())
    });
});
AddMethods!(gtk::CssProvider,methods => {
    Call!(methods,
          load_from_data,
          data:String => data.as_bytes(),
          i => if i.is_ok() { Ok(String::from(""))} else {Ok(String::from(i.unwrap_err().to_string()))}
          );
});
pub fn style_context(lua: &Lua) -> LuaResult<LuaTable> {
    let style_context = lua.create_table()?;
    style_context.set(
        "add_provider_for_screen",
        lua.create_function(
            |_, (screen, provider, priority): (LuaValue, LuaValue, u32)| {
                //gtk::StyleContext::add_provider_for_screen
                match (screen, provider) {
                    (LuaValue::UserData(screen), LuaValue::UserData(provider)) => {
                        if screen.is::<LuaWrapper<gtk::gdk::Screen>>()
                            && provider.is::<LuaWrapper<gtk::CssProvider>>()
                        {
                            let screen = screen.borrow::<LuaWrapper<_>>().unwrap();
                            let provider =
                                provider.borrow::<LuaWrapper<gtk::CssProvider>>().unwrap();
                            gtk::StyleContext::add_provider_for_screen(
                                &screen.0,
                                &provider.0,
                                priority,
                            )
                        }
                    }
                    _ => {}
                }

                Ok(())
            },
        )?,
    )?;
    style_context.set(
        "remove_provider_for_screen",
        lua.create_function(|_, (screen, provider): (LuaValue, LuaValue)| {
            //gtk::StyleContext::add_provider_for_screen
            match (screen, provider) {
                (LuaValue::UserData(screen), LuaValue::UserData(provider)) => {
                    if screen.is::<LuaWrapper<gtk::gdk::Screen>>()
                        && provider.is::<LuaWrapper<gtk::CssProvider>>()
                    {
                        let screen = screen.borrow::<LuaWrapper<_>>().unwrap();
                        let provider = provider.borrow::<LuaWrapper<gtk::CssProvider>>().unwrap();
                        gtk::StyleContext::remove_provider_for_screen(&screen.0, &provider.0)
                    }
                }
                _ => {}
            }

            Ok(())
        })?,
    )?;
    Ok(style_context)
}
