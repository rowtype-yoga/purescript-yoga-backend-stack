module Test.Pino.Main where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldSatisfy)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (runSpec)
import Yoga.Pino as Pino

spec :: Spec Unit
spec = do
  describe "Yoga.Pino FFI" do
    describe "Logger Creation" do
      it "creates pino logger" do
        _ <- liftEffect $ Pino.pino
        pure unit

      it "logs messages at different levels" do
        logger <- liftEffect $ Pino.pino
        liftEffect $ Pino.info logger "Test info message"
        liftEffect $ Pino.warn logger "Test warn message"
        pure unit

main :: Effect Unit
main = launchAff_ $ runSpec [ consoleReporter ] spec
