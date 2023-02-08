(local process (require :utils.process))
(local inspect (require :inspect))
(local awful (require :awful))
(local shutdown
       {:label :shutdown
        :exec #(awful.spawn "sh -c \"shutdown now\"")})
(local battery
       {:label :battery
        :real-time #(table.concat (process.read-popen "acpi") "\n")
        :exec #$})

[battery shutdown]
