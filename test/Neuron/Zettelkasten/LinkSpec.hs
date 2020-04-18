{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Neuron.Zettelkasten.LinkSpec
  ( spec,
  )
where

import Neuron.Zettelkasten.ID
import Neuron.Zettelkasten.Link
import Neuron.Zettelkasten.Link.Theme (LinkTheme (..))
import Neuron.Zettelkasten.Markdown (MarkdownLink (..))
import Neuron.Zettelkasten.Query
import Neuron.Zettelkasten.Tag
import Relude
import Test.Hspec
import Text.URI

spec :: Spec
spec = do
  describe "Link Action conversion" $ do
    forM_ zLinkCases $ \(name, link, action) -> do
      it ("converts " <> name) $ do
        mkZLink (uncurry mkMarkdownLink $ either (id &&& id) id link) `shouldBe` action

zLinkCases :: [(String, Either Text (Text, Text), Maybe ZLink)]
zLinkCases =
  [ ( "alias link",
      (Left "1234567"),
      Just $ ZLink_ConnectZettel Folgezettel zid
    ),
    ( "not an alias link (different link text)",
      (Right ("foo", "1234567")),
      Nothing
    ),
    ( "z: link",
      (Right ("1234567", "z:")),
      Just $ ZLink_ConnectZettel Folgezettel zid
    ),
    ( "z: link, with annotation ignored",
      (Right ("1234567", "z://foo-bar")),
      Just $ ZLink_ConnectZettel Folgezettel zid
    ),
    ( "zcf: link",
      (Right ("1234567", "zcf:")),
      Just $ ZLink_ConnectZettel OrdinaryConnection zid
    ),
    ( "zcf: link, with annotation ignored",
      (Right ("1234567", "zcf://foo-bar")),
      Just $ ZLink_ConnectZettel OrdinaryConnection zid
    ),
    ( "zquery: link",
      (Right (".", "zquery://search?tag=science")),
      Just $ ZLink_QueryZettels Folgezettel LinkTheme_Default [Query_ZettelsByTag $ TagPattern "science"]
    ),
    ( "zcfquery: link, with link theme",
      (Right (".", "zcfquery://search?tag=science&linkTheme=withDate")),
      Just $ ZLink_QueryZettels OrdinaryConnection LinkTheme_WithDate [Query_ZettelsByTag $ TagPattern "science"]
    ),
    ( "normal link",
      (Left "https://www.google.com"),
      Nothing
    )
  ]
  where
    zid = parseZettelID "1234567"

mkMarkdownLink :: Text -> Text -> MarkdownLink
mkMarkdownLink s l =
  MarkdownLink s $ either (error . toText . displayException) id $ mkURI l