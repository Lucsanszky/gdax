{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}

module Network.GDAX.Implicit.Private where

import           Control.Lens                  hiding ((.=))
import           Control.Monad.Catch
import           Control.Monad.IO.Class
import           Control.Monad.Reader
import           Data.Vector                   (Vector)
import           Network.GDAX.Core
import qualified Network.GDAX.Explicit.Private as Explicit
import           Network.GDAX.Types.Private
import           Network.GDAX.Types.Shared

listAccounts :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => m (Vector Account)
listAccounts = do
    g <- (^. gdax) <$> ask
    Explicit.listAccounts g

getAccount :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => AccountId -> m Account
getAccount aid = do
    g <- (^. gdax) <$> ask
    Explicit.getAccount g aid

getAccountHistory :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => AccountId -> m (Vector Entry)
getAccountHistory aid = do
    g <- (^. gdax) <$> ask
    Explicit.getAccountHistory g aid

getAccountHolds :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => AccountId -> m (Vector Hold)
getAccountHolds aid = do
    g <- (^. gdax) <$> ask
    Explicit.getAccountHolds g aid

placeOrder :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => NewOrder -> m NewOrderConfirmation
placeOrder no = do
    g <- (^. gdax) <$> ask
    Explicit.placeOrder g no

placeLimitOrder :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => NewLimitOrder -> m NewOrderConfirmation
placeLimitOrder no = do
    g <- (^. gdax) <$> ask
    Explicit.placeLimitOrder g no

placeMarketOrder :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => NewMarketOrder -> m NewOrderConfirmation
placeMarketOrder no = do
    g <- (^. gdax) <$> ask
    Explicit.placeMarketOrder g no

placeStopOrder :: (MonadIO m, MonadThrow m, MonadReader e m, HasGdax e) => NewStopOrder -> m NewOrderConfirmation
placeStopOrder no = do
    g <- (^. gdax) <$> ask
    Explicit.placeStopOrder g no
