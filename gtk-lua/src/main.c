#include "cairo.h"
#include "gdk/gdk.h"
#include "gio/gio.h"
#include "glib-object.h"
#include "glib.h"
#include "luaconf.h"
#include "pango/pango-layout.h"
#include <gtk-4.0/gtk/gtkcssprovider.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>

#include <gdk/x11/gdkx.h>
#include <gtk/gtk.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <string.h>

typedef struct Gwrapper {
  GObject *object;
} Gwrapper;
typedef struct Widget {
  GtkWidget *widget;
} Widget;

#define MY_LIBRARY_EXPORT __attribute__((visibility("default")))
#define dup_stack_top(L) (lua_pushvalue((L), -1))

#define paramless_retvoid(widget, fname)                                       \
  static int widget##_##fname(lua_State *L) {                                  \
    Widget *w = lua_touserdata(L, 1);                                          \
    gtk_##widget_##fname(w->widget);                                           \
    return 0;                                                                  \
  };
static Gwrapper *wrap_g_object_with_name(lua_State *L, GObject *w,
                                         const char *name) {
  Gwrapper *ret = lua_newuserdata(L, sizeof(Gwrapper)); // [udata,...]
  luaL_getmetatable(L, name);                           //[mt,udata...]
  lua_setmetatable(L, -2);                              //[udata...]
  ret->object = w;
  g_object_ref(w);
  return ret;
}
static Gwrapper *wrap_g_object(lua_State *L, GObject *w) {
  const char *mt_name = G_OBJECT_TYPE_NAME(w);
  return wrap_g_object_with_name(L, w, mt_name);
}
static int gwrapper_gc(lua_State *L) {
  Gwrapper *w = lua_touserdata(L, 1);
  GObject *obj = G_OBJECT(w->object);
  g_object_unref(w->object);
  if (obj->ref_count == 0) {
    // clear registry
    lua_pushlightuserdata(L, w->object);
    lua_pushnil(L);
    lua_settable(L, LUA_REGISTRYINDEX);
  }
  return obj->ref_count;
}

static Widget *wrap_gtk_widget(lua_State *L, GtkWidget *w) {
  Widget *ret = lua_newuserdata(L, sizeof(Widget)); // [udata,...]

  const char *mt_name = G_OBJECT_TYPE_NAME(w);
  luaL_getmetatable(L, mt_name); //[mt,udata...]
  lua_setmetatable(L, -2);       //[udata...]
  ret->widget = w;
  g_object_ref(w);
  return ret;
}

// widget
static int widget_get_first_child(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  GtkWidget *child = gtk_widget_get_first_child(w->widget);
  wrap_gtk_widget(L, child);
  return 1;
}
static int widget_get_next_sibling(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  GtkWidget *next = gtk_widget_get_next_sibling(w->widget);
  wrap_gtk_widget(L, next);
  return 1;
}
static int widget_set_size_request(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  int width = (int)lua_tonumber(L, 2);
  int height = (int)lua_tonumber(L, 3);
  gtk_widget_set_size_request(w->widget, width, height);
  return 0;
}
static int widget_gc(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  GObject *obj = G_OBJECT(w->widget);
  g_object_unref(w->widget);
  if (obj->ref_count == 0) {
    // clear registry
    lua_pushlightuserdata(L, w->widget);
    lua_pushnil(L);
    lua_settable(L, LUA_REGISTRYINDEX);
  }
  return obj->ref_count;
}
static int widget_set_vexpand(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  bool expand = lua_toboolean(L, 2);
  gtk_widget_set_vexpand(w->widget, expand);
  return 0;
}
static int widget_set_hexpand(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  bool expand = lua_toboolean(L, 2);
  gtk_widget_set_hexpand(w->widget, expand);
  return 0;
}
static int widget_grab_focus(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  gtk_widget_grab_focus(w->widget);
  return 0;
}
static int widget_address(lua_State *L) {
  Widget *w = lua_touserdata(L, 1);
  lua_pushinteger(L, (lua_Integer)w->widget);
  return 1;
}
static void print_stack(lua_State *L) {
  int i = 1;
  int c = lua_gettop(L);
  printf("[%d] ", c);
  while (i <= c) {
    switch (lua_type(L, i)) {
    case LUA_TNIL:
      printf("nil ");
      break;
    case LUA_TBOOLEAN:
      printf("bool(%d) ", lua_toboolean(L, i));
      break;
    case LUA_TLIGHTUSERDATA:
      printf("ld ");
      break;
    case LUA_TNUMBER:
      printf("number (%lld)", lua_tointeger(L, i));
      break;
    case LUA_TSTRING:
      printf("str(%s) ", lua_tostring(L, i));
      break;
    case LUA_TTABLE:
      printf("tbl ");
      break;
    case LUA_TFUNCTION:
      printf("fn ");
      break;
    case LUA_TUSERDATA:
      printf("udata ");
      break;
    case LUA_TTHREAD:
      printf("thread ");
      break;
    }
    i++;
  }
  printf("\n");
}
static void put_event_callback_to_registry(lua_State *L, void *key,
                                           const char *name) {
  luaL_checktype(L, -1, LUA_TFUNCTION); //[fn ..]
  lua_pushlightuserdata(L, key);        //[key,fn]
  lua_gettable(L, LUA_REGISTRYINDEX);   //[table/nil,fn]
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);                      // [fn]
    lua_pushlightuserdata(L, key);      // [key,fn]
    lua_newtable(L);                    //[table,key,fn...]
    lua_settable(L, LUA_REGISTRYINDEX); //[fn ...]
    lua_pushlightuserdata(L, key);      // [key,fn...]
    lua_gettable(L, LUA_REGISTRYINDEX); // [table,fn..]
  }
  lua_pushvalue(L, -2);      //[fn,table,fn ...]
  lua_setfield(L, -2, name); // [table,fn,...]
  lua_pop(L, 1);             //[fn...]
}

/**
 * put the stack top to a registry by key, queue name is specificed by name
 * registry[key] =  tbl
 * tbl[name] = [stack top ]
 * */
