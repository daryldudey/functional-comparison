module Main where

import Prelude
import Text.ParserCombinators.Parsec
import Data.CSV
import Data.List

data Activity = Activity String Double Double deriving Show
data Resource = Resource String Double Double deriving Show
data Allocation = Allocation String String Double deriving Show
data SchemaData = SchemaData [Activity] [Resource] [Allocation] deriving Show

earthRadius :: Double
earthRadius = 6367450.0 -- geometric mean value gives about .1% error
convert2Rad :: Double
convert2Rad = pi / 180.0
convert2Deg :: Double
convert2Deg = 180.0 / pi
seconds_per_metre :: Double
seconds_per_metre = 0.0559234073

distanceBetweenPointsLatLong :: Double -> Double -> Double -> Double -> Double 
distanceBetweenPointsLatLong lat1 lon1 lat2 lon2 =
  let dStartLatInRad = lat1 * convert2Rad
      dStartLongInRad = lon1 * convert2Rad
      dEndLatInRad = lat2 * convert2Rad
      dEndLongInRad = lon2 * convert2Rad
      dLongitude = dEndLongInRad - dStartLongInRad
      dLatitude = dEndLatInRad - dStartLatInRad
      dSinHalfLatitude = sin (dLatitude * 0.5)
      dSinHalfLongitude = sin (dLongitude * 0.5)
      a = dSinHalfLatitude * dSinHalfLatitude + cos(dStartLatInRad) * cos(dEndLatInRad) * dSinHalfLongitude * dSinHalfLongitude
      c = atan2 (sqrt a) (sqrt (1.0 - a))
      dist = earthRadius * (c + c)
  in dist

processRow :: [String] -> SchemaData -> SchemaData
processRow (x1 : x2 : [x3]) (SchemaData a r al) = SchemaData a ((Resource x1 (read x2) (read x3)) : r) al
processRow (x1 : x2 : x3 : [_]) (SchemaData a r al) = SchemaData ((Activity x1 (read x2) (read x3)) : a) r al

processCSV :: [[String]] -> SchemaData -> SchemaData
processCSV [] entities = entities
processCSV (x : xs) entities = processCSV xs $ processRow x entities

importCSV :: IO (Maybe SchemaData)
importCSV = 
  do 
    result <- parseFromFile csvFile "/Users/daryl/Source/SkylinedSoftware/Prototypes/PerformanceComparison/Data/DataSPIF.csv"
    let entities = case result of
                    (Left _) -> Nothing
                    (Right x) -> Just $ processCSV x $ SchemaData [] [] []
    return entities

scheduleResource :: Resource -> Int -> SchemaData -> IO SchemaData
scheduleResource _ 0 (SchemaData a r al) = 
  case length r of
    0 -> return (SchemaData a r al)
    _ -> scheduleResource (head r) 5 (SchemaData a (tail r) al)
scheduleResource resource count (SchemaData a r al) = do
  let (Resource rid lat lng) = resource
      dists = map (\ (Activity aid alat alng) -> (aid, distanceBetweenPointsLatLong lat lng alat alng)) a
      (caid, dist) = head $ sortBy (\ x y -> compare (snd x) (snd y)) dists
  scheduleResource resource (count - 1) (SchemaData (filter (\ (Activity aid _ _) -> aid /= caid) a) r ((Allocation rid caid dist) : al))

runMultiple :: Int -> SchemaData -> IO ()
runMultiple 0 _ = return ()
runMultiple count (SchemaData a r al) = do
  (SchemaData _ _ res_al) <- scheduleResource (head r) 5 (SchemaData a (tail r) al)
  let distances = map (\ (Allocation _ _ dist) -> dist) res_al
  let tot = foldl (+) 0.0 distances
  putStrLn $ show tot
  runMultiple (count - 1) (SchemaData a r al)

start :: Int -> IO ()
start count = do 
  entities <- importCSV
  case entities of
    Nothing -> putStrLn "Nothing"
    Just s -> do
      runMultiple count s

main :: IO ()
main = start 1000
