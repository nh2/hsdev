{-# LANGUAGE OverloadedStrings #-}

module HsDev.Cache (
	escapePath,
	cabalCache,
	projectCache,
	dump,
	load,
	toDatabase
	) where

import Control.Applicative
import Control.Monad (mzero)
import Data.Aeson
import qualified Data.ByteString.Lazy as BS
import Data.Char
import Data.List
import Data.Maybe
import Data.Map (Map)
import Data.Monoid
import qualified Data.Map as M
import System.Directory
import System.FilePath

import HsDev.Symbols
import HsDev.Project
import HsDev.Database

instance ToJSON Location where
	toJSON loc = object [
		"file" .= locationFile loc,
		"line" .= locationLine loc,
		"column" .= locationColumn loc]

instance FromJSON Location where
	parseJSON (Object v) = Location <$>
		v .: "file" <*>
		v .: "line" <*>
		v .: "column" <*>
		pure Nothing
	parseJSON _ = mzero

instance ToJSON Import where
	toJSON i = object [
		"name" .= importModuleName i,
		"qualified" .= importIsQualified i,
		"as" .= importAs i]

instance FromJSON Import where
	parseJSON (Object v) = Import <$>
		v .: "name" <*>
		v .: "qualified" <*>
		v .: "as"
	parseJSON _ = mzero

instance ToJSON a => ToJSON (Symbol a) where
	toJSON s = object [
		"name" .= symbolName s,
		"docs" .= symbolDocs s,
		"location" .= symbolLocation s,
		"symbol" .= symbol s]

instance FromJSON a => FromJSON (Symbol a) where
	parseJSON (Object v) = Symbol <$>
		v .: "name" <*>
		pure Nothing <*>
		v .: "docs" <*>
		v .: "location" <*>
		pure [] <*>
		v .: "symbol"
	parseJSON _ = mzero

instance ToJSON Cabal where
	toJSON x = toJSON $ case x of
		Cabal -> Nothing
		CabalDev p -> Just p

instance FromJSON Cabal where
	parseJSON = fmap (maybe Cabal CabalDev) . parseJSON

instance ToJSON Module where
	toJSON m = object [
		"exports" .= moduleExports m,
		"imports" .= moduleImports m,
		"declarations" .= moduleDeclarations m,
		"cabal" .= moduleCabal m]

instance FromJSON Module where
	parseJSON (Object v) = Module <$>
		v .: "exports" <*>
		v .: "imports" <*>
		v .: "declarations" <*>
		v .: "cabal"
	parseJSON _ = mzero

instance ToJSON TypeInfo where
	toJSON t = object [
		"ctx" .= typeInfoContext t,
		"args" .= typeInfoArgs t,
		"definition" .= typeInfoDefinition t]

instance FromJSON TypeInfo where
	parseJSON (Object v) = TypeInfo <$>
		v .: "ctx" <*>
		v .: "args" <*>
		v .: "definition"
	parseJSON _ = mzero

instance ToJSON Declaration where
	toJSON (Function t) = object [
		"what" .= ("function" :: String),
		"type" .= t]
	toJSON (Type i) = object [
		"what" .= ("type" :: String),
		"info" .= i]
	toJSON (NewType i) = object [
		"what" .= ("newtype" :: String),
		"info" .= i]
	toJSON (Data i) = object [
		"what" .= ("data" :: String),
		"info" .= i]
	toJSON (Class i) = object [
		"what" .= ("class" :: String),
		"info" .= i]

instance FromJSON Declaration where
	parseJSON (Object v) = do
		w <- fmap (id :: String -> String) $ v .: "what"
		i <- v .: "info"
		let
			ctor = case w of
				"type" -> Type
				"newtype" -> NewType
				"data" -> Data
				"class" -> Class
				_ -> error "Invalid data"
		return $ ctor i
	parseJSON _ = mzero

escapePath :: FilePath -> FilePath
escapePath = intercalate "." . map (filter (\c -> isAlpha c || isDigit c)) . splitDirectories

-- | Name of cache file for cabal
cabalCache :: Cabal -> FilePath
cabalCache Cabal = "cabal.json"
cabalCache (CabalDev p) = escapePath p ++ ".json"

-- | Name of cache file for projects
projectCache :: Project -> FilePath
projectCache p = escapePath (projectCabal p) ++ ".json"

-- | Dump cache data to file
dump :: FilePath -> Map String (Symbol Module) -> IO ()
dump file = BS.writeFile file . encode

-- | Load cache from file
load :: FilePath -> IO (Map String (Symbol Module))
load file = do
	cts <- BS.readFile file
	return $ fromMaybe M.empty $ decode cts

toDatabase :: Map String (Symbol Module) -> Database
toDatabase = mconcat . map fromModule . M.elems