static void put_to_registry_q(lua_State *L, void *key, const char *name) {
  if (lua_gettop(L) == 0) {
    lua_pushstring(L, "lua stack is empty");
    lua_error(L);
    return;
  }
  lua_pushlightuserdata(L, key);      //[key,val]
  lua_gettable(L, LUA_REGISTRYINDEX); //[table/nil,val]
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);                      // [val]
    lua_pushlightuserdata(L, key);      // [key,val]
    lua_newtable(L);                    //[table,key,val...]
    lua_settable(L, LUA_REGISTRYINDEX); //[val ...]
    lua_pushlightuserdata(L, key);      // [key,val...]
    lua_gettable(L, LUA_REGISTRYINDEX); // [table,val..]
  }
  lua_getfield(L, -1, name); // [queue/nil,table,val ...]
  if (lua_type(L, -1) == LUA_TNIL) {
    lua_pop(L, 1);             // [table,val,...]
    lua_createtable(L, 1, 0);  //[queue,table,val...]
    lua_setfield(L, -2, name); //[table,val, ...]
    lua_getfield(L, -1, name); // [queue,table]
  }
  lua_len(L, -1); // [q-size,queue,table,val ...]
  LUA_INTEGER size = lua_tointeger(L, -1);
  lua_pop(L, 1); //[q,table,val]
  // q[size+1] = val

  lua_pushvalue(L, -3);         // [val,q,table,val ...]
  lua_rawseti(L, -2, size + 1); // [q,table,val]
  lua_pop(L, 3);
}
static void registry_q_pop(lua_State *L, void *key, const char *q_name) {
  lua_pushlightuserdata(L, key);      //[key,...]
  lua_gettable(L, LUA_REGISTRYINDEX); //[table,...]
  lua_getfield(L, -1, q_name);        // [q,table]
  lua_len(L, -1);                     //[size,q,table]
  LUA_INTEGER size = lua_tointeger(L, -1);
  lua_pop(L, 1);         // [q,table...]
  lua_geti(L, -1, size); //[val,q,table]
  lua_pushnil(L);        //[nil,val,q,table]
  lua_seti(L, -3, size); //[val,q,table]
  lua_remove(L, -2);     //[val,q...]
  lua_remove(L, -2);     // [val,...]
}

static void get_event_callback(lua_State *L, void *key, const char *name) {
  lua_pushlightuserdata(L, key);      //[key,...]
  lua_gettable(L, LUA_REGISTRYINDEX); //[table,...]
  lua_getfield(L, -1, name);          // [fn,table]
  lua_remove(L, -2);                  // remove the register table
}
static void clear_event_callback(lua_State *L, void *key, const char *name) {
  lua_pushlightuserdata(L, key);      //[key,...]
  lua_gettable(L, LUA_REGISTRYINDEX); //[table,...]
  lua_pushnil(L);                     //[nil,table...]
  lua_setfield(L, -2, name);          // [table ...]
  lua_pop(L, -1);
}

static void on_map(GtkWidget *self, gpointer user_data) {
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, self, "e_map");
  wrap_gtk_widget(L, self);
  lua_call(L, 1, 0);
  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
}
static int widget_connect_map(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  put_event_callback_to_registry(L, w->widget, "e_map");
  g_signal_connect(w->widget, "map", G_CALLBACK(on_map), L);
  return 0;
}
gboolean on_key_pressed(GtkEventControllerKey *self, guint keyval,
                        guint keycode, GdkModifierType state,
                        gpointer user_data) {
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  get_event_callback(L, w, "e_key_pressed");
  lua_pushinteger(L, keyval);
  lua_pushinteger(L, keycode);
  lua_pushinteger(L, state);
  lua_call(L, 3, 1);
  bool processed = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return processed;
}
gboolean on_key_pressed_capture(GtkEventControllerKey *self, guint keyval,
                                guint keycode, GdkModifierType state,
                                gpointer user_data) {
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  get_event_callback(L, w, "e_key_pressed_capture");
  lua_pushinteger(L, keyval);
  lua_pushinteger(L, keycode);
  lua_pushinteger(L, state);
  wrap_gtk_widget(L, w);
  lua_call(L, 4, 1);
  bool processed = lua_toboolean(L, -1);
  lua_pop(L, -1);
  return processed;
}

static int widget_connect_key_pressed(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  put_event_callback_to_registry(L, w->widget, "e_key_pressed");
  GtkEventController *key_event = gtk_event_controller_key_new();
  g_signal_connect(key_event, "key_pressed", G_CALLBACK(on_key_pressed), L);
  gtk_widget_add_controller(w->widget, key_event);
  return 0;
}
static int widget_connect_key_pressed_capture(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  put_event_callback_to_registry(L, w->widget, "e_key_pressed_capture");
  GtkEventController *key_event = gtk_event_controller_key_new();
  g_signal_connect(key_event, "key_pressed", G_CALLBACK(on_key_pressed_capture),
                   L);
  gtk_widget_add_controller(w->widget, key_event);
  gtk_event_controller_set_propagation_phase(key_event, GTK_PHASE_CAPTURE);
  return 0;
}
void on_focus_out(GtkEventControllerFocus *self, gpointer user_data) {
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, w, "e_focus_out");
  lua_call(L, 0, 0);

  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
}

static int widget_connect_focus_out(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  put_event_callback_to_registry(L, w->widget, "e_focus_out");
  GtkEventController *controller = gtk_event_controller_focus_new();
  g_signal_connect(controller, "leave", G_CALLBACK(on_focus_out), L);
  gtk_widget_add_controller(w->widget, controller);
  return 0;
}
void on_mouse_move(GtkEventControllerMotion *self, gdouble x, gdouble y,
                   gpointer user_data) {
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, w, "e_mouse_move");
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_call(L, 2, 0);

  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
}

static int widget_connect_move(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  put_event_callback_to_registry(L, w->widget, "e_mouse_move");
  GtkEventController *controller = gtk_event_controller_motion_new();
  g_signal_connect(controller, "motion", G_CALLBACK(on_mouse_move), L);
  gtk_widget_add_controller(w->widget, controller);
  return 0;
}

void on_click_released(GtkGestureClick *self, gint n_press, gdouble x,
                       gdouble y, gpointer user_data) {
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, w, "e_click_release");
  lua_call(L, 0, 0);

  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
}

static int widget_connect_click_released(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  put_event_callback_to_registry(L, w->widget, "e_click_release");
  GtkEventController *controller =
      GTK_EVENT_CONTROLLER(gtk_gesture_click_new());
  g_signal_connect(controller, "released", G_CALLBACK(on_click_released), L);
  gtk_widget_add_controller(w->widget, controller);
  return 0;
}

static int widget_set_visible(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  bool visible = lua_toboolean(L, 2);
  gtk_widget_set_visible(w->widget, visible);
  return 0;
}
static int widget_add_css_class(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  const char *css = lua_tostring(L, 2);
  gtk_widget_add_css_class(w->widget, css);
  return 0;
}
static int widget_remove_css_class(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  const char *css = lua_tostring(L, 2);
  gtk_widget_remove_css_class(w->widget, css);
  return 0;
}
static int widget_set_halign(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  int align = lua_tonumber(L, 2);
  gtk_widget_set_halign(w->widget, align);
  return 0;
}
static int widget_set_valign(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  int align = lua_tonumber(L, 2);
  gtk_widget_set_valign(w->widget, align);
  return 0;
}
static int widget_overflow(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  GtkOverflow overflow = lua_tonumber(L, 2);
  gtk_widget_set_overflow(w->widget, overflow);
  return 0;
}
static int widget_get_height(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  int height = gtk_widget_get_height(w->widget);
  lua_pushnumber(L, height);
  return 1;
}
static int widget_get_width(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  int width = gtk_widget_get_width(w->widget);
  lua_pushnumber(L, width);
  return 1;
}

