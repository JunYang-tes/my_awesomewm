(local stringx (require :pl.stringx))
(fn split [str sep]
  (stringx.split str sep))
                
(fn starts-with [str prefix]
  (stringx.startswith str prefix)) 
(fn includes [str sub]                               
  (not= (stringx.lfind str sub) 
        nil)) 
{
 : split
 : starts-with 
 : includes } 
 
