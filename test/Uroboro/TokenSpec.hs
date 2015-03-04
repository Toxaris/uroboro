module Uroboro.TokenSpec
    (
      spec
    ) where

import Test.Hspec

import Uroboro.Token

import Utils

spec :: Spec
spec = do
    context "when looking for identifiers" $ do
        it "rejects keywords" $ do
            identifier `shouldReject` "codata"
            identifier `shouldReject` "data"
            identifier `shouldReject` "function"
            identifier `shouldReject` "where"
        it "accepts identifiers starting with keywords" $ do
            identifier `shouldAccept` "codatatype"
            identifier `shouldAccept` "datatype"
            identifier `shouldAccept` "functional"
            identifier `shouldAccept` "whereas"
    context "when looking for a keyword" $ do
        it "accepts the keyword" $ do
            reserved "codata" `shouldAccept` "codata"
            reserved "data" `shouldAccept` "data"
            reserved "function" `shouldAccept` "function"
            reserved "where" `shouldAccept` "where"
        it "rejects identifiers starting with the keyword" $ do
            reserved "codata" `shouldReject` "codatatype"
            reserved "data" `shouldReject` "datatype"
            reserved "function" `shouldReject` "functional"
            reserved "where" `shouldReject` "whereas"
    context "when looking for comments" $ do
        it "recognizes end-of-line comments starting with --" $ do
            whiteSpace `shouldAccept` "-- comment \n"
            whiteSpace `shouldReject` "-- comment \nfoo"
        it "recognizes comments between {- and -}" $ do
            whiteSpace `shouldAccept` "{- comment -}"
            whiteSpace `shouldReject` "{- comment -}foo"
        it "recognizes nested comments" $ do
            whiteSpace `shouldAccept` "{- {- -} -}"
            whiteSpace `shouldReject` "{- {- -}"
