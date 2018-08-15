module Main where

import qualified Data.Text.ICU.Normalize
import qualified Data.Text.IO

main :: IO ()
main = do
  txt <- Data.Text.IO.getLine
  Data.Text.IO.putStrLn (Data.Text.ICU.Normalize.normalize Data.Text.ICU.Normalize.NFC txt)