const luaL_Reg widget_apis[] = {
    {"set_hexpand", widget_set_hexpand},
    {"set_vexpand", widget_set_vexpand},
    {"add_css_class", widget_add_css_class},
    {"remove_css_class", widget_remove_css_class},
    {"set_visible", widget_set_visible},
    {"connect_map", widget_connect_map},
    {"address", widget_address},
    {"connect_key_pressed", widget_connect_key_pressed},
    {"connect_key_pressed_capture", widget_connect_key_pressed_capture},
    {"connect_focus_out", widget_connect_focus_out},
    {"connect_click_release", widget_connect_click_released},
    {"connect_mouse_move", widget_connect_move},
    {"grab_focus", widget_grab_focus},
    {"get_first_child", widget_get_first_child},
    {"set_size_request", widget_set_size_request},
    {"get_next_sibling", widget_get_next_sibling},
    {"set_valign", widget_set_valign},
    {"set_halign", widget_set_halign},
    {"set_overflow", widget_overflow},
    {"get_height", widget_get_height},
    {"get_width", widget_get_width},
    {NULL, NULL}};

typedef GtkWidget *(*widget_factory)();
static inline int make_a_widget(lua_State *L, widget_factory factory) {
  Widget *w = (Widget *)lua_newuserdata(L, sizeof(Widget)); //[udata ...]
  GtkWidget *widget = factory();
  const char *name = G_OBJECT_TYPE_NAME(widget);
  luaL_getmetatable(L, name); //[mt udata ...]
  lua_setmetatable(L, -2);    // [udata ...]
  w->widget = factory();
  g_object_ref(w->widget);
  return 1;
}

static int button_new(lua_State *L) { return make_a_widget(L, gtk_button_new); }
static int button_from_icon_name(lua_State *L) {
  const char *name = lua_tostring(L, 1);
  GtkWidget *w = gtk_button_new_from_icon_name(name);
  wrap_gtk_widget(L, w);
  return 1;
}
static void on_button_click(GtkButton *self, gpointer user_data) {
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, self, "e_click");
  lua_call(L, 0, 0);
  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
}
static int button_connect_click(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  luaL_checktype(L, 2, LUA_TFUNCTION);
  put_event_callback_to_registry(L, w->widget, "e_click");
  g_signal_connect(w->widget, "clicked", G_CALLBACK(on_button_click), L);

  return 0;
}
static int button_set_label(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkButton");
  const char *label = lua_tostring(L, 2);
  gtk_button_set_label(GTK_BUTTON(w->widget), label);
  return 0;
}
static int button_set_icon_name(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkButton");
  const char *name = lua_tostring(L, 2);
  gtk_button_set_icon_name(GTK_BUTTON(w->widget), name);
  return 0;
}
luaL_Reg button_methods[] = {{"connect_click", button_connect_click},
                             {"__gc", widget_gc},
                             {"set_label", button_set_label},
                             {"set_icon_name", button_set_icon_name},
                             {NULL, NULL}};

typedef struct App {
  GMainContext *g_main_ctx;
} App;

static int gtk_app(lua_State *L) {
  App *app = (App *)lua_newuserdata(L, sizeof(App));

  luaL_getmetatable(L, "GtkApp");
  lua_setmetatable(L, -2);
  GMainContext *g_main_ctx = g_main_context_default();
  gtk_init();
  app->g_main_ctx = g_main_ctx;
  return 1;
}
static int gtk_app_iteration(lua_State *L) {
  App *app = luaL_checkudata(L, 1, "GtkApp");
  bool block = lua_toboolean(L, 2);
  lua_pop(L, 2);
  g_main_context_iteration(app->g_main_ctx, block);
  return 0;
}
static int gtk_app_gc(lua_State *L) {
  App *app = luaL_checkudata(L, 1, "GtkApp");
  g_main_context_unref(app->g_main_ctx);
  return 0;
}
static int gtk_app_run(lua_State *L) {
  App *app = luaL_checkudata(L, 1, "GtkApp");
  while (true)
    g_main_context_iteration(app->g_main_ctx, true);
  return 0;
}

typedef struct GtkWrapper {
  void *fields[4];
} GtkWrapper;

static int window_new(lua_State *L) { return make_a_widget(L, gtk_window_new); }
static int window_close(lua_State *L) {
  Widget *win = (Widget *)luaL_checkudata(L, 1, "GtkWindow");
  gtk_window_close(GTK_WINDOW(win->widget));
  return 0;
}
static int window_set_child(lua_State *L) {
  Widget *win = (Widget *)luaL_checkudata(L, 1, "GtkWindow");
  Widget *p = lua_touserdata(L, 2);
  gtk_window_set_child(GTK_WINDOW(win->widget),
                       GTK_WIDGET(((Widget *)p)->widget));
  return 0;
}
static int window_present(lua_State *L) {
  Widget *win = (Widget *)luaL_checkudata(L, 1, "GtkWindow");
  gtk_window_present(GTK_WINDOW(win->widget));
  return 0;
}
static int window_set_role(lua_State *L) {
  Widget *win = (Widget *)luaL_checkudata(L, 1, "GtkWindow");
  const char *role = lua_tostring(L, 2);
  GdkSurface *surf = gtk_native_get_surface(GTK_NATIVE(win->widget));
  GdkDisplay *display = gdk_surface_get_display(surf);
  gdk_x11_surface_set_utf8_property(surf, "WM_WINDOW_ROLE", role);
  return 0;
}
static int window_set_title(lua_State *L) {
  Widget *win = (Widget *)luaL_checkudata(L, 1, "GtkWindow");
  const char *title = lua_tostring(L, 2);
  gtk_window_set_title(GTK_WINDOW(win->widget), title);
  return 0;
}
gboolean handle_close_request(GtkWindow *self, gpointer user_data) {
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, self, "e_close_request");
  lua_call(L, 0, 1);
  gboolean b = lua_toboolean(L, -1);
  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
  return b;
}
static int window_connect_close_request(lua_State *L) {
  Widget *win = (Widget *)luaL_checkudata(L, 1, "GtkWindow");
  put_event_callback_to_registry(L, win->widget, "e_close_request");
  g_signal_connect(win->widget, "close-request",
                   G_CALLBACK(handle_close_request), L);
  return 0;
}
const luaL_Reg window_methods[] = {
    {"__gc", widget_gc},
    {"present", window_present},
    {"set_title", window_set_title},
    {"set_child", window_set_child},
    {"set_role", window_set_role},
    {"connect_close_request", window_connect_close_request},
    {"close", window_close},
    {NULL, NULL}};

