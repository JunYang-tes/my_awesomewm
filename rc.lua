pcall(require, "luarocks.loader")
package.path = "/home/xiaobao/.config/awesome/lua/?.lua;" ..package.path
print(pcall(require,"main"))
