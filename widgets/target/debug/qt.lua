local qt = require("widgets").qt
local app = qt.app()
print("app",app);
local win = qt.win()
local vbox = qt.vbox()
win:set_layout(vbox:as_ptr())
--
local data ={}

for v in io.popen("ps aux"):lines() do 
  table.insert(data,v)
  -- table.insert(data,v)
  -- table.insert(data,v)
  -- table.insert(data,v)
end




local line = qt.line_edit()
vbox:add_widget(line:as_ptr())
line:on_text_edited(function(line) 
  relist(data)
end)
local btn = qt.button()
btn:set_text("I'm button")
btn:on_clicked(function(b) 
  collectgarbage()
end)
vbox:add_widget(btn:as_ptr())
--
local list = qt.list();
vbox:add_widget(list:as_ptr());


function relist(data) 
  print("recreate list:",#data)
  local a = os.clock()
  list:clear()
  refs = {}

  for i,line in ipairs(data) do
      local btn = qt.button();
      btn:set_text(line)
      list:add_item( btn:as_ptr());
      table.insert(refs,btn)
  end
  local b = os.clock()
  print((b-a) * 1000)
end
relist(data)

--
--
app:exec()