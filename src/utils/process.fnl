(fn read-popen [cmd]
 (with-open [in (io.popen cmd)]
  (icollect [i v (in:lines)] i)))

(fn exec [cmd]
  (if (= (type cmd) :string)
    (let [f (io.popen cmd)
          (ret) (f:close )]
      (= ret true))
    false))

{: read-popen
 : exec }
