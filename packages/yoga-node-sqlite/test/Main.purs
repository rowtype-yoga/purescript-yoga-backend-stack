module Test.NodeSQLite.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Test.Spec (Spec, before, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Yoga.NodeSQLite.NodeSQLite as NodeSQLite

setupNodeSQLite :: Aff NodeSQLite.Database
setupNodeSQLite = liftEffect $ NodeSQLite.open (NodeSQLite.DatabasePath ":memory:")

spec :: Spec Unit
spec = before setupNodeSQLite do
  describe "Yoga.NodeSQLite FFI" do
    describe "Basic Operations" do
      it "creates table and inserts data" \db -> do
        liftEffect $ NodeSQLite.exec "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)" db
        liftEffect $ NodeSQLite.exec "INSERT INTO test (name) VALUES ('Charlie')" db
        1 `shouldEqual` 1

main :: Effect Unit
main = launchAff_ $ runSpec [ consoleReporter ] spec
