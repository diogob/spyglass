{-|
Module      : Pasta
Description : Assembles SQL statements
-}
module Pasta
    ( updateTarget
    , assignments
    , updateFilter
    , insert
    , insertTarget
    , insertColumns
    , insertValues
    , onConflict
    , doNothing
    , doUpdate
    , (===)
    , (=:=)
    , (=.=)
    , (//)
    , conflictAssignments
    , conflictWhere
    , select
    , selectExp
    , selectFrom
    , selectFunction
    , alias
    , columns
    , expression
    , t
    , f
    , fromClause
    , relationAlias
    , relationExpression
    , setWhere
    , showt
    , NonEmpty (..)
    , fromList
    ) where

import Pasta.Types
import Control.Lens
import Data.List.NonEmpty (NonEmpty(..), fromList)
import TextShow (showt)
import qualified Data.Text as T

makeLenses ''Select
makeLenses ''FromRelation
makeLenses ''Column
makeLenses ''Expression
makeLenses ''Update
makeLenses ''Insert
makeLenses ''ConflictAction

-- | Builds a SELECT null with neither FROM nor WHERE clauses.
select :: Select
select = Select ((Column $ LitExp "NULL") :| []) [] Nothing

-- | Builds a SELECT * FROM table statement.
selectFrom :: Name -> Select
selectFrom table = select & columns .~ ("*" :| []) & fromClause .~ [FromRelation (NameExp table) table]

-- | Builds a SELECT expression with neither FROM nor WHERE clauses
selectExp :: Expression -> Select
selectExp expr = select & columns .~ (Column expr :| [])

-- | Builds a SELECT fn(parameters) with neither FROM nor WHERE clauses
selectFunction :: T.Text -> [Expression] -> Select
selectFunction fn parameters = selectExp $ FunctionExp (Name fn, parameters)

-- | Just a convenient set whereClause composed with a Just
setWhere :: BooleanExpression -> Select -> Select
setWhere = set whereClause . Just

-- | Just a convenient way to write a BoolLiteral True
t :: BooleanExpression
t = BoolLiteral True

-- | Just a convenient way to write a BoolLiteral False
f :: BooleanExpression
f = BoolLiteral False

-- | Builds an INSERT statement using a target, a non-empty list of column names and a non-empty list of values
insert :: T.Text -> NonEmpty T.Text -> NonEmpty T.Text -> Insert
insert target cols vals = Insert (Identifier schema table) colNames valExps Nothing
  where
    qId = Name <$> T.split (=='.') target
    schema = if length qId == 2
               then head qId
               else "public"
    table = if length qId == 2
               then qId!!1
               else head qId
    colNames = Name <$> cols
    valExps = (LitExp . Literal) <$> vals

doNothing :: Maybe ConflictAction
doNothing = Just DoNothing

doUpdate :: [Assignment] -> Maybe ConflictAction
doUpdate [] = Nothing
doUpdate assigns = Just $ DoUpdate (fromList assigns) Nothing

(=:=) :: Name -> Expression -> Assignment
(=:=) = Assignment

(===) :: Name -> Name -> Assignment
(===) = flip $ flip (=:=) . NameExp

(=.=) :: Name -> Identifier -> Assignment
(=.=) = flip $ flip (=:=) . IdentifierExp

(//) :: Name -> Name -> Identifier
(//) = Identifier
