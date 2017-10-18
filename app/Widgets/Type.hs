module Widgets.Type where

import Graphics.Declarative.Classes
import Graphics.Declarative.Bordered
import qualified Graphics.Declarative.Border as Border
import Graphics.Declarative.Cairo.TangoColors
import Graphics.Declarative.Cairo.Form
import Graphics.Declarative.Cairo.Shape
import Graphics.Declarative.SDL.Input

import qualified Reactive
import Reactive (Reactive(..))
import qualified Event
import RunReactive (runReactive)
import Data.Monoid (First(..))
import Utils
import Linear
import FormUtils

import qualified Widgets.TextField as TextField
import qualified Widgets.Button as Button

data Model -- for types
  = Record [Association] Button.Model
  | Var TextField.Model
  deriving (Show, Eq)

type Association = (TextField.Model, Model, Bool)

monoStyle :: TextStyle
monoStyle = defaultTextStyle { fontFamily = "monospace" }

example :: Model
example
  = record
  [ ( "key", var "value" )
  , ( "record"
    , record
      [ ( "nested", var "records" )
      , ( "mutliple", var "fields" )
      , ( "all good are", var "3" )
      ]
    )
  ]

record :: [(String, Model)] -> Model
record = flip Record Button.construct . map makeModel
  where makeModel (str, model) = ( TextField.inactive str, model, False)

var :: String -> Model
var = Var . TextField.inactive


view :: Model -> Reactive Model
view (Var textField) = Var <$> TextField.view monoStyle "variable" textField
view (Record associations buttonModel) =
    Reactive.besidesTo down handleAddAssociation
      (viewAssociations associations)
      (alignHV (0, 0) (Button.view (text monoStyle "+") buttonModel))
  where
    placeholderAssoc = (TextField.emptyInactive, Var TextField.emptyActive, False)
    handleAddAssociation :: [Association] -> (Button.Model, Button.Event) -> Model
    handleAddAssociation associations (buttonModel, buttonClicked)
      | buttonClicked = Record (associations ++ [placeholderAssoc]) buttonModel
      | otherwise     = Record associations buttonModel

viewAssociations :: [Association] -> Reactive [Association]
viewAssociations associations =
    Reactive.besidesAll down (map viewAssociation associations)

viewAssociation :: Association -> Reactive Association
viewAssociation (textField, typ, isInvalid) =
    attachValidity <$> Reactive.besidesTo right (,) nameReactive (view typ)
  where
    attachValidity (x, y) = (x, y, isInvalid)
    possiblyAddBorder =
      if isInvalid then addBorder red else id
    nameReactive =
      Reactive.attachFormTo right
        (text monoStyle ": ")
        (Reactive.onVisual (possiblyAddBorder . padded 2)
          (TextField.view monoStyle "field name" textField))