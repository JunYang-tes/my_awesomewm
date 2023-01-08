(fn not-nil [val def]
  (if (not= val nil)
      val
      def))

(fn catched [f handle]
  (let [handle (or handle #(print :error-occured $1))]
    (fn [...]
      (let [(ok ret) (xpcall f debug.traceback ...)]
        (if ok
            ret
            (do
              (handle ret)
              nil))))))

{: not-nil
 : catched}