static int label_new(lua_State *L) {
  Widget *label = (Widget *)lua_newuserdata(L, sizeof(Widget));
  luaL_getmetatable(L, "GtkLabel");
  lua_setmetatable(L, -2);
  label->widget = gtk_label_new(NULL);
  g_object_ref(label->widget);
  return 1;
}
static int label_set_text(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  const char *s = luaL_checkstring(L, 2);
  gtk_label_set_text(GTK_LABEL(label->widget), s);
  return 0;
}
static int label_set_markup(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  const char *s = luaL_checkstring(L, 2);
  gtk_label_set_markup(GTK_LABEL(label->widget), s);
  return 0;
}
static int label_set_xalign(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  double xalign = lua_tonumber(L, 2);
  gtk_label_set_xalign(GTK_LABEL(label->widget), xalign);
  return 0;
}
static int label_set_wrap(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  bool wrap = lua_toboolean(L, 2);
  gtk_label_set_wrap(GTK_LABEL(label->widget), wrap);
  return 0;
}
static int label_set_wrap_mode(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  bool wrap = lua_tonumber(L, 2);
  gtk_label_set_wrap_mode(GTK_LABEL(label->widget), wrap);
  return 0;
}
static int label_set_ellipsize(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  PangoEllipsizeMode mode = lua_tonumber(L, 2);
  gtk_label_set_ellipsize(GTK_LABEL(label->widget), mode);
  return 0;
}
const luaL_Reg label_methods[] = {{"__gc", widget_gc},
                                  {"set_text", label_set_text},
                                  {"set_label", label_set_text},
                                  {"set_ellipsize", label_set_ellipsize},
                                  {"set_wrap", label_set_wrap},
                                  {"set_wrap_mode", label_set_wrap_mode},
                                  {"set_xalign", label_set_xalign},
                                  {"set_markup", label_set_markup},
                                  {NULL, NULL}};

static GtkWidget *create_vbox() {
  return gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
}

static int box_new(lua_State *L) { return make_a_widget(L, create_vbox); }
static int box_set_orientation(lua_State *L) {
  Widget *box = (Widget *)luaL_checkudata(L, 1, "GtkBox");
  int orientation = lua_tonumber(L, 2);
  gtk_orientable_set_orientation(GTK_ORIENTABLE(box->widget), orientation);
  return 0;
}
static int box_append(lua_State *L) {
  Widget *box = (Widget *)luaL_checkudata(L, 1, "GtkBox");
  Widget *p = (Widget *)lua_touserdata(L, 2);
  gtk_box_append(GTK_BOX(box->widget), p->widget);
  return 0;
}
static int box_remove(lua_State *L) {
  Widget *box = (Widget *)luaL_checkudata(L, 1, "GtkBox");
  Widget *p = (Widget *)lua_touserdata(L, 2);
  gtk_box_remove(GTK_BOX(box->widget), p->widget);
  return 0;
}
static int box_set_spacing(lua_State *L) {
  Widget *box = (Widget *)luaL_checkudata(L, 1, "GtkBox");
  int space = (int)lua_tonumber(L, 2);
  gtk_box_set_spacing(GTK_BOX(box->widget), space);
  return 0;
}
static int box_set_homogeneous(lua_State *L) {
  Widget *box = (Widget *)luaL_checkudata(L, 1, "GtkBox");
  bool b = lua_toboolean(L, 2);
  gtk_box_set_homogeneous(GTK_BOX(box->widget), b);
  return 0;
}
static int box_remove_all_children(lua_State *L) {
  Widget *box = (Widget *)luaL_checkudata(L, 1, "GtkBox");
  GtkWidget *child = gtk_widget_get_first_child(box->widget);
  while (child) {
    gtk_box_remove(GTK_BOX(box->widget), child);
    child = gtk_widget_get_first_child(box->widget);
  }
  return 0;
}
static const luaL_Reg box_methods[] = {
    {"__gc", widget_gc},
    {"append", box_append},
    {"remove", box_remove},
    {"remove_all_children", box_remove_all_children},
    {"set_spacing", box_set_spacing},
    {"set_homogeneous", box_set_homogeneous},
    {"set_orientation", box_set_orientation},
    {NULL, NULL}};

static int scroll_win_new(lua_State *L) {
  return make_a_widget(L, gtk_scrolled_window_new);
}
static int scroll_win_new_set_child(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkScrolledWindow");
  Widget *p = (Widget *)lua_touserdata(L, 2);
  gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(w->widget), p->widget);
  return 1;
}
static int scrolled_window_set_hpolicy(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkScrolledWindow");
  GtkPolicyType htype;
  GtkPolicyType vtype;
  gtk_scrolled_window_get_policy(GTK_SCROLLED_WINDOW(w->widget), &htype,
                                 &vtype);
  htype = lua_tonumber(L, 2);
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(w->widget), htype, vtype);
  return 0;
}
static int scrolled_window_set_vpolicy(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkScrolledWindow");
  GtkPolicyType htype;
  GtkPolicyType vtype;
  gtk_scrolled_window_get_policy(GTK_SCROLLED_WINDOW(w->widget), &htype,
                                 &vtype);
  vtype = lua_tonumber(L, 2);
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(w->widget), htype, vtype);
  return 0;
}
static int scroll_win_set_max_content_width(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkScrolledWindow");
  lua_Integer width = lua_tonumber(L, 2);
  gtk_scrolled_window_set_max_content_width(GTK_SCROLLED_WINDOW(w->widget),
                                            width);
  return 0;
}
static const luaL_Reg scrolled_win_methods[] = {
    {"__gc", widget_gc},
    {"set_child", scroll_win_new_set_child},
    {"set_hpolicy", scrolled_window_set_hpolicy},
    {"set_vpolicy", scrolled_window_set_vpolicy},
    {"set_max_content_width", scroll_win_new_set_child},
    {NULL, NULL}};

static GtkWidget *new_empty_listview() { return gtk_list_view_new(NULL, NULL); }
static int listview_new(lua_State *L) {
  return make_a_widget(L, new_empty_listview);
}
static int listview_set_model(lua_State *L) {
  int argc = lua_gettop(L);
  if (argc != 2) {
    return 0;
  }

  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkListView");
  luaL_checktype(L, 2, LUA_TTABLE);
  lua_len(L, 2);
  int cnt = lua_tonumber(L, 3);
  lua_pop(L, 1);

  GtkStringList *list_model = gtk_string_list_new(NULL);
  int i = 1;
  while (i <= cnt) {
    lua_rawgeti(L, -1, i);
    const char *s = luaL_checkstring(L, -1);
    lua_pop(L, 1);
    gtk_string_list_append(list_model, s);
    i++;
  }
  GtkSelectionModel *m =
      GTK_SELECTION_MODEL(gtk_no_selection_new(G_LIST_MODEL(list_model)));
  gtk_list_view_set_model(GTK_LIST_VIEW(w->widget), m);
  return 0;
}
static int listview_update_model(lua_State *L) {
  int argc = lua_gettop(L);
  if (argc != 2) {
    return 0;
  }

  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkListView");
  luaL_checktype(L, 2, LUA_TTABLE);
  lua_len(L, 2);
  int cnt = lua_tonumber(L, 3);
  lua_pop(L, 1);

  GtkStringList *list_model = gtk_string_list_new(NULL);
  int i = 1;
  while (i <= cnt) {
    lua_rawgeti(L, -1, i);
    const char *s = luaL_checkstring(L, -1);
    lua_pop(L, 1);
    gtk_string_list_append(list_model, s);
    i++;
  }
  GtkNoSelection *m =
      GTK_NO_SELECTION(gtk_list_view_get_model(GTK_LIST_VIEW(w->widget)));
  gtk_no_selection_set_model(m, G_LIST_MODEL(list_model));

  return 0;
}

