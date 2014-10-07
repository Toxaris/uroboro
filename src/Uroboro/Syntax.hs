module Uroboro.Syntax where

type Identifier = String

data Exp = Variable Identifier
         | Application Identifier [Exp]
--       | FunctionApplication Identifier [Exp]
--       | ConstructorApplication Identifier [Exp]
         | DestructorApplication Exp Identifier [Exp] deriving (Show, Eq)

data Pattern = VariablePattern Identifier
             | ConstructorPattern Identifier [Pattern] deriving (Show, Eq)

-- data Type = PositiveType Identifier
--           | NegativeType Identifier
type Type = Identifier

data Signature = Signature Identifier [Type] Type deriving (Show, Eq)

data Copattern = DestructorCopattern Identifier [Pattern] deriving (Show, Eq)

data ApplicationPattern = ApplicationPattern [Pattern] [Copattern] Exp deriving (Show, Eq)

data Definition = DataDefinition Identifier [Signature]
                | CodataDefinition Identifier [Signature]
                | FunctionDefinition Signature [ApplicationPattern] deriving (Show, Eq)
