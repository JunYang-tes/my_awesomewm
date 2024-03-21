(local process (require :utils.process))
(local inspect (require :inspect))
(local awful (require :awful))

(local shutdown
       {:label :Shutdown
        :exec #(awful.spawn "sh -c \"shutdown now\"")})
(local reboot
  {:label :Reboot
   :exec #(awful.spawn [:sh :-c "pkexec reboot"])})

(local suspend
  {:label :Suspend
   :exec #(awful.spawn [:sh :-c "pkexec systemctl suspend -i"])})

(local switch-user
  {:label "Switch user"
   :exec #(awful.spawn "dm-tool switch-to-greeter")})

(local battery
       {:label :Battery
        :real-time #(table.concat (process.read-popen "acpi") "\n")
        :exec #$})

[battery shutdown reboot suspend switch-user]
