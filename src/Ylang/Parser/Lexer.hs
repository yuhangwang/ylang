---------------------------------------------------------------------
-- |
-- Module      :  Ylang.Parser.Lexer
-- Description :  Token Lexer for Ylang
-- Copyright   :  (c) 2014 Kazuhiro Mizuhsima
-- License     :  Apache-2
--
-- Maintainer  :  Kazuhiro Mizushima <voqn.tyrantist@gmail.com>
-- Stability   :  unstable
-- Portability :  portable
---------------------------------------------------------------------
module Ylang.Parser.Lexer where

import Control.Applicative  hiding (many, (<|>))
import Control.Monad.Identity
import Data.Char
import Data.Ratio
import Data.Text            (Text)
import Text.Parsec
import Text.Parsec.Text     (Parser)
import Ylang.Syntax.Literal
import Ylang.Parser.Combinator

import qualified Data.Text as T
import qualified Text.Parsec.Token as TK

---------------------------------------------------------------------
-- Basic Lexer
---------------------------------------------------------------------

notSpace :: Parser Char
notSpace = satisfy $ not . isSpace

sign :: (Num a) => Parser (a -> a)
sign = '-' !> pure negate </> pure id

------------------------------------------------------------------
-- Language Definition of Ylang
------------------------------------------------------------------
type YlangDef st    = TK.GenLanguageDef Text st Identity

type TokenParser st = TK.GenTokenParser Text st Identity

ylangDef :: YlangDef ()
ylangDef = TK.LanguageDef {
    TK.commentStart    = ";;;"
  , TK.commentEnd      = ";;;"
  , TK.commentLine     = ";"
  , TK.nestedComments  = False
  , TK.identStart      = letter
  , TK.identLetter     = alphaNum
  , TK.opStart         = undefined
  , TK.opLetter        = undefined
  , TK.reservedNames   = []
  , TK.reservedOpNames = ["=", "->", "=>", ":", "::", ","]
  , TK.caseSensitive   = True
  }

------------------------------------------------------------------
-- Lexer for Ylang
------------------------------------------------------------------

lexer :: TokenParser ()
lexer = TK.makeTokenParser ylangDef

parens :: Parser a -> Parser a
parens = TK.parens lexer

commaSep :: Parser a -> Parser [a]
commaSep = TK.commaSep lexer

semiSep :: Parser a -> Parser [a]
semiSep = TK.semiSep lexer

symbol :: String -> Parser String
symbol = TK.symbol lexer

identifier :: Parser String
identifier = TK.identifier lexer

whiteSpace :: Parser ()
whiteSpace = TK.whiteSpace lexer

natural :: Parser Integer
natural = TK.natural lexer

integer :: Parser Integer
integer = TK.integer lexer

float :: Parser Double
float = ($) <$> sign <*> TK.float lexer

charLit :: Parser Char
charLit = TK.charLiteral lexer

strLit :: Parser String
strLit = TK.stringLiteral lexer

toText :: Parser String -> Parser Text
toText p = T.pack <$> p

rational :: Parser Rational
rational = ratio <$> sign <*> natural <*> (char '/' *> natural)
  where
  ratio f n d = f (n % d)

boolLit :: Parser Bool
boolLit
   =  True  <$ symbol "Yes"
  </> False <$ symbol "No"

keyword :: Parser Text
keyword = T.pack <$> (char ':' *> many1 notSpace)

------------------------------------------------------------------
-- Literal Token for Ylang
------------------------------------------------------------------

literal :: Parser Lit
literal
   =  LitHole <$  symbol "_"
  </> LitUnit <$  symbol "()"
  </> LitBool <$> boolLit
  </> LitRatn <$> rational
  </> LitFlon <$> float
  </> LitIntn <$> integer
  </> LitChr  <$> charLit
  </> LitStr  <$> toText strLit
  </> LitKey  <$> keyword
