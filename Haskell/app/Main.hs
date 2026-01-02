{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import qualified Data.ByteString.Char8 as C8
import qualified Data.ByteString.Lazy  as BL
import           Network.HTTP.Client
import           Network.HTTP.Client.TLS
import           Network.HTTP.Client.MultipartFormData
import           Network.HTTP.Types.Status (statusCode)
import           System.Environment (getArgs)

backgroundRemoval :: String -> FilePath -> FilePath -> IO ()
backgroundRemoval apiKey src dst = do
  manager <- newManager tlsManagerSettings
  baseReq <- parseRequest "https://api.backgrounderase.net/v2"

  -- ✅ no type signature on the left of `<-`
  reqWithBody <- formDataBody [partFileSource "image_file" src] baseReq
  -- If you really want a type annotation: 
  -- reqWithBody <- (formDataBody [partFileSource "image_file" src] baseReq :: IO Request)

  let req = reqWithBody
          { method = "POST"
          , requestHeaders = ("x-api-key", C8.pack apiKey) : requestHeaders reqWithBody
          }

  resp <- httpLbs req manager
  let code = statusCode (responseStatus resp)
  if code == 200
    then BL.writeFile dst (responseBody resp) >> putStrLn ("✅ Saved: " ++ dst)
    else do
      putStrLn $ "❌ " ++ show code
      BL.putStr (responseBody resp) >> putStrLn ""

main :: IO ()
main = do
  -- Usage: cabal run ben -- YOUR_API_KEY input.jpg output.png
  args <- getArgs
  case args of
    [apiKey, src, dst] -> backgroundRemoval apiKey src dst
    _ -> putStrLn "Usage: ben <API_KEY> <input-image> <output.png>"
