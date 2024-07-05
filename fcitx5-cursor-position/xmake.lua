add_rules("plugin.compile_commands.autoupdate",{outputdir="./"})
add_rules("mode.debug", "mode.release")
target("fcitx5-cursor-position")
    set_kind("shared")
    add_includedirs("/usr/include/Fcitx5/Core")
    add_includedirs("/usr/include/Fcitx5/Config")
    add_includedirs("/usr/include/Fcitx5/Utils")
    add_files("src/*.cpp")