static int listview_set_item_factory(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkListView");
  GtkWrapper *wrapper =
      (GtkWrapper *)luaL_checkudata(L, 2, "GtkSignalItemFactory");
  gtk_list_view_set_factory(GTK_LIST_VIEW(w->widget),
                            GTK_LIST_ITEM_FACTORY(wrapper->fields[0]));
  return 0;
}
static int listview_scroll_to(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkListView");
  guint pos = (guint)luaL_checknumber(L, 2);
  GtkListScrollFlags flag = (GtkListScrollFlags)luaL_checknumber(L, 3);
  gtk_list_view_scroll_to(GTK_LIST_VIEW(w->widget), pos, flag, NULL);
  return 0;
}
static void signal_item_on_teardown(GtkSignalListItemFactory *self,
                                    GObject *object, gpointer user_data) {
  // static int teardown_count = 0 ;
  // printf("td %d\n",++teardown_count);
  GtkListItem *item = GTK_LIST_ITEM(object);
  lua_State *L = (lua_State *)user_data;
  int stack_size = lua_gettop(L);
  lua_pushlightuserdata(L, self);
  lua_gettable(L, LUA_REGISTRYINDEX); //[table ..]
  lua_rawgeti(L, -1, 3);              // [teardown table ]
  //
  lua_pushlightuserdata(L, (void *)object); // [ludata,teardown,table]
  lua_gettable(L, LUA_REGISTRYINDEX);       // [child teardown table]
  //
  // wrap_gtk_widget(L, gtk_list_item_get_child(item)); // [chid,bind,table ...]
  lua_call(L, 1, 0);

  // clear child in registry
  lua_pushlightuserdata(L, (void *)object);
  lua_pushnil(L);
  lua_settable(L, LUA_REGISTRYINDEX);

  int should_pop = lua_gettop(L) - stack_size;
  if (should_pop > 0) {
    lua_pop(L, should_pop);
  }
}

void signal_item_on_bind(GtkSignalListItemFactory *self, GObject *object,
                         gpointer user_data) {
  GtkListItem *item = GTK_LIST_ITEM(object);

  lua_State *L = (lua_State *)user_data;
  int stack_size = lua_gettop(L);
  lua_pushlightuserdata(L, self);
  lua_gettable(L, LUA_REGISTRYINDEX); //[table ..]
  lua_rawgeti(L, -1, 2);              // [bind table ]
  //
  wrap_gtk_widget(L, gtk_list_item_get_child(item)); // [chid,bind,table ...]

  const char *content = gtk_string_object_get_string(

      GTK_STRING_OBJECT(gtk_list_item_get_item(item)));
  lua_pushstring(L, content); // [list-data,child,bind ...]

  lua_call(L, 2, 0);
  int should_pop = lua_gettop(L) - stack_size;
  if (should_pop > 0) {
    lua_pop(L, should_pop);
  }
}
void signal_item_on_unbind(GtkSignalListItemFactory *self, GObject *object,
                           gpointer user_data) {
  GtkListItem *item = GTK_LIST_ITEM(object);

  lua_State *L = (lua_State *)user_data;
  int stack_size = lua_gettop(L);
  lua_pushlightuserdata(L, self);
  lua_gettable(L, LUA_REGISTRYINDEX); //[table ..]
  lua_rawgeti(L, -1, 4);              // [bind table ]
  //
  wrap_gtk_widget(L, gtk_list_item_get_child(item)); // [chid,bind,table ...]

  const char *content = gtk_string_object_get_string(

      GTK_STRING_OBJECT(gtk_list_item_get_item(item)));
  lua_pushstring(L, content); // [list-data,child,bind ...]

  lua_call(L, 2, 0);
  int should_pop = lua_gettop(L) - stack_size;
  if (should_pop > 0) {
    lua_pop(L, should_pop);
  }
}
void signal_item_on_setup(GtkSignalListItemFactory *self, GObject *object,
                          gpointer user_data) {
  GtkListItem *item = GTK_LIST_ITEM(object);

  lua_State *L = (lua_State *)user_data;
  int stack_size = lua_gettop(L);
  lua_pushlightuserdata(L, self);     // [ludata ...]
  lua_gettable(L, LUA_REGISTRYINDEX); // [table ...]
  luaL_checktype(L, -1, LUA_TTABLE);
  lua_rawgeti(L, -1, 1); // [setup table ...]
  luaL_checktype(L, -1, LUA_TFUNCTION);
  lua_call(L, 0, 1); // [r ...]
  luaL_checktype(L, -1, LUA_TUSERDATA);
  void *p = lua_touserdata(L, -1); //[r ...]
  gtk_list_item_set_child(item, ((Widget *)p)->widget);

  lua_pushlightuserdata(L, (void *)item); // [ldata r ...]
  lua_pushvalue(L, -2);                   // [returned ludata ...]
  lua_settable(L, LUA_REGISTRYINDEX);     // register[ludata] = returned

  int should_pop = lua_gettop(L) - stack_size;
  if (should_pop > 0) {
    lua_pop(L, should_pop);
  }
}
static int signal_item_factory_new(lua_State *L) {
  if (lua_gettop(L) < 4) {
    lua_pushliteral(L, "Too few arguemnts to create SignalItemFactory");
    lua_error(L);
    return 0;
  }
  luaL_checktype(L, 1, LUA_TFUNCTION); // setup callback (Lua fn)
  luaL_checktype(L, 2, LUA_TFUNCTION); // bind callback (Lua fn)
  luaL_checktype(L, 3, LUA_TFUNCTION); // teardown callback (Lua fn)
  luaL_checktype(L, 4, LUA_TFUNCTION); // unbind

  GtkWrapper *wrapper = (GtkWrapper *)lua_newuserdata(L, sizeof(GtkWrapper));

  luaL_getmetatable(L, "GtkSignalItemFactory");
  lua_setmetatable(L, -2);

  wrapper->fields[0] = gtk_signal_list_item_factory_new();

  lua_createtable(L, 2, 0); // [table .. bind setup]
  lua_pushvalue(L, 1);      // [setup table .. bind setup]
  lua_rawseti(L, -2, 1);    // table[1]=setup

  lua_pushvalue(L, 2);   // [bind table .. ]
  lua_rawseti(L, -2, 2); // table[2]=bind

  lua_pushvalue(L, 3);   // [teardown table ...]
  lua_rawseti(L, -2, 3); // table[3] = teardown

  lua_pushvalue(L, 4);   // [unbind table ...]
  lua_rawseti(L, -2, 4); // table[4]=unbind

  lua_pushlightuserdata(L, wrapper->fields[0]); // [ludata,table ...]
  lua_pushvalue(L, -2);                         // [table,ludata,table ...]
  lua_settable(L, LUA_REGISTRYINDEX); // registry[ludata] = table,[table ...]

  g_signal_connect(wrapper->fields[0], "setup",
                   G_CALLBACK(signal_item_on_setup), L);
  g_signal_connect(wrapper->fields[0], "bind", G_CALLBACK(signal_item_on_bind),
                   L);
  g_signal_connect(wrapper->fields[0], "unbind",
                   G_CALLBACK(signal_item_on_unbind), L);
  g_signal_connect(wrapper->fields[0], "teardown",
                   G_CALLBACK(signal_item_on_teardown), L);
  lua_pop(L, 1);

  return 1;
}
static int listview_set_show_separators(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkListView");
  gboolean show_sep = lua_toboolean(L, 2);
  gtk_list_view_set_show_separators(GTK_LIST_VIEW(w->widget), show_sep);
  return 0;
}
const luaL_Reg listview_methods[] = {
    {"set_model", listview_set_model},
    {"set_factory", listview_set_item_factory},
    {"update_model", listview_update_model},
    {"scroll_to", listview_scroll_to},
    {"set_show_separators", listview_set_show_separators},
    {NULL, NULL}};

