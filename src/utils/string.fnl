(local stringx (require :pl.stringx))
(fn split [str sep]
  (stringx.split str sep))
                
(fn starts-with [str prefix]
  (stringx.startswith str prefix)) 
(fn ends-with [str prefix]
  (stringx.endswith str prefix)) 
(fn includes [str sub]                               
  (not= (stringx.lfind str sub) 
        nil)) 
(fn replace [str old new]
  (stringx.replace str old new))
(fn is-empty [str]
  (or 
    (= nil str)
    (= 0
      (length
        (-> str
            stringx.strip)))))
{
 : split
 : starts-with 
 : ends-with
 : includes
 :last-index stringx.rfind
 :trim-start stringx.lstrip
 :trim-end stringx.rstrip
 : replace
 : is-empty}
 
