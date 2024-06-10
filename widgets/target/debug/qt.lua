local qt = require("widgets").qt
local app = qt.app()
print("app",app);
local win = qt.win()
print("win",win);
local vbox = qt.vbox()
-- local line = qt.line_edit()
-- print("line",line);
-- vbox:add_widget(line:as_ptr())
-- print("line",line:as_ptr());
-- print("line",line:as_ptr());
print("add widget")
win:set_layout(vbox:as_ptr())
win:show()
print("set layout")
print("show")
app:exec()
