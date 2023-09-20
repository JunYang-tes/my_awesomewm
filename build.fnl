#! env fennel
(local inspect (require :inspect))
(local stringx (require :pl.stringx))

(fn read-popen [cmd]
 (with-open [in (io.popen cmd)]
  (icollect [i v (in:lines)] i)))

(fn get-change-time [file]
  (-> (read-popen
       (.. :stat " -c %Y " file))
      (. 1)
      tonumber))
(fn get-src-list []
  (let [files
        (read-popen "find src/ -name '*.fnl' ")
        src (icollect [_ v (ipairs files)]
              (if (not (stringx.startswith v :src/macros))
                v))]
    src))

(fn get-output-file [file]
  (-> file 
      (stringx.replace "src" "lua")
      (stringx.replace "fnl" "lua")))
(fn get-dir [path]
  (let [index (stringx.rfind path "/")]
    (string.sub path 1 index)))

(fn not-exits [file]
  (let [f (io.open file :r)]
    (if f
        (do 
          (io.close f)
          false)
      true)))

(fn test-should-be-compile [file]
  (let [tgt (get-output-file file)]
    (or
      (not-exits tgt)
      (> (get-change-time file)
         (get-change-time tgt)))))
(fn test-should-be-copy [file]
  (let [tgt (stringx.replace file "src" "lua")]
    (or
      (not-exits tgt)
      (> (get-change-time file)
         (get-change-time tgt)))))

(fn copy-asserts [postfix]
  (let [src-dir "src/"
        dist-dir "lua/"

        files (read-popen (.. "find " src-dir " -name *." postfix))]
    (each [_ file (ipairs files)]
      (let [dist (.. dist-dir (stringx.replace file src-dir ""))]
        (when (test-should-be-compile file)
          (print (.. "Copying " file " to " dist))
          (os.execute (.. "mkdir -p " (get-dir dist)))
          (os.execute (.. "cp " file " " dist)))))))

(fn compile [file]
  (print (.. "compiling " file))
  (let [tgt (get-output-file file)
        tgt-dir (get-dir tgt)]
    (os.execute (.. "mkdir -p " tgt-dir))
    (os.execute (.. :fennel " "
                    :--add-macro-path " \"./src/macros/?.fnl\" "
                    :--compile " " file
                    ">"
                    tgt))))

(fn run []
  (copy-asserts "png")
  (copy-asserts "jpg")
  (let [files (get-src-list)
        need-compile (icollect [_ v (ipairs files)]
                       (if (test-should-be-compile v) v))]
    (each [_ v (ipairs need-compile)]
      (compile v))))
(run)
