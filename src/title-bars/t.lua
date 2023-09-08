local wibox     = require( "wibox"                   )
local awful     = require( "awful"                   )
--local rad_tag   = require( "radical.impl.common.tag" )
local beautiful = require( "beautiful"               )
--local radical   = require( "radical"                 )
--local rad_task  = require( "radical.impl.tasklist"   )
local chopped   = require( "chopped"                 )
local collision = require( "collision"               )
local color     = require( "gears.color"             )
--local infobg    = require( "radical.widgets.infoshapes" )
local shape     = require( "gears.shape")
{
       {
         {
               {
                  beautiful.titlebar_show_icon and wibox.widget.imagebox(c.icon) or nil,
                  title,
                  spacing = 4,
                  layout = wibox.layout.fixed.horizontal,
               },
               left   = 13                 ,
               right  = 13                 ,
               layout = wibox.container.margin,
         },
         id                 = "title_bg"                                  ,
         shape              = beautiful.titlebar_title_shape              ,
         shape_border_width = beautiful.titlebar_title_border_width       ,
         shape_border_color = beautiful.titlebar_title_border_color_active,
         bg                 = beautiful.titlebar_title_bg                 ,
         bgimage            = beautiful.titlebar_title_bgimage            ,
         buttons            = (align ~= "center") and buttons             ,
         layout             = wibox.container.background                  ,
      },
      align              = align,
      expand             = (align == "center") and "fill" or nil,
      spacing            = 10,
      id                 = "infoshapes",
      shape              = shape.hexagon,
      shape_bg           = beautiful.titlebar_underlay_bg or beautiful.underlay_bg or "#0C2853",
      shape_border_color = beautiful.titlebar_underlay_border_color,
      shape_border_width = beautiful.titlebar_underlay_border_width,
      fg                 = beautiful.titlebar_underlay_fg,
      widget             = infobg,
    }
