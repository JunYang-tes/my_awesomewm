#include <X11/Xlib.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

int is_valid_window(Display *display, Window window) {
  XWindowAttributes attributes;
  if (XGetWindowAttributes(display, window, &attributes)) {
    return 1; // Window ID is valid
  } else {
    return 0; // Window ID is invalid
  }
}

int make_a_overlay(lua_State *L) {
  unsigned long win = luaL_checknumber(L, 1);
  Display *display = XOpenDisplay(NULL);
  if (!is_valid_window(display, (Window)win)) {
    printf("[xdnd] %ld is not a valided window\n", win);
    return 0;
  }
  lua_pushlightuserdata(L, (void *)win);
  lua_newtable(L); //[table,win ...]

  // Push the key "running"
  lua_pushstring(L, "running"); // ["running",table,win]
  // Push the value (e.g., a boolean)
  lua_pushboolean(L, 1); // true // [true,"running",table]
  // Set the table field
  lua_settable(L, -3); // Table is at -3, key is at -2, value is at -1
                       // [table ...]

  // Push the key "dragging"
  lua_pushstring(L, "dragging");
  // Push the value (e.g., a boolean)
  lua_pushboolean(L, 0); // false
  // Set the table field
  lua_settable(L, -3); // Table is at -3, key is at -2, value is at -1
                       // [table win ...]
  lua_settable(L, LUA_REGISTRYINDEX);
  return 0;
}
int is_dragging(lua_State *L) {
  unsigned long win = luaL_checknumber(L, 1);
  lua_pushlightuserdata(L, (void *)win);
  lua_gettable(L, LUA_REGISTRYINDEX);
  //[nil/table ...]
  if (lua_isnil(L, -1)) {
    printf("[xdnd] Do you called make_a_overlay for %ld\n", win);
    lua_pushboolean(L, 0);
    return 1;
  }
}

__attribute__((visibility("default"))) int luaopen_lua(lua_State *L) {
  static const luaL_Reg lib[] = {{NULL, NULL}};
  luaL_newlib(L, lib);
  return 1;
}