static int entry_new(lua_State *L) { return make_a_widget(L, gtk_entry_new); }
static int entry_set_text(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkEntry");
  const char *s = lua_tostring(L, 2);
  GtkEntryBuffer *buf = gtk_entry_get_buffer(GTK_ENTRY(w->widget));
  gtk_entry_buffer_set_text(buf, s, strlen(s));
  return 0;
}
static int entry_get_text(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkEntry");
  GtkEntryBuffer *buf = gtk_entry_get_buffer(GTK_ENTRY(w->widget));
  const char *s = gtk_entry_buffer_get_text(buf);
  lua_pushstring(L, s);
  return 1;
}
static void on_entry_text_changed(GtkEntry *self, gpointer user_data) {
  lua_State *L = user_data;
  int stack_size = lua_gettop(L);
  get_event_callback(L, self, "e_text_change");
  GtkEntryBuffer *buffer = gtk_entry_get_buffer(self);
  const char *s = gtk_entry_buffer_get_text(buffer);
  lua_pushstring(L, s);
  lua_call(L, 1, 0);
  int shrink = lua_gettop(L) - stack_size;
  if (shrink > 0) {
    lua_pop(L, shrink);
  }
}
static int entry_connect_changed(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkEntry");
  put_event_callback_to_registry(L, w->widget, "e_text_change");
  g_signal_connect(w->widget, "changed", G_CALLBACK(on_entry_text_changed), L);
  return 0;
}
static int entry_set_placeholder(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkEntry");
  const char *placeholder = lua_tostring(L, 2);
  gtk_entry_set_placeholder_text(GTK_ENTRY(w->widget), placeholder);
  return 0;
}
static const luaL_Reg entry_methods[] = {
    {"__gc", widget_gc},
    {"connect_changed", entry_connect_changed},
    {"text", entry_get_text},
    {"connect_change", entry_connect_changed},
    {"set_placeholder", entry_set_placeholder},
    {"set_text", entry_set_text},
    {NULL, NULL}};

static void setup_metatable(lua_State *L, const char *name,
                            const luaL_Reg *items) {
  luaL_newmetatable(L, name);
  dup_stack_top(L);
  lua_setfield(L, -2, "__index"); // mt.__index = mt

  int i = 0;
  while (items[i].name != NULL) {
    lua_pushcfunction(L, items[i].func);
    lua_setfield(L, -2, items[i].name);
    i++;
  }
  lua_pop(L, 1);
}
static void setup_metatable_(lua_State *L, const char *name,
                             const luaL_Reg *items[]) {
  luaL_newmetatable(L, name);
  dup_stack_top(L);
  lua_setfield(L, -2, "__index"); // mt.__index = mt

  int i = 0;
  while (items[i] != NULL) {
    const luaL_Reg *curr = items[i];
    int j = 0;
    while (curr[j].name != NULL) {
      lua_pushcfunction(L, curr[j].func);
      lua_setfield(L, -2, curr[j].name);
      j++;
    }
    i++;
  }
  lua_pop(L, 1);
}

static int texture_from_file(lua_State *L) {
  const char *filepath = luaL_checkstring(L, 1);
  GError *err = NULL;
  GdkTexture *texture = gdk_texture_new_from_filename(filepath, &err);
  if (err) {
    g_printerr("Error loading texture: %s\n", err->message);
    lua_pushstring(L, err->message);
    g_error_free(err);
    lua_error(L);
  }
  wrap_g_object(L, G_OBJECT(texture));
  return 1;
}
static int texture_from_bytes(lua_State *L) {
  size_t len;
  const char *data = luaL_checklstring(L, 1, &len);
  GBytes *bytes = g_bytes_new(data, len);
  GdkTexture *texture = gdk_texture_new_from_bytes(bytes, NULL);
  if (texture == NULL) {
    printf("[gtk-lua] Failed to load image\n");
    g_bytes_unref(bytes);
    return 0;
  } else {
    wrap_g_object(L, G_OBJECT(texture));
    g_bytes_unref(bytes);
    return 1;
  }
}
static inline GdkMemoryFormat cairo_fmt_to_gdk_fmt(cairo_format_t fmt) {
  if (fmt == CAIRO_FORMAT_ARGB32) {
    return GDK_MEMORY_B8G8R8A8;
  } else if (fmt == CAIRO_FORMAT_RGB24) {
    return GDK_MEMORY_B8G8R8;
  } else if (fmt == CAIRO_FORMAT_A8) {
    return GDK_MEMORY_A8;
  }
  return GDK_MEMORY_A8;
}
static int texture_from_cairo_ptr(lua_State *L) {
  cairo_surface_t *ptr = (void *)(long)lua_tonumber(L, 1);
  int width = cairo_image_surface_get_width(ptr);
  int height = cairo_image_surface_get_height(ptr);
  int stride = cairo_image_surface_get_stride(ptr);

  cairo_format_t fmt = cairo_image_surface_get_format(ptr);
  unsigned char *data = cairo_image_surface_get_data(ptr);
  if (data == NULL) {
    lua_pushstring(L,
                   "@texture_from_cairo_ptr: invalid cairo image surface data");
    lua_error(L);
  }
  GBytes *gbytes = g_bytes_new(data, height * stride);
  wrap_g_object(L,
                G_OBJECT(gdk_memory_texture_new(
                    width, height, cairo_fmt_to_gdk_fmt(fmt), gbytes, stride)));
  g_bytes_unref(gbytes);
  return 1;
}

