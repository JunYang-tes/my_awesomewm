(local process (require :utils.process))
(local inspect (require :inspect))
(local awful (require :awful))

(local shutdown
       {:label :shutdown
        :exec #(awful.spawn "sh -c \"shutdown now\"")})
(local reboot
  {:label :reboot
   :exec #(awful.spawn "sh - c \"reboot\"")})

(local suspend
  {:label :suspend
   :exec #(awful.spawn "pkexec systemctl suspend -i")})

(local switch-user
  {:label :switch-user
   :exec #(awful.spawn "dm-tool switch-to-greeter")})

(local battery
       {:label :battery
        :real-time #(table.concat (process.read-popen "acpi") "\n")
        :exec #$})

[battery shutdown suspend switch-user lock]
