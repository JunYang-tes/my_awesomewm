(fn mk-test [name tests]
  `(tset test ,name 
         (fn []
           ,tests)))
{
 : mk-test}