static int texture_save(lua_State *L) {
  Gwrapper *texture = lua_touserdata(L, 1);
  const char *path = lua_tostring(L, 2);
  gdk_texture_save_to_png(GDK_TEXTURE(texture->object), path);
  return 0;
}
static int texture_save_bytes(lua_State *L) {
  Gwrapper *texture = lua_touserdata(L, 1);
  GBytes *data = gdk_texture_save_to_png_bytes(GDK_TEXTURE(texture->object));
  gsize size;
  const char *bytes = g_bytes_get_data(data, &size);
  lua_pushlstring(L, bytes, size);
  free(data);
  return 1;
}
static luaL_Reg texture_methods[] = {{"__gc", gwrapper_gc},
                                     {"save", texture_save},
                                     {"save_bytes", texture_save_bytes},
                                     {NULL, NULL}};

static int picture_new(lua_State *L) {
  return make_a_widget(L, gtk_picture_new);
}
static int picture_set_texture(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkPicture");
  Gwrapper *texture = lua_touserdata(L, 2);
  gtk_picture_set_paintable(GTK_PICTURE(w->widget),
                            GDK_PAINTABLE(texture->object));
  return 0;
}
static int picture_set_content_fit(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkPicture");
  int fit = lua_tonumber(L, 2);
  gtk_picture_set_content_fit(GTK_PICTURE(w->widget), fit);
  return 0;
}
static int picture_set_can_shrink(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkPicture");
  gboolean shrink = lua_toboolean(L, 2);
  gtk_picture_set_can_shrink(GTK_PICTURE(w->widget), shrink);
  return 0;
}
const static luaL_Reg picture_methods[] = {
    {"__gc", widget_gc},
    {"set_texture", picture_set_texture},
    {"set_content_fit", picture_set_content_fit},
    {"set_can_shrink", picture_set_can_shrink},
    {NULL, NULL}};

static int overlay_new(lua_State *L) {
  return make_a_widget(L, gtk_overlay_new);
}
static int overlay_set_child(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkOverlay");
  Widget *c = lua_touserdata(L, 2);
  gtk_overlay_set_child(GTK_OVERLAY(w->widget), c->widget);
  return 0;
}
static int overlay_set_overlay(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkOverlay");
  Widget *c = lua_touserdata(L, 2);
  gtk_overlay_add_overlay(GTK_OVERLAY(w->widget), c->widget);
  return 0;
}
const static luaL_Reg overlay_methods[] = {{"__gc", widget_gc},
                                           {"set_child", overlay_set_child},
                                           {"set_overlay", overlay_set_overlay},
                                           {NULL, NULL}};
static int fixed_new(lua_State *L) { return make_a_widget(L, gtk_fixed_new); }
static int fixed_add_child(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkFixed");
  Widget *c = lua_touserdata(L, 2);
  double x = lua_tonumber(L, 3);
  double y = lua_tonumber(L, 4);
  gtk_fixed_put(GTK_FIXED(w->widget), c->widget, x, y);
  return 0;
}
static int fixed_move(lua_State *L) {
  Widget *w = luaL_checkudata(L, 1, "GtkFixed");
  Widget *c = lua_touserdata(L, 2);
  double x = lua_tonumber(L, 3);
  double y = lua_tonumber(L, 4);
  gtk_fixed_move(GTK_FIXED(w->widget), c->widget, x, y);
  return 0;
}
static int fixed_remove_all_children(lua_State *L) {
  Widget *container = (Widget *)luaL_checkudata(L, 1, "GtkFixed");
  GtkWidget *child = gtk_widget_get_first_child(container->widget);
  while (child) {
    gtk_fixed_remove(GTK_FIXED(container->widget), child);
    child = gtk_widget_get_first_child(container->widget);
  }
  return 0;
}

const static luaL_Reg fixed_methods[] = {
    {"__gc", widget_gc},
    {"add_child", fixed_add_child},
    {"move", fixed_move},
    {"remove_all_children", fixed_remove_all_children},
    {NULL, NULL}};

