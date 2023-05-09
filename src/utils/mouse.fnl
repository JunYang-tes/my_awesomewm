(local LEFT-BUTTON 1)
(local RIGHT-BUTTON 3)
(local WHEEL-UP 4)
(local WHEEL-DOWN 5)
(local mouse _G.mouse)
(local root _G.root)

(fn move-to [x y]
  (mouse.coords {: x : y}))

(fn click [btn]
  (fn [x y]
    (mouse.coords {: x : y})
    (root.fake_input :button_press btn)
    (root.fake_input :button_release btn)))

(fn press [btn]
  (fn [x y]
    (mouse.coords {: x : y})
    (root.fake_input :button_press btn)))

(fn release [btn]
  (fn [x y]
    (mouse.coords {: x : y})
    (root.fake_input :button_release btn)))


{ : move-to
  :left-click (click LEFT-BUTTON)
  :right-click (click RIGHT-BUTTON)
  :press-left (press LEFT-BUTTON)
  :release-left (release LEFT-BUTTON)
  :press-right (press RIGHT-BUTTON)
  :release-right (press RIGHT-BUTTON)
  :wheel-up (click WHEEL-UP)
  :wheel-down (click WHEEL-DOWN)}
