// import ejs from "npm:ejs@3.1.10"
// console.log(ejs)
// ejs.compile()
//
function call(f: () => string) {
  return f()
}

type GtkApiInfo = {
  name: string
  gtkInstaceCast: Array<string>,
  params: Array<'int' | 'double' | 'boolean' | 'char *' | 'GtkInstace'>,
  ret: 'int' | 'double' | 'boolean' | 'char *' | 'void *' | 'void' | 'GtkInstace'
}
function makeCallToGtkApi(prefix: string, info: GtkApiInfo) {
  const gtkParam = info.params.map((p, i) => {
    if (p === 'GtkInstace' && info.gtkInstaceCast[i]) {
      return info.gtkInstaceCast[i] + `(var_${i}->gtk_instance )`;
    } else {
      return `var_${i}`
    }
  }).join(',')
  return (`
static int ${prefix}_${info.name}(luaState *L) {
  ${info.params.map((p, i) => {
    if (p === 'GtkInstace') {
      return `GtkInstace *var_${i}= lua_touserdata(L,${i + 1});`
    } else {
      return `
        ${p} var_i =${call(() => {
        switch (p) {
          case 'int':
          case 'double':
            return `(${p})luaL_checknumber(L,${i + 1})`;
          case 'boolean':
            return `luaL_checktype(L,${i + 1},LUA_TBOOLEAN)`
          case 'char *':
            return `lua__checkstring(L,${i + 1})`
        }
        return "0;//warning:unhandled param type";
      })};
     `
    }
  }).join('\n')}
  ${call(() => {
    if (info.ret === 'void') {
      return `
${info.name}(${gtkParam})
return 0;`
    } else {
      if (info.ret == 'GtkInstace') {
        return `GtkInstace *instance =(GtkInstace *) lua_newuserdata(L,sizeof(GtkInstace));
instance->gtk_instance = ${info.name}(${gtkParam})
`
      }

      return `return 1;`
    }
  })}
  
}
`)
}

function paramlessRetVoid(
  widgetName: string,
  items: string[]): GtkApiInfo[] {
  return items.map(name => ({ name: `gtk_${widgetName}_${name}`, params: ['GtkInstace'], ret: 'void', gtkInstaceCast: [`GTK_${widgetName.toUpperCase()}`] }))
}
function simpleType(widgetName: string, items: Array<[method: string, params: Array<'int' | 'double' | 'char *'>, ret?: 'int' | 'boolean' | 'double']>): GtkApiInfo[] {
  return items.map(([method, params, ret]) => ({
    name: `gtk_${widgetName}_${method}`,
    params: ['GtkInstace', ...params],
    gtkInstaceCast: [`GTK_WIDGET`],
    ret: ret ?? 'void'
  }))
}


function widgetApis(widgetName: string, apis: GtkApiInfo[]) {
  return (
    `
${apis.map((item) => `${makeCallToGtkApi(widgetName, item)}`)}

luaLReg ${widgetName}_apis[] = {
${apis.map((item) => `{${item.name},${widgetName}_${item.name}},`).join("\n")}
  {NULL,NULL}
};

`
  );
}


const code = `
#include <gtk/gtk.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
typedef struct GtkInstance {
  void *gtk_instance;
} GtkInstace;

${widgetApis("widget", [
  ...paramlessRetVoid('widget', ["show", "hide"]),
  ...simpleType('widget', [['real_contains', ['double', 'double'], 'boolean']])
])}

`;
console.log(code);
