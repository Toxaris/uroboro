module Uroboro.InterpreterSpec
    (
      spec
    ) where

import Test.Hspec
import Text.Parsec (parse)

import Paths_uroboro (getDataFileName)
import Uroboro.Checker (typecheck, inferExp)
import Uroboro.CheckerSpec (prelude)
import Uroboro.Interpreter (pmatch, eval)
import Uroboro.Parser (parseDef, parseExp)
import Uroboro.Tree.Internal

import Utils (parseString)

rules :: IO Rules
rules = do
    fname <- getDataFileName "samples/prelude.uro"
    input <- readFile fname
    case parse parseDef fname input of
        Left _ -> fail "Parser"
        Right defs -> case typecheck defs of
            Left _ -> fail "Checker"
            Right p -> return p

main :: String -> IO Exp
main input = do
    pexp <- parseString parseExp input
    prog <- prelude
    case inferExp prog [] pexp of
        Left msg -> fail $ "Checker:" ++ show msg
        Right texp -> return texp

spec :: Spec
spec = do
    let int = Type "Int"
    describe "pattern matching" $ do
        it "fills variables" $ do
            let name = "l"
            let t = Type "ListOfInt"
            let term = (ConExp t "empty" [])
            pmatch term (VarPat t name) `shouldBe` Right [(name, term)]
    describe "eval" $ do
        it "completes" $ do
            p <- rules
            m <- main "add(zero(), succ(zero()))"
            eval p m `shouldBe` ConExp int "succ" [ConExp int "zero" []]
        it "can run add1(0)" $ do
            p <- rules
            m <- main "add1().apply1(zero())"
            r <- main "succ(zero())"
            eval p m `shouldBe` r
        it "can run add1(1)" $ do
            p <- rules
            m <- main "add1().apply1(succ(zero()))"
            r <- main "succ(succ(zero()))"
            eval p m `shouldBe` r
        it "matches manual reduction" $ do
            p <- rules
            m <- main "map(add1(), cons(succ(zero()), cons(zero(), empty())))"
            r <- main "cons(succ(succ(zero())), cons(succ(zero()), empty()))"
            eval p m `shouldBe` r
    describe "prelude" $ do
        it "adder works" $ do
            p <- rules
            m <- main "map(adder(succ(zero())), cons(succ(zero()), cons(zero(), empty())))"
            r <- main "cons(succ(succ(zero())), cons(succ(zero()), empty()))"
            eval p m `shouldBe` r
