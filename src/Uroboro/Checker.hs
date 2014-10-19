module Uroboro.Checker
    (
      check
    , TExp(..)
    ) where

import Control.Monad (mapM)
import Data.Either (isRight)
import Data.List (find)
import Data.Maybe (listToMaybe)

import Uroboro.Syntax

data TExp = TVar Identifier Type
          | TApp Identifier [TExp] Type
          | TCon Identifier [TExp] Type -- positive
          | TDes Identifier TExp [TExp] Type deriving (Show, Eq) -- negative

etype :: TExp -> Type
etype (TVar _ t) = t
etype (TApp _ _ t) = t
etype (TCon _ _ t) = t
etype (TDes _ _ _ t) = t

type Context = [(Identifier, Type)]

signature :: [Signature] -> Identifier -> Either String [Type]
signature ((Signature n ts _):_) n' | n == n' = return ts
signature (_:ss) n = signature ss n
signature _ _ = Left "unknown"

sigma :: Library -> Identifier -> Either String ([Type], Type)
sigma ((FunctionDefinition (Signature n' ts t) _):_) n | n' == n = return (ts, t)
sigma (_:xs) n = sigma xs n
sigma _ _ = Left "unknown"

constructor :: Library -> Type -> Identifier -> Either String [Type]
constructor ((DataDefinition d' ss):_) d n | d' == d = signature ss n
constructor (_:xs) d n = constructor xs d n
constructor _ _ _ = Left "unknown"

checkargs :: Library -> Context -> [Exp] -> [Type] -> Either String [TExp]
checkargs _ _ [] [] = return []
checkargs p c (e:es) (t:ts) = do
    te <- check p c e t
    tes <- checkargs p c es ts
    return (te:tes)
checkargs _ _ _ _ = Left "wrong number of arguments"

infers :: [Signature] -> Identifier -> [Type] -> Either String Type
infers ((Signature n ts t):_) n' ts' | n == n' && ts == ts' = return t
infers (_:ss) n ts = infers ss n ts
infers _ _ _ = Left "unknown"

mu :: Library -> Identifier -> [Type] -> Either String Type
mu ((DataDefinition _ ss):_) c ts = infers ss c ts
mu (_:ds) c ts = mu ds c ts
mu _ _ _ = Left "unknown"

inferd :: [Signature] -> Identifier -> Either String ([Type], Type)
inferd ((Signature n ts t):_) n' | n == n' = return (ts, t)
inferd (_:ss) n = inferd ss n
inferd _ _ = Left "unknown"

nu :: Library -> Type -> Identifier -> Either String ([Type], Type)
nu ((CodataDefinition c' ss):_) c d | c' == c = inferd ss d
nu (_:ds) c d = nu ds c d
nu _ _ _ = Left "unknown"

inferc :: Library -> Context -> Identifier -> [Exp] -> Either String TExp
inferc p c n es = do
    tes <- mapM (infer p c) es
    let ts = map etype tes
    t <- mu p n ts
    return $ TCon n tes t

infer :: Library -> Context -> Exp -> Either String TExp
infer _ c (Variable x) = maybe (Left "unknown") (Right . TVar x) $ lookup x c
infer p c (Application n es) = case (infer p c (FunctionApplication n es), infer p c (ConstructorApplication n es)) of
    (Right e, Left _) -> Right e
    (Left _, Right e) -> Right e
    _ -> Left "ambiguous"
infer p c (FunctionApplication f es) = do
    (ts, t) <- sigma p f
    tes <- checkargs p c es ts
    return $ TApp f tes t
infer p c (ConstructorApplication n es) = inferc p c n es
infer p c (DestructorApplication e n es) = do
    te <- infer p c e
    (ts, t) <- nu p (etype te) n
    tes <- checkargs p c es ts
    return $ TDes n te tes t

check :: Library -> Context -> Exp -> Type -> Either String TExp
check p c e@(Variable x) t = do
    te <- infer p c e
    if etype te == t then return te else Left "mismatch"
check p c (Application n es) t = case (check p c (FunctionApplication n es) t, check p c (ConstructorApplication n es) t) of
    (Right e, Left _) -> Right e
    (Left _, Right e) -> Right e
    _ -> Left "ambiguous"
check p c e@(FunctionApplication _ _) t = do
    te <- infer p c e
    if etype te == t then return te else Left "mismatch"
check p c (ConstructorApplication x es) t = do
    ts <- constructor p t x
    tes <- checkargs p c es ts
    return $ TCon x tes t
check p c d@(DestructorApplication e n es) t = do
    te <- infer p c d
    if etype te == t then return te else Left "mismatch"
