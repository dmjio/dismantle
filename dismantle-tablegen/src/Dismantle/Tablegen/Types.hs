{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
module Dismantle.Tablegen.Types (
  InstructionDescriptor(..),
  OperandDescriptor(..),
  OperandType(..),
  RegisterClass(..),
  ISADescriptor(..)
  ) where

import GHC.Generics ( Generic )
import Control.DeepSeq
import Data.Word ( Word8 )

import qualified Dismantle.Tablegen.ByteTrie as BT

-- | The type of data contained in a field operand.
--
-- For now, this is just a wrapper around a string.  Later in the
-- process, we will parse that out using information in the tablegen
-- files.
--
-- Those have definitions for 'DAGOperand's, which will let us
-- classify each operand with great precision.  There are subtypes of
-- DAGOperand:
--
-- * RegisterClass: this defines a *class* of registers
-- * RegisterOperand: references a register class
--
-- It seems like some of the details are ISA-specific, so we don't
-- want to commit to a representation at this point.
data OperandType = OperandType String
                 deriving (Eq, Ord, Show, Generic, NFData)

-- | Description of an operand field in an instruction (could be a
-- register reference or an immediate)
data OperandDescriptor =
  OperandDescriptor { opName :: String
                    , opChunks :: [(Int, Word8, Word8)]
                    -- ^ (Bit in the instruction, bit in the operand, number of bits in chunk)
                    , opType :: !OperandType
                    }
  deriving (Eq, Ord, Show)

instance NFData OperandDescriptor where
  rnf od = opName od `deepseq` opChunks od `deepseq` od `seq` ()

-- FIXME: Replace these big lists of bits with some cleaner bytestring
-- masks.  We won't need the endian-corrected one if we can generate
-- the trie tables at TH time, which would save a lot

-- | Description of an instruction, abstracted from the tablegen
-- definition
data InstructionDescriptor =
  InstructionDescriptor { idMask :: [BT.Bit]
                        -- ^ Endian-corrected bit mask
                        , idMaskRaw :: [BT.Bit]
                        -- ^ Raw bitmask with no endian correction
                        , idMnemonic :: String
                        , idInputOperands :: [OperandDescriptor]
                        , idOutputOperands :: [OperandDescriptor]
                        , idNamespace :: String
                        , idDecoderNamespace :: String
                        , idAsmString :: String
                        , idPseudo :: Bool
                        }
  deriving (Eq, Ord, Show, Generic, NFData)

data RegisterClass = RegisterClass String
  deriving (Show, Generic, NFData)

data ISADescriptor =
  ISADescriptor { isaInstructions :: [InstructionDescriptor]
                , isaRegisterClasses :: [RegisterClass]
                , isaRegisters :: [(String, RegisterClass)]
                , isaOperands :: [OperandType]
                -- ^ All of the operand types used in an ISA.
                , isaErrors :: [(String, String)]
                -- ^ Errors while mapping operand classes to bit
                -- fields in the instruction encoding; the first
                -- String is the mnemonic, while the second is the
                -- operand name.
                }
  deriving (Show, Generic, NFData)
