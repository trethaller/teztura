module Main (test, main)
where

import FFI
import Prelude

data JQuery
instance Show JQuery

alert :: String -> Fay ()
alert = ffi "window.alert(%1)"

trace :: String -> Fay ()
trace = ffi "console.log('[FAY]', %1)"

--jSelect :: String -> Fay JQuery
--jSelect = ffi "jQuery(%1)"

getContext :: JQuery -> Fay JQuery
getContext = ffi "%1.getContext('2d')"

getCanvas :: String -> Fay JQuery
getCanvas = ffi "jQuery(%1)[0]"

getWidth :: JQuery -> Fay Int
getWidth = ffi "%1.width"
getHeight :: JQuery -> Fay Int
getHeight = ffi "%1.height"

getSize :: JQuery -> Fay (Int, Int)
getSize j = do 
  w <- getWidth j
  h <- getHeight j
  return (w,h)

test :: Fay ()
test = do
  can <- getCanvas "#canvas"
  c2d <- getContext can
  size <- getSize can

  --lol <- j "window['jQuery']"
  let (w, h) = size
  trace $ (show w) ++ " " ++ (show h)

main :: Fay()
main = test
