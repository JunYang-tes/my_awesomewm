#include "cairo.h"
#include "glib-object.h"
#include "glib.h"
#include "luaconf.h"
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
static Gwrapper *wrap_g_object(lua_State *L, GObject *w) {
  Gwrapper *ret = lua_newuserdata(L, sizeof(Gwrapper)); // [udata,...]
  const char *mt_name = G_OBJECT_TYPE_NAME(w);
  luaL_getmetatable(L, mt_name); //[mt,udata...]
  lua_setmetatable(L, -2);       //[udata...]
  ret->object = w;
  g_object_ref(w);
  return ret;
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
      printf("number (%d)", lua_tonumber(L, i));
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
static void get_event_callbacl(lua_State *L, void *key, const char *name) {
  lua_pushlightuserdata(L, key);      //[key,...]
  lua_gettable(L, LUA_REGISTRYINDEX); //[table,...]
  lua_getfield(L, -1, name);          // [fn,table]
}

static void on_map(GtkWidget *self, gpointer user_data) {
  lua_State *L = user_data;
  get_event_callbacl(L, self, "e_map");
  wrap_gtk_widget(L, self);
  lua_call(L, 1, 0);
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
  printf("[C}key pressed\n");
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  print_stack(L);
  get_event_callbacl(L, w, "e_key_pressed");
  print_stack(L);
  lua_pushinteger(L, keyval);
  lua_pushinteger(L, keycode);
  lua_pushinteger(L, state);
  print_stack(L);
  lua_call(L, 3, 1);
  return lua_toboolean(L, -1);
}
gboolean on_key_pressed_capture(GtkEventControllerKey *self, guint keyval,
                                guint keycode, GdkModifierType state,
                                gpointer user_data) {
  GtkWidget *w = gtk_event_controller_get_widget(GTK_EVENT_CONTROLLER(self));
  lua_State *L = user_data;
  print_stack(L);
  get_event_callbacl(L, w, "e_key_pressed_capture");
  print_stack(L);
  lua_pushinteger(L, keyval);
  lua_pushinteger(L, keycode);
  lua_pushinteger(L, state);
  print_stack(L);
  lua_call(L, 3, 1);
  return lua_toboolean(L, -1);
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
    {"grab_focus", widget_grab_focus},
    {"get_first_child", widget_get_first_child},
    {"set_size_request", widget_set_size_request},
    {"get_next_sibling", widget_get_next_sibling},
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
static void on_button_click(GtkButton *self, gpointer user_data) {
  lua_State *L = user_data;
  lua_pushlightuserdata(L, self);
  lua_gettable(L, LUA_REGISTRYINDEX);
  lua_call(L, 0, 0);
}
static int button_connect_click(lua_State *L) {
  Widget *w = (Widget *)lua_touserdata(L, 1);
  luaL_checktype(L, 2, LUA_TFUNCTION);
  g_signal_connect(w->widget, "clicked", G_CALLBACK(on_button_click), L);
  // stack:
  // lua_fn
  // userdata

  lua_pushlightuserdata(L, w->widget);
  // stack:
  // key
  // lua_fn
  // userdata
  lua_pushvalue(L, 2);
  // stack:
  // lua_fn
  // key
  // lua_fn
  // userdata
  lua_settable(L, LUA_REGISTRYINDEX);
  lua_pop(L, 2);

  return 0;
}
static int button_set_label(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkButton");
  const char *label = lua_tostring(L, 2);
  gtk_button_set_label(GTK_BUTTON(w->widget), label);
  return 0;
}
luaL_Reg button_methods[] = {{"connect_click", button_connect_click},
                             {"__gc", widget_gc},
                             {"set_label", button_set_label},
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
const luaL_Reg window_methods[] = {{"__gc", widget_gc},
                                   {"present", window_present},
                                   {"set_child", window_set_child},
                                   {"set_role", window_set_role},
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
  bool wrap = lua_tonumber(L, 2);
  gtk_label_set_wrap(GTK_LABEL(label->widget), wrap);
  return 0;
}
static int label_set_wrap_mode(lua_State *L) {
  Widget *label = (Widget *)luaL_checkudata(L, 1, "GtkLabel");
  bool wrap = lua_tonumber(L, 2);
  gtk_label_set_wrap_mode(GTK_LABEL(label->widget), wrap);
  return 0;
}
const luaL_Reg label_methods[] = {{"__gc", widget_gc},
                                  {"set_text", label_set_text},
                                  {"set_label", label_set_text},
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
static const luaL_Reg scrolled_win_methods[] = {
    {"__gc", widget_gc}, {"set_child", scroll_win_new_set_child}, {NULL, NULL}};

static GtkWidget *new_empty_listview() { return gtk_list_view_new(NULL, NULL); }
static int listview_new(lua_State *L) {
  return make_a_widget(L, new_empty_listview);
}
static int listview_set_moda(lua_State *L) {
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

void signal_item_on_bind(GtkSignalListItemFactory *self, GObject *object,
                         gpointer user_data) {
  GtkListItem *item = GTK_LIST_ITEM(object);

  lua_State *L = (lua_State *)user_data;
  lua_pushlightuserdata(L, self);
  lua_gettable(L, LUA_REGISTRYINDEX); //[table ..]
  lua_rawgeti(L, -1, 2);              // [bind table ]
  //
  wrap_gtk_widget(L, gtk_list_item_get_child(item)); // [chid,bind,table ...]

  const char *content = gtk_string_object_get_string(

      GTK_STRING_OBJECT(gtk_list_item_get_item(item)));
  lua_pushstring(L, content); // [list-data,child,bind ...]

  lua_call(L, 2, 0);
}
void signal_item_on_setup(GtkSignalListItemFactory *self, GObject *object,
                          gpointer user_data) {
  GtkListItem *item = GTK_LIST_ITEM(object);

  lua_State *L = (lua_State *)user_data;
  lua_pushlightuserdata(L, self);
  lua_gettable(L, LUA_REGISTRYINDEX); // [table ..]
  luaL_checktype(L, -1, LUA_TTABLE);
  lua_rawgeti(L, -1, 1); // [setup table ...]
  luaL_checktype(L, -1, LUA_TFUNCTION);
  lua_call(L, 0, 1);
  luaL_checktype(L, -1, LUA_TUSERDATA);
  void *p = lua_touserdata(L, -1);
  gtk_list_item_set_child(item, ((Widget *)p)->widget);
}
static int signal_item_factory_new(lua_State *L) {
  if (lua_gettop(L) != 2) {
    lua_pushliteral(L, "Too few arguemnts to create SignalItemFactory");
    lua_error(L);
    return 0;
  }
  luaL_checktype(L, 1, LUA_TFUNCTION); // setup callback (Lua fn)
  luaL_checktype(L, 2, LUA_TFUNCTION); // bind callback (Lua fn)

  GtkWrapper *wrapper = (GtkWrapper *)lua_newuserdata(L, sizeof(GtkWrapper));

  luaL_getmetatable(L, "GtkSignalItemFactory");
  lua_setmetatable(L, -2);

  wrapper->fields[0] = gtk_signal_list_item_factory_new();

  lua_createtable(L, 2, 0); // [table .. bind setup]
  lua_pushvalue(L, 1);      // [setup table .. bind setup]
  lua_rawseti(L, -2, 1);    // table[1]=setup

  lua_pushvalue(L, 2);   // [bind table .. ]
  lua_rawseti(L, -2, 2); // table[2]=bind

  lua_pushlightuserdata(L, wrapper->fields[0]); // [ludata,table ...]
  lua_pushvalue(L, -2);                         // [table,ludata,table ...]
  lua_settable(L, LUA_REGISTRYINDEX); // registry[ludata] = table,[table ...]

  g_signal_connect(wrapper->fields[0], "setup",
                   G_CALLBACK(signal_item_on_setup), L);
  g_signal_connect(wrapper->fields[0], "bind", G_CALLBACK(signal_item_on_bind),
                   L);
  lua_pop(L, 1);

  return 1;
}

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
  get_event_callbacl(L, self, "e_text_change");
  GtkEntryBuffer *buffer = gtk_entry_get_buffer(self);
  const char *s = gtk_entry_buffer_get_text(buffer);
  lua_pushstring(L, s);

  lua_call(L, 1, 0);
  lua_settop(L, 1);
}
static int entry_connect_changed(lua_State *L) {
  Widget *w = (Widget *)luaL_checkudata(L, 1, "GtkEntry");
  put_event_callback_to_registry(L, w->widget, "e_text_change");
  g_signal_connect(w->widget, "changed", G_CALLBACK(on_entry_text_changed), L);
  return 0;
}
static const luaL_Reg entry_methods[] = {
    {"__gc", widget_gc},          {"connect_changed", entry_connect_changed},
    {"text", entry_get_text},     {"connect_change", entry_connect_changed},
    {"set_text", entry_set_text}, {NULL, NULL}};

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
const static luaL_Reg picture_methods[] = {
    {"__gc", widget_gc}, {"set_texture", picture_set_texture}, {NULL, NULL}};

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

  const luaL_Reg listview[] = {{"set_model", listview_set_moda},
                               {"set_factory", listview_set_item_factory},
                               {"scroll_to", listview_scroll_to},
                               {NULL, NULL}};
  setup_metatable(L, "GtkListView", listview);

  const luaL_Reg signal_item[] = {{NULL, NULL}};
  setup_metatable(L, "GtkSignalItemFactory", signal_item);

  const luaL_Reg *entry[] = {widget_apis, entry_methods, NULL};
  setup_metatable_(L, "GtkEntry", entry);
  const luaL_Reg *button[] = {widget_apis, button_methods, NULL};
  setup_metatable_(L, "GtkButton", button);
  const luaL_Reg *picture[] = {widget_apis, picture_methods, NULL};
  setup_metatable_(L, "GtkPicture", picture);

  static const luaL_Reg mylib[] = {
      {"app", gtk_app},
      {"box", box_new},
      {"button", button_new},
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
      {"texture_from_cairo_ptr", texture_from_cairo_ptr},
      {NULL, NULL}};
  luaL_newlib(L, mylib);
  return 1;
}
