(local stringx (require :pl.stringx))
(fn split [str sep]
  (stringx.split str sep))
                
(fn starts-with [str prefix]
  (stringx.startswith str prefix)) 
                               
{
 : split
 : starts-with} 
 