void css_parsing_error(GtkCssProvider *self, GtkCssSection *section,
                       GError *error, gpointer user_data) {
  printf("[C] css error: %s", error->message);
}
static int load_css(lua_State *L) {
  const char *css = luaL_checkstring(L, 1);
  GtkCssProvider *provider = gtk_css_provider_new();
  GdkDisplay *display = gdk_display_get_default();
  gtk_css_provider_load_from_string(provider, css);
  gtk_style_context_add_provider_for_display(
      display, GTK_STYLE_PROVIDER(provider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  Gwrapper *wrapper = lua_newuserdata(L, sizeof(Gwrapper));
  wrapper->object = G_OBJECT(provider);
  g_signal_connect(provider, "parsing-error", G_CALLBACK(css_parsing_error),
                   NULL);
  lua_createtable(L, 0, 1);          // [table,udata]
  lua_pushcfunction(L, gwrapper_gc); // [gc,table,udata]
  lua_setfield(L, -2, "__gc");       // [table,udata]
  lua_setmetatable(L, -2);
  return 1;
}

static int clipboard_new(lua_State *L) {
  GdkDisplay *display = gdk_display_get_default();
  GdkClipboard *clipboard = gdk_display_get_clipboard(display);
  wrap_g_object_with_name(L, G_OBJECT(clipboard), "GdkClipboard");
  return 1;
}

void gdk_clipboard_read_text_callback(GObject *source_object, GAsyncResult *res,
                                      gpointer data) {
  lua_State *L = data;
  registry_q_pop(L, source_object, "get_text");
  char *txt =
      gdk_clipboard_read_text_finish(GDK_CLIPBOARD(source_object), res, NULL);
  lua_pushstring(L, txt);
  free(txt);
  lua_call(L, 1, 0);
}

static int clipboard_get_text(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  put_to_registry_q(L, w->object, "get_text");
  gdk_clipboard_read_text_async(GDK_CLIPBOARD(w->object), NULL,
                                gdk_clipboard_read_text_callback, L);
  return 0;
}

void gdk_clipboard_read_texture_callback(GObject *source_object,
                                         GAsyncResult *res, gpointer data) {
  lua_State *L = data;
  registry_q_pop(L, source_object, "get_texture");
  GdkTexture *texture = gdk_clipboard_read_texture_finish(
      GDK_CLIPBOARD(source_object), res, NULL);
  wrap_g_object(L, G_OBJECT(texture));
  lua_call(L, 1, 0);
}

static int clipboard_get_texture(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  put_to_registry_q(L, w->object, "get_texture");
  gdk_clipboard_read_texture_async(GDK_CLIPBOARD(w->object), NULL,
                                   gdk_clipboard_read_texture_callback, L);
  return 0;
}

void clipboard_changed(GdkClipboard *self, gpointer user_data) {
  lua_State *L = user_data;
  get_event_callback(L, self, "changed");
  lua_call(L, 0, 0);
}

static int clipboard_connect_change(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  put_event_callback_to_registry(L, w->object, "changed");
  g_signal_connect(G_OBJECT(w->object), "changed",
                   G_CALLBACK(clipboard_changed), L);
  return 0;
}
static int clipboard_set_text(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  const char *txt = lua_tostring(L, 2);
  g_signal_handlers_disconnect_by_func(G_OBJECT(w->object),
                                       G_CALLBACK(clipboard_changed), L);
  gdk_clipboard_set_text(GDK_CLIPBOARD(w->object), txt);
  g_signal_connect(G_OBJECT(w->object), "changed",
                   G_CALLBACK(clipboard_changed), L);
  return 0;
}
static int clipboard_set_texture(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  Gwrapper *texture = lua_touserdata(L, 2);
  g_signal_handlers_disconnect_by_func(G_OBJECT(w->object),
                                       G_CALLBACK(clipboard_changed), L);
  gdk_clipboard_set_texture(GDK_CLIPBOARD(w->object),
                            GDK_TEXTURE(texture->object));
  g_signal_connect(G_OBJECT(w->object), "changed",
                   G_CALLBACK(clipboard_changed), L);
  return 0;
}
static int clipboard_get_content(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  GdkContentProvider *p = gdk_clipboard_get_content(GDK_CLIPBOARD(w->object));
  lua_pushlightuserdata(L, p);
  return 1;
}
static int clipboard_set_text_content(lua_State *L) {
  // [GdkClipboard,mime_types,content]
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  g_signal_handlers_disconnect_by_func(G_OBJECT(w->object),
                                       G_CALLBACK(clipboard_changed), L);

  const char *content = lua_tostring(L, 3);
  GBytes *bytes = g_bytes_new(content, strlen(content));
  lua_len(L, 2);
  LUA_INTEGER len = lua_tointeger(L, -1);
  lua_pop(L, 1);
  GdkContentProvider **providers = malloc(len * sizeof(GdkContentProvider *));
  for (int i = 0; i < len; i++) {
    lua_rawgeti(L, 2, i + 1);
    const char *mime = lua_tostring(L, -1);
    lua_pop(L, 1);
    providers[i] = gdk_content_provider_new_for_bytes(mime, bytes);
  }

  GdkContentProvider *provider = gdk_content_provider_new_union(providers, len);
  gdk_clipboard_set_content(GDK_CLIPBOARD(w->object), provider);
  g_object_unref(provider);
  g_bytes_unref(bytes);

  g_signal_connect(G_OBJECT(w->object), "changed",
                   G_CALLBACK(clipboard_changed), L);
  return 0;
}
static int clipboard_get_mime_type(lua_State *L) {
  Gwrapper *w = luaL_checkudata(L, 1, "GdkClipboard");
  GdkContentFormats *fmt = gdk_clipboard_get_formats(GDK_CLIPBOARD(w->object));
  const char *const *mime_types = gdk_content_formats_get_mime_types(fmt, NULL);
  lua_createtable(L, 5, 0);
  int i = 0;
  if (mime_types) {
    while (mime_types[i] != NULL) {
      lua_pushstring(L, mime_types[i]);
      i++;
      lua_rawseti(L, -2, i);
    }
  }
  return 1;
}
static const luaL_Reg clipboard_methods[] = {
    {"__gc", gwrapper_gc},
    {"get_text", clipboard_get_text},
    {"set_text", clipboard_set_text},
    {"set_text_content", clipboard_set_text_content},
    {"get_texture", clipboard_get_texture},
    {"set_texture", clipboard_set_texture},
    {"get_mime_types", clipboard_get_mime_type},
    {"connect_changed", clipboard_connect_change},
    {NULL, NULL},
};

MY_LIBRARY_EXPORT int luaopen_lua(lua_State *L) {
  const luaL_Reg *gtkapp_[] = {widget_apis, NULL};
  const luaL_Reg gtkapp[] = {{"__gc", gtk_app_gc},
                             {"iteration", gtk_app_iteration},
                             {"run", gtk_app_run},
                             {NULL, NULL}};

  setup_metatable(L, "GtkApp", gtkapp);
  const luaL_Reg *win[] = {widget_apis, window_methods, NULL};
  setup_metatable_(L, "GtkWindow", win);
  const luaL_Reg *label[] = {widget_apis, label_methods, NULL};
  setup_metatable_(L, "GtkLabel", label);
  const luaL_Reg *box_[] = {widget_apis, box_methods, NULL};
  setup_metatable_(L, "GtkBox", box_);

  const luaL_Reg *scrolled[] = {widget_apis, scrolled_win_methods, NULL};
  setup_metatable_(L, "GtkScrolledWindow", scrolled);

  const luaL_Reg *listview[] = {widget_apis, listview_methods, NULL};
  setup_metatable_(L, "GtkListView", listview);

  const luaL_Reg signal_item[] = {{NULL, NULL}};
  setup_metatable(L, "GtkSignalItemFactory", signal_item);

  const luaL_Reg *entry[] = {widget_apis, entry_methods, NULL};
  setup_metatable_(L, "GtkEntry", entry);
  const luaL_Reg *button[] = {widget_apis, button_methods, NULL};
  setup_metatable_(L, "GtkButton", button);
  const luaL_Reg *picture[] = {widget_apis, picture_methods, NULL};
  setup_metatable_(L, "GtkPicture", picture);

  const luaL_Reg *clipboard[] = {clipboard_methods, NULL};
  setup_metatable_(L, "GdkClipboard", clipboard);
  const luaL_Reg *texture[] = {texture_methods, NULL};
  setup_metatable_(L, "GdkTexture", texture);
  setup_metatable_(L, "GdkMemoryTexture", texture);
  const luaL_Reg *overlay[] = {widget_apis, overlay_methods, NULL};
  setup_metatable_(L, "GtkOverlay", overlay);
  const luaL_Reg *fixed[] = {widget_apis, fixed_methods, NULL};
  setup_metatable_(L, "GtkFixed", fixed);

  static const luaL_Reg mylib[] = {
      {"app", gtk_app},
      {"box", box_new},
      {"clipboard", clipboard_new},
      {"button", button_new},
      {"icon_button", button_from_icon_name},
      {"scrolled_win", scroll_win_new},
      {"picture", picture_new},
      {"win", window_new},
      {"label", label_new},
      {"entry", entry_new},
      {"text_box", entry_new},
      {"listview", listview_new},
      {"list_view", listview_new},
      {"signal_item_factory", signal_item_factory_new},
      {"texture_from_file", texture_from_file},
      {"texture_from_bytes", texture_from_bytes},
      {"texture_from_cairo_ptr", texture_from_cairo_ptr},
      {"load_css", load_css},
      {"fixed", fixed_new},
      {"overlay", overlay_new},
      {NULL, NULL}};
  luaL_newlib(L, mylib);
  return 1;
}
