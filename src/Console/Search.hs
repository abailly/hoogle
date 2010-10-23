{-# LANGUAGE RecordWildCards #-}

module Console.Search(actionSearch) where

import CmdLine.All
import Data.TagStr
import General.Code
import Hoogle


actionSearch :: CmdLine -> Query -> IO ()
actionSearch flags q = do
    (missing,dbs) <- loadQueryDatabases (databases flags) q
    unless (null missing) $
        error $ "Could not find some databases: " ++ unwords missing

    let sug = querySuggestions dbs q
    when (isJust sug) $
        putStrLn $ showTag $ fromJust sug
    when verbose $ putStrLn "= ANSWERS ="

    when (color flags) $
        putStrLn $ "Searching for: " ++ showTag (renderQuery q)

    let res = search dbs q
    if null res then
        putStrLn "No results found"
     else if info flags then do
        let Result{..} = snd $ head res
        putStrLns 2 $ f $ head res
        putStrLns 2 $ showTag docs
        when (isJust package) $ putStrLn $ "From package " ++ snd (fromJust package)
        putStrLns 1 $ showTag $ snd self
     else
        putStr $ unlines $ map f res
    where
        search | start2 == 0 && count2 == maxBound = searchAll
               | otherwise = searchRange (start2,start2+count2-1)
            where start2 = maybe 0 (subtract 1) $ start flags
                  count2 = fromMaybe maxBound $ count flags

        showTag = if color flags then showTagConsole else showTagText
        verbose = False

        f (s,Result{..}) = maybe "" (\m -> snd m ++ " ") modul ++
                           showTag (snd self) ++ (if verbose then "  -- " ++ show s else "")


-- Put out a string with some blank links following
-- Do not put out the blank lines if no text output
putStrLns :: Int -> String -> IO ()
putStrLns n xs = when (xs /= "") $ do
                     putStr xs
                     putStr $ replicate n '\n'