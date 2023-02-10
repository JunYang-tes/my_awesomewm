(local {: window
        : scrolled-window
        : flow-box
        : image} (require :gtk.node))
(local {: run} (require :lite-reactive.app))
(local list (require :utils.list))
(local icons 
    ["face-angry"
      "face-surprise"
      "face-laugh"
      "face-plain"
      "face-sad"
      "face-cool"
      "face-smirk"
      "face-sick"
      "face-kiss"
      "face-smile"])
(run
  (window 
    (scrolled-window
      (flow-box
        (-> (list.range 0 400 1)
            (list.map #(image { :icon_name (. icons (% $2 (length icons)))
                                :pixel_size 32})))))))
