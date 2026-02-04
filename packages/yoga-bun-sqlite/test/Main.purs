module Test.BunSQLite.Main where

import Prelude

import Yoga.BunSQLite.BunSQLite as BunSQLite
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Test.Spec (Spec, before, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)

setupBunSQLite :: Aff BunSQLite.Database
setupBunSQLite = liftEffect $ BunSQLite.open (BunSQLite.DatabasePath ":memory:")

spec :: Spec Unit
spec = before setupBunSQLite do
  describe "Yoga.BunSQLite FFI" do
    describe "Basic Operations" do
      it "creates table and inserts data" \db -> do
        liftEffect $ BunSQLite.run "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)" db
        liftEffect $ BunSQLite.run "INSERT INTO test (name) VALUES ('Bob')" db
        rows <- liftEffect $ BunSQLite.query "SELECT * FROM test" db
        1 `shouldEqual` 1

main :: Effect Unit
main = launchAff_ $ runSpec [ consoleReporter ] spec
