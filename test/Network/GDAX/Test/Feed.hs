{-# LANGUAGE OverloadedLists   #-}
{-# LANGUAGE OverloadedStrings #-}

module Network.GDAX.Test.Feed
    ( tests
    ) where

import           Control.Lens
import           Data.Aeson              (Value (..))
import qualified Data.Aeson              as Aeson
import           Data.Aeson.Lens
import qualified Data.ByteString.Lazy    as LBS
import           Network.GDAX.Test.Types
import           Network.GDAX.Types.Feed
import           Network.WebSockets
import           Test.Tasty
import           Test.Tasty.HUnit
import           Wuss

tests :: Env -> TestTree
tests e = testGroup "Feed Parse"
    [ case_heartbeat e
    , case_ticker e
    , case_level2 e
    , case_matches e
    , case_full e
    , case_sum e
    ]

case_heartbeat :: Env -> TestTree
case_heartbeat _ = testCase "Heartbeats" $
        runSecureClient "ws-feed.gdax.com" 443 "/" client
    where
        client :: ClientApp ()
        client conn = do
            sendTextData conn (Aeson.encode testSub)

            m1 <- receiveNotSubs conn

            sendTextData conn (Aeson.encode testUnSub)

            let h1 = Aeson.eitherDecode m1 :: Either String Heartbeat

            assertRight h1

        testSub = Subscribe $ Subscriptions [] [ChannelSubscription ChannelHeartbeat ["BTC-USD"]]
        testUnSub =  UnSubscribe $ Subscriptions [] [ChannelSubscription ChannelHeartbeat ["BTC-USD"]]

case_ticker :: Env -> TestTree
case_ticker _ = testCase "Ticker" $
        runSecureClient "ws-feed.gdax.com" 443 "/" client
    where
        client :: ClientApp ()
        client conn = do
            sendTextData conn (Aeson.encode testSub)

            m2 <- receiveNotSubs conn

            sendTextData conn (Aeson.encode testUnSub)

            let h1 = Aeson.eitherDecode m2 :: Either String Ticker

            assertRight h1

        testSub = Subscribe $ Subscriptions [] [ChannelSubscription ChannelTicker ["BTC-USD"]]
        testUnSub =  UnSubscribe $ Subscriptions [] [ChannelSubscription ChannelTicker ["BTC-USD"]]

case_level2 :: Env -> TestTree
case_level2 _ = testCase "Level 2" $
        runSecureClient "ws-feed.gdax.com" 443 "/" client
    where
        client :: ClientApp ()
        client conn = do
            sendTextData conn (Aeson.encode testSub)

            m1 <- receiveNotSubs conn
            m2 <- receiveNotSubs conn
            m3 <- receiveNotSubs conn

            sendTextData conn (Aeson.encode testUnSub)

            let snap = Aeson.eitherDecode m1 :: Either String Level2Snapshot
                u1 = Aeson.eitherDecode m2 :: Either String Level2Update
                u2 = Aeson.eitherDecode m3 :: Either String Level2Update

            assertRight snap
            assertRight u1
            assertRight u2

        testSub = Subscribe $ Subscriptions [] [ChannelSubscription ChannelLevel2 ["BTC-USD"]]
        testUnSub =  UnSubscribe $ Subscriptions [] [ChannelSubscription ChannelLevel2 ["BTC-USD"]]


case_matches :: Env -> TestTree
case_matches _ = testCase "Matches" $
        runSecureClient "ws-feed.gdax.com" 443 "/" client
    where
        client :: ClientApp ()
        client conn = do
            sendTextData conn (Aeson.encode testSub)

            m1 <- receiveNotSubs conn
            m2 <- receiveNotSubs conn

            sendTextData conn (Aeson.encode testUnSub)

            let mt1 = Aeson.eitherDecode m1 :: Either String Match
                mt2 = Aeson.eitherDecode m2 :: Either String Match

            assertRight mt1
            assertRight mt2

        testSub = Subscribe $ Subscriptions [] [ChannelSubscription ChannelMatches ["BTC-USD"]]
        testUnSub =  UnSubscribe $ Subscriptions [] [ChannelSubscription ChannelMatches ["BTC-USD"]]

case_full :: Env -> TestTree
case_full _ = testCase "Full" $
        runSecureClient "ws-feed.gdax.com" 443 "/" client
    where
        client :: ClientApp ()
        client conn = do
            sendTextData conn (Aeson.encode testSub)

            m1 <- receiveNotSubs conn
            m2 <- receiveNotSubs conn

            print m1
            print m2

            sendTextData conn (Aeson.encode testUnSub)

            -- let mt1 = Aeson.eitherDecode m1 :: Either String Match
            --     mt2 = Aeson.eitherDecode m2 :: Either String Match

            -- assertRight mt1
            -- assertRight mt2

        testSub = Subscribe $ Subscriptions [] [ChannelSubscription ChannelFull ["BTC-USD"]]
        testUnSub =  UnSubscribe $ Subscriptions [] [ChannelSubscription ChannelFull ["BTC-USD"]]

case_sum :: Env -> TestTree
case_sum _ = testCase "Sum" $
        runSecureClient "ws-feed.gdax.com" 443 "/" client
    where
        client :: ClientApp ()
        client conn = do
            sendTextData conn (Aeson.encode testSub)

            ms <- sequence $ take 100 $ repeat (receiveNotSubs conn)

            sendTextData conn (Aeson.encode testUnSub)

            let res = fmap Aeson.eitherDecode ms

            mapM_ assertRight (res :: [Either String GdaxMessage])

        testSub = Subscribe $ Subscriptions [] subs
        testUnSub =  UnSubscribe $ Subscriptions [] subs
        subs =
            [ ChannelSubscription ChannelHeartbeat ["BTC-USD"]
            , ChannelSubscription ChannelTicker ["BTC-USD"]
            , ChannelSubscription ChannelLevel2 ["BTC-USD"]
            , ChannelSubscription ChannelMatches ["BTC-USD"]
            ]

receiveNotSubs :: Connection -> IO LBS.ByteString
receiveNotSubs conn = loop
    where
        loop = do
            res <- receiveData conn
            let asValue = Aeson.eitherDecode res :: Either String Value
            case asValue of
                Left er -> fail (show er)
                Right v ->
                    if (v ^? key "type") == (Just (String "subscriptions"))
                        then loop
                        else return res

assertRight :: (Show e) => Either e a -> IO ()
assertRight (Right _) = return ()
assertRight (Left er) = fail (show er)
