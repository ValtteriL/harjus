#include "FixConfig.h"
#include <filesystem>
#include <fstream>
#include <quickfix/SessionSettings.h>

void prepareFixFileStore(const std::string &dir) {
  std::filesystem::create_directory(dir);

  for (const auto &entry : std::filesystem::directory_iterator(dir)) {
    if (entry.path().extension() == ".session" ||
        entry.path().extension() == ".body" ||
        entry.path().extension() == ".header" ||
        entry.path().extension() == ".seqnums") {
      std::filesystem::remove(entry.path());
    }
  }
}

std::string writeSchemaToTemp(const std::string &xml, const std::string &name) {
  auto tmp = std::filesystem::temp_directory_path() / name;
  std::ofstream ofs(tmp);
  ofs << xml;
  return tmp.string();
}

std::string FixMdSchema() {
  return R"(<fix major='4' type='FIX' servicepack='0' minor='4'>
 <header>
  <field name='BeginString' required='Y'/>
  <field name='BodyLength' required='Y'/>
  <field name='MsgType' required='Y'/>
  <field name='SenderCompID' required='Y'/>
  <field name='TargetCompID' required='Y'/>
  <field name='MsgSeqNum' required='Y'/>
  <field name='SendingTime' required='Y'/>
  <field name='RecvWindow' required='N'/>
 </header>
 <messages>
  <message name='Heartbeat' msgcat='admin' msgtype='0'>
   <field name='TestReqID' required='N'/>
  </message>
  <message name='TestRequest' msgcat='admin' msgtype='1'>
   <field name='TestReqID' required='Y'/>
  </message>
  <message name='Reject' msgcat='admin' msgtype='3'>
   <field name='RefSeqNum' required='N'/>
   <field name='RefTagID' required='N'/>
   <field name='RefMsgType' required='N'/>
   <field name='SessionRejectReason' required='N'/>
   <field name='ErrorCode' required='N'/>
   <field name='Text' required='N'/>
  </message>
  <message name='Logout' msgcat='admin' msgtype='5'>
   <field name='Text' required='N'/>
  </message>
  <message name='Logon' msgcat='admin' msgtype='A'>
   <field name='EncryptMethod' required='N'/>
   <field name='HeartBtInt' required='Y'/>
   <field name='RawDataLength' required='N'/>
   <field name='RawData' required='N'/>
   <field name='ResetSeqNumFlag' required='N'/>
   <field name='Username' required='N'/>
   <field name='MessageHandling' required='N'/>
   <field name='UUID' required='N'/>
  </message>
  <message name='LimitQuery' msgcat='app' msgtype='XLQ'>
   <field name='ReqID' required='Y'/>
  </message>
  <message name='LimitResponse' msgcat='app' msgtype='XLR'>
   <field name='ReqID' required='Y'/>
   <group name='NoLimitIndicators' required='Y'>
    <field name='LimitType' required='Y'/>
    <field name='LimitCount' required='Y'/>
    <field name='LimitMax' required='Y'/>
    <field name='LimitResetInterval' required='N'/>
    <field name='LimitResetIntervalResolution' required='N'/>
   </group>
  </message>
  <message name='InstrumentListRequest' msgcat='app' msgtype='x'>
   <field name='InstrumentReqID' required='Y'/>
   <field name='InstrumentListRequestType' required='Y'/>
   <field name='Symbol' required='N'/>
  </message>
  <message name='InstrumentList' msgcat='app' msgtype='y'>
   <field name='InstrumentReqID' required='Y'/>
   <group name='NoRelatedSym' required='Y'>
    <field name='Symbol' required='Y'/>
    <field name='Currency' required='Y'/>
    <field name='MinTradeVol' required='Y'/>
    <field name='MaxTradeVol' required='Y'/>
    <field name='MinQtyIncrement' required='Y'/>
    <field name='MarketMinTradeVol' required='Y'/>
    <field name='MarketMaxTradeVol' required='Y'/>
    <field name='MarketMinQtyIncrement' required='Y'/>
    <field name='MinPriceIncrement' required='Y'/>
   </group>
  </message>
  <message name='MarketDataRequest' msgcat='app' msgtype='V'>
   <field name='MDReqID' required='Y'/>
   <field name='SubscriptionRequestType' required='Y'/>
   <field name='MarketDepth' required='N'/>
   <group name='NoRelatedSym' required='N'>
    <field name='Symbol' required='Y'/>
   </group>
   <group name='NoMDEntryTypes' required='N'>
    <field name='MDEntryType' required='Y'/>
   </group>
   <field name='AggregatedBook' required='N'/>
  </message>
  <message name='MarketDataRequestReject' msgcat='app' msgtype='Y'>
   <field name='MDReqID' required='Y'/>
   <field name='MDReqRejReason' required='N'/>
   <field name='ErrorCode' required='N'/>
   <field name='Text' required='N'/>
  </message>
  <message name='MarketDataSnapshot' msgcat='app' msgtype='W'>
   <field name='MDReqID' required='Y'/>
   <field name='Symbol' required='Y'/>
   <field name='LastBookUpdateID' required='N'/>
   <group name='NoMDEntries' required='Y'>
    <field name='MDEntryType' required='Y'/>
    <field name='MDEntryPx' required='Y'/>
    <field name='MDEntrySize' required='Y'/>
   </group>
  </message>
  <message name='MarketDataIncrementalRefresh' msgcat='app' msgtype='X'>
   <field name='MDReqID' required='Y'/>
   <field name='LastFragment' required='N'/>
   <group name='NoMDEntries' required='Y'>
    <field name='MDUpdateAction' required='Y'/>
    <field name='MDEntryPx' required='Y'/>
    <field name='MDEntrySize' required='N'/>
    <field name='MDEntryType' required='Y'/>
    <field name='Symbol' required='N'/>
    <field name='TransactTime' required='N'/>
    <field name='TradeID' required='N'/>
    <field name='AggressorSide' required='N'/>
    <field name='FirstBookUpdateID' required='N'/>
    <field name='LastBookUpdateID' required='N'/>
   </group>
  </message>
  <message name='News' msgtype='B' msgcat='app'>
   <field name='Headline' required='Y'/>
  </message>
 </messages>
 <trailer>
  <field name='CheckSum' required='Y'/>
 </trailer>
 <components>
 </components>
 <fields>
  <field number='8' name='BeginString' type='STRING'>
   <value enum='FIX.4.4' description='FIX44'/>
  </field>
  <field number='9' name='BodyLength' type='LENGTH'/>
  <field number='10' name='CheckSum' type='STRING'/>
  <field number='15' name='Currency' type='STRING'/>
  <field number='34' name='MsgSeqNum' type='SEQNUM'/>
  <field number='35' name='MsgType' type='STRING'>
   <value enum='0' description='HEARTBEAT'/>
   <value enum='1' description='TEST_REQUEST'/>
   <value enum='3' description='REJECT'/>
   <value enum='5' description='LOGOUT'/>
   <value enum='A' description='LOGON'/>
   <value enum='B' description='NEWS'/>
   <value enum='V' description='MARKET_DATA_REQUEST'/>
   <value enum='W' description='MARKET_DATA_SNAPSHOT'/>
   <value enum='X' description='MARKET_DATA_INCREMENTAL_REFRESH'/>
   <value enum='Y' description='MARKET_DATA_REQUEST_REJECT'/>
   <value enum='x' description='INSTRUMENT_LIST_REQUEST'/>
   <value enum='y' description='INSTRUMENT_LIST'/>
   <value enum='XLQ' description='LIMIT_QUERY'/>
   <value enum='XLR' description='LIMIT_RESPONSE'/>
  </field>
  <field number='45' name='RefSeqNum' type='INT'/>
  <field number='49' name='SenderCompID' type='STRING'/>
  <field number='52' name='SendingTime' type='UTCTIMESTAMP'/>
  <field number='55' name='Symbol' type='STRING'/>
  <field number='56' name='TargetCompID' type='STRING'/>
  <field number='58' name='Text' type='STRING'/>
  <field number='60' name='TransactTime' type='UTCTIMESTAMP'/>
  <field number='95' name='RawDataLength' type='LENGTH'/>
  <field number='96' name='RawData' type='DATA'/>
  <field number='98' name='EncryptMethod' type='INT'>
   <value enum='0' description='NONE'/>
  </field>
  <field number='108' name='HeartBtInt' type='INT'/>
  <field number='112' name='TestReqID' type='STRING'/>
  <field number='141' name='ResetSeqNumFlag' type='BOOLEAN'>
   <value enum='Y' description='YES'/>
   <value enum='N' description='NO'/>
  </field>
  <field number='146' name='NoRelatedSym' type='NUMINGROUP'/>
  <field number='148' name='Headline' type='STRING'/>
  <field number='262' name='MDReqID' type='STRING'/>
  <field number='263' name='SubscriptionRequestType' type='char'>
   <value enum='1' description='Subscribe'/>
   <value enum='2' description='Unsubscribe'/>
  </field>
  <field number='264' name='MarketDepth' type='INT'/>
  <field number='266' name='AggregatedBook' type='BOOLEAN'>
   <value enum='Y' description='BOOK_ENTRIES_TO_BE_AGGREGATED'/>
  </field>
  <field number='267' name='NoMDEntryTypes' type='NUMINGROUP'/>
  <field number='268' name='NoMDEntries' type='NUMINGROUP'/>
  <field number='269' name='MDEntryType' type='CHAR'>>
   <value enum='0' description='BID'/>
   <value enum='1' description='OFFER'/>
   <value enum='2' description='TRADE'/>
  </field>
  <field number='270' name='MDEntryPx' type='PRICE'/>
  <field number='271' name='MDEntrySize' type='QTY'/>
  <field number='279' name='MDUpdateAction' type='CHAR'>
   <value enum='0' description='NEW'/>
   <value enum='1' description='CHANGE'/>
   <value enum='2' description='DELETE'/>
  </field>
  <field number='281' name='MDReqRejReason' type='CHAR'>
   <value enum='1' description='DUPLICATE_MDREQID'/>
   <value enum='2' description='TOO_MANY_SUBSCRIPTIONS'/>
  </field>
  <field number='320' name='InstrumentReqID' type='STRING'/>
  <field number='371' name='RefTagID' type='INT'/>
  <field number='372' name='RefMsgType' type='STRING'/>
  <field number='373' name='SessionRejectReason' type='INT'>
   <value enum='0' description='INVALID_TAG_NUMBER'/>
   <value enum='1' description='REQUIRED_TAG_MISSING'/>
   <value enum='2' description='TAG_NOT_DEFINED_FOR_THIS_MESSAGE_TYPE'/>
   <value enum='3' description='UNDEFINED_TAG'/>
   <value enum='5' description='VALUE_IS_INCORRECT'/>
   <value enum='6' description='INCORRECT_DATA_FORMAT_FOR_VALUE'/>
   <value enum='8' description='SIGNATURE_PROBLEM'/>
   <value enum='10' description='SENDINGTIME_ACCURACY_PROBLEM'/>
   <value enum='13' description='TAG_APPEARS_MORE_THAN_ONCE'/>
   <value enum='14' description='TAG_SPECIFIED_OUT_OF_REQUIRED_ORDER'/>
   <value enum='15' description='REPEATING_GROUP_FIELDS_OUT_OF_ORDER'/>
   <value enum='16' description='INCORRECT_NUMINGROUP_COUNT_FOR_REPEATING_GROUP'/>
   <value enum='99' description='OTHER'/>
  </field>
  <field number='553' name='Username' type='STRING'/>
  <field number='559' name='InstrumentListRequestType' type='INT'>
   <value enum='0' description='SINGLE_INSTRUMENT'/>
   <value enum='4' description='ALL_INSTRUMENTS'/>
  </field>
  <field number='562' name='MinTradeVol' type='QTY'/>
  <field number='893' name='LastFragment' type='BOOLEAN'>
   <value enum='N' description='NOT_LAST_MESSAGE'/>
   <value enum='Y' description='LAST_MESSAGE'/>
  </field>
  <field number='969' name='MinPriceIncrement' type='PRICE'/>
  <field number='1003' name='TradeID' type='INT'/>
  <field number='1140' name='MaxTradeVol' type='QTY'/>
  <field number='2446' name='AggressorSide' type='CHAR'>
   <value enum='1' description='BUY'/>
   <value enum='2' description='SELL'/>
  </field>
  <field number='6136' name='ReqID' type='STRING'/>
  <field number='25000' name='RecvWindow' type='INT'/>
  <field number='25003' name='NoLimitIndicators' type='NUMINGROUP'/>
  <field number='25004' name='LimitType' type='CHAR'>
   <value enum='2' description='MESSAGE_LIMIT'/>
   <value enum='3' description='SUBSCRIPTION_LIMIT'/>
  </field>
  <field number='25005' name='LimitCount' type='INT'/>
  <field number='25006' name='LimitMax' type='INT'/>
  <field number='25007' name='LimitResetInterval' type='INT'/>
  <field number='25008' name='LimitResetIntervalResolution' type='CHAR'>
   <value enum='s' description='SECOND'/>
   <value enum='m' description='MINUTE'/>
   <value enum='h' description='HOUR'/>
   <value enum='d' description='DAY'/>
  </field>
  <field number='25016' name='ErrorCode' type='INT'/>
  <field number='25035' name='MessageHandling' type='INT'>
   <value enum='1' description='UNORDERED'/>
   <value enum='2' description='SEQUENTIAL'/>
  </field>
  <field number='25037' name='UUID' type='STRING'/>
  <field number='25039' name='MinQtyIncrement' type='QTY'/>
  <field number='25040' name='MarketMinTradeVol' type='QTY'/>
  <field number='25041' name='MarketMaxTradeVol' type='QTY'/>
  <field number='25042' name='MarketMinQtyIncrement' type='QTY'/>
  <field number='25043' name='FirstBookUpdateID' type='INT'/>
  <field number='25044' name='LastBookUpdateID' type='INT'/>
 </fields>
</fix>
)";
}

std::string FixOeSchema() {
  return R"(<fix major='4' type='FIX' servicepack='0' minor='4'>
 <header>
  <field name='BeginString' required='Y'/>
  <field name='BodyLength' required='Y'/>
  <field name='MsgType' required='Y'/>
  <field name='SenderCompID' required='Y'/>
  <field name='TargetCompID' required='Y'/>
  <field name='MsgSeqNum' required='Y'/>
  <field name='SendingTime' required='Y'/>
  <field name='RecvWindow' required='N'/>
 </header>
 <messages>
  <message name='Heartbeat' msgcat='admin' msgtype='0'>
   <field name='TestReqID' required='N'/>
  </message>
  <message name='TestRequest' msgcat='admin' msgtype='1'>
   <field name='TestReqID' required='Y'/>
  </message>
  <message name='Reject' msgcat='admin' msgtype='3'>
   <field name='RefSeqNum' required='N'/>
   <field name='RefTagID' required='N'/>
   <field name='RefMsgType' required='N'/>
   <field name='SessionRejectReason' required='N'/>
   <field name='ErrorCode' required='N'/>
   <field name='Text' required='N'/>
  </message>
  <message name='Logout' msgcat='admin' msgtype='5'>
   <field name='Text' required='N'/>
  </message>
  <message name='ExecutionReport' msgcat='app' msgtype='8'>
   <field name='ExecID' required='N'/>
   <field name='ClOrdID' required='N'/>
   <field name='OrigClOrdID' required='N'/>
   <field name='OrderID' required='N'/>
   <field name='OrderQty' required='N'/>
   <field name='OrdType' required='Y'/>
   <field name='Side' required='Y'/>
   <field name='Symbol' required='Y'/>
   <field name='ExecInst' required='N'/>
   <field name='Price' required='N'/>
   <component name='TriggeringInstruction' required='N'/>
   <field name='TimeInForce' required='N'/>
   <field name='TransactTime' required='N'/>
   <field name='OrderCreationTime' required='N'/>
   <field name='MaxFloor' required='N'/>
   <field name='ListID' required='N'/>
   <field name='CashOrderQty' required='N'/>
   <field name='TargetStrategy' required='N'/>
   <field name='StrategyID' required='N'/>
   <field name='SelfTradePreventionMode' required='N'/>
   <field name='ExecType' required='Y'/>
   <field name='CumQty' required='Y'/>
   <field name='LeavesQty' required='N'/>
   <field name='CumQuoteQty' required='N'/>
   <field name='AggressorIndicator' required='N'/>
   <field name='TradeID' required='N'/>
   <field name='LastPx' required='N'/>
   <field name='LastQty' required='Y'/>
   <field name='OrdStatus' required='Y'/>
   <field name='AllocID' required='N' />
   <field name='MatchType' required='N' />
   <field name='WorkingFloor' required='N'/>
   <field name='WorkingIndicator' required='N'/>
   <field name='WorkingTime' required='N'/>
   <field name='TrailingTime' required='N'/>
   <field name='PreventedMatchID' required='N'/>
   <field name='PreventedExecutionPrice' required='N'/>
   <field name='PreventedExecutionQty' required='N'/>
   <field name='TradeGroupID' required='N'/>
   <field name='CounterSymbol' required='N'/>
   <field name='CounterOrderID' required='N'/>
   <field name='PreventedQty' required='N'/>
   <field name='LastPreventedQty' required='N'/>
   <field name='SOR' required='N'/>
   <group name='NoMiscFees' required='N'>
    <field name='MiscFeeAmt' required='Y'/>
    <field name='MiscFeeCurr' required='Y'/>
    <field name='MiscFeeType' required='Y'/>
   </group>
   <field name='OrdRejReason' required='N'/>
   <field name='ErrorCode' required='N'/>
   <field name='Text' required='N'/>
  </message>
  <message name='OrderCancelReject' msgcat='app' msgtype='9'>
   <field name='ClOrdID' required='Y'/>
   <field name='OrigClOrdID' required='N'/>
   <field name='OrderID' required='N'/>
   <field name='OrigClListID' required='N'/>
   <field name='ListID' required='N'/>
   <field name='Symbol' required='Y'/>
   <field name='CancelRestrictions' required='N'/>
   <field name='CxlRejResponseTo' required='Y'/>
   <field name='ErrorCode' required='Y'/>
   <field name='Text' required='Y'/>
  </message>
  <message name='OrderCancelRequestAndNewOrderSingle' msgcat='app' msgtype='XCN'>
   <field name='OrderCancelRequestAndNewOrderSingleMode' required='Y'/>
   <field name='OrderRateLimitExceededMode' required='N'/>
   <field name='OrderID' required='N'/>
   <field name='CancelClOrdID' required='N'/>
   <field name='OrigClOrdID' required='N'/>
   <field name='CancelRestrictions' required='N'/>
   <component name='NewOrder' required='Y'/>
  </message>
  <message name='Logon' msgcat='admin' msgtype='A'>
   <field name='EncryptMethod' required='N'/>
   <field name='HeartBtInt' required='Y'/>
   <field name='RawDataLength' required='N'/>
   <field name='RawData' required='N'/>
   <field name='ResetSeqNumFlag' required='N'/>
   <field name='Username' required='N'/>
   <field name='MessageHandling' required='N'/>
   <field name='ResponseMode' required='N'/>
   <field name='DropCopyFlag' required='N'/>
   <field name='UUID' required='N'/>
  </message>
  <message name='NewOrderSingle' msgcat='app' msgtype='D'>
   <component name='NewOrder' required='Y'/>
   <field name='SOR' required='N'/>
  </message>
  <message name='NewOrderList' msgcat='app' msgtype='E'>
   <field name='ClListID' required='Y'/>
   <field name='ContingencyType' required='Y'/>
   <group name='NoOrders' required='N'>
    <component name='NewOrder' required='Y'/>
    <component name='ListTriggeringInstruction' required='N'/>
   </group>
  </message>
  <message name='OrderCancelRequest' msgcat='app' msgtype='F'>
   <field name='ClOrdID' required='Y'/>
   <field name='OrigClOrdID' required='N'/>
   <field name='OrderID' required='N'/>
   <field name='OrigClListID' required='N'/>
   <field name='ListID' required='N'/>
   <field name='Symbol' required='Y'/>
   <field name='CancelRestrictions' required='N'/>
  </message>
  <message name='ListStatus' msgcat='app' msgtype='N'>
   <field name='Symbol' required='Y'/>
   <field name='ListID' required='N'/>
   <field name='ClListID' required='N'/>
   <field name='OrigClListID' required='N'/>
   <field name='ContingencyType' required='N'/>
   <field name='ListStatusType' required='Y'/>
   <field name='ListOrderStatus' required='Y'/>
   <field name='ListRejectReason' required='N'/>
   <field name='TransactTime' required='N'/>
   <group name='NoOrders' required='N'>
    <field name='ClOrdID' required='Y'/>
    <field name='Symbol' required='Y'/>
    <field name='OrderID' required='N'/>
    <component name='ListTriggeringInstruction' required='N'/>
    <field name='OrdRejReason' required='N'/>
    <field name='ErrorCode' required='N'/>
    <field name='Text' required='N'/>
   </group>
  </message>
  <message name='OrderMassCancelRequest' msgcat='app' msgtype='q'>
   <field name='Symbol' required='Y'/>
   <field name='ClOrdID' required='Y'/>
   <field name='MassCancelRequestType' required='Y'/>
  </message>
  <message name='OrderMassCancelReport' msgcat='app' msgtype='r'>
   <field name='Symbol' required='Y'/>
   <field name='ClOrdID' required='Y'/>
   <field name='MassCancelRequestType' required='Y'/>
   <field name='MassCancelResponse' required='Y'/>
   <field name='MassCancelRejectReason' required='N'/>
   <field name='TotalAffectedOrders' required='N'/>
   <field name='ErrorCode' required='N'/>
   <field name='Text' required='N'/>
  </message>
  <message name='OrderAmendKeepPriorityRequest' msgcat='app' msgtype='XAK'>
   <field name='ClOrdID' required='Y'/>
   <field name='OrigClOrdID' required='N'/>
   <field name='OrderID' required='N'/>
   <field name='Symbol' required='Y'/>
   <field name='OrderQty' required='Y'/>
  </message>
  <message name='OrderAmendReject' msgcat='app' msgtype='XAR'>
   <field name='ClOrdID' required='Y'/>
   <field name='OrigClOrdID' required='N'/>
   <field name='OrderID' required='N'/>
   <field name='Symbol' required='Y'/>
   <field name='OrderQty' required='Y'/>
   <field name='ErrorCode' required='Y'/>
   <field name='Text' required='Y'/>
  </message>
  <message name='LimitQuery' msgcat='app' msgtype='XLQ'>
   <field name='ReqID' required='Y'/>
  </message>
  <message name='LimitResponse' msgcat='app' msgtype='XLR'>
   <field name='ReqID' required='Y'/>
   <group name='NoLimitIndicators' required='Y'>
    <field name='LimitType' required='Y'/>
    <field name='LimitCount' required='Y'/>
    <field name='LimitMax' required='Y'/>
    <field name='LimitResetInterval' required='N'/>
    <field name='LimitResetIntervalResolution' required='N'/>
   </group>
  </message>
  <message name='News' msgtype='B' msgcat='app'>
   <field name='Headline' required='Y'/>
  </message>
 </messages>
 <trailer>
  <field name='CheckSum' required='Y'/>
 </trailer>
 <components>
  <component name='TriggeringInstruction'>
   <field name='TriggerType' required='N'/>
   <field name='TriggerAction' required='N'/>
   <field name='TriggerPrice' required='N'/>
   <field name='TriggerPriceType' required='N'/>
   <field name='TriggerPriceDirection' required='N'/>
   <field name='TriggerTrailingDeltaBips' required='N'/>
  </component>
  <component name='ListTriggeringInstruction'>
   <group name='NoListTriggeringInstructions' required='N'>
    <field name='ListTriggerType' required='Y'/>
    <field name='ListTriggerTriggerIndex' required='Y'/>
    <field name='ListTriggerAction' required='Y'/>
   </group>
  </component>
  <component name='NewOrder'>
   <field name='ClOrdID' required='Y'/>
   <field name='OrderQty' required='N'/>
   <field name='OrdType' required='Y'/>
   <field name='ExecInst' required='N'/>
   <field name='Price' required='N'/>
   <component name='TriggeringInstruction' required='N'/>
   <field name='Side' required='Y'/>
   <field name='Symbol' required='Y'/>
   <field name='TimeInForce' required='N'/>
   <field name='MaxFloor' required='N'/>
   <field name='CashOrderQty' required='N'/>
   <field name='TargetStrategy' required='N'/>
   <field name='StrategyID' required='N'/>
   <field name='SelfTradePreventionMode' required='N'/>
  </component>
 </components>
 <fields>
  <field number='8' name='BeginString' type='STRING'>
   <value enum='FIX.4.4' description='FIX44'/>
  </field>
  <field number='9' name='BodyLength' type='LENGTH'/>
  <field number='10' name='CheckSum' type='STRING'/>
  <field number='11' name='ClOrdID' type='STRING'/>
  <field number='14' name='CumQty' type='QTY'/>
  <field number='17' name='ExecID' type='INT'/>
  <field number='18' name='ExecInst' type='CHAR'>
   <value enum='6' description='PARTICIPATE_DONT_INITIATE'/>
  </field>
  <field number='31' name='LastPx' type='PRICE'/>
  <field number='32' name='LastQty' type='QTY'/>
  <field number='34' name='MsgSeqNum' type='SEQNUM'/>
  <field number='35' name='MsgType' type='STRING'>
   <value enum='0' description='HEARTBEAT'/>
   <value enum='1' description='TEST_REQUEST'/>
   <value enum='3' description='REJECT'/>
   <value enum='5' description='LOGOUT'/>
   <value enum='8' description='EXECUTION_REPORT'/>
   <value enum='9' description='ORDER_CANCEL_REJECT'/>
   <value enum='A' description='LOGON'/>
   <value enum='B' description='NEWS'/>
   <value enum='D' description='NEW_ORDER_SINGLE'/>
   <value enum='E' description='NEW_ORDER_LIST'/>
   <value enum='F' description='ORDER_CANCEL_REQUEST'/>
   <value enum='N' description='LIST_STATUS'/>
   <value enum='q' description='ORDER_MASS_CANCEL_REQUEST'/>
   <value enum='r' description='ORDER_MASS_CANCEL_REPORT'/>
   <value enum='XAK' description='ORDER_AMEND_KEEP_PRIORITY_REQUEST'/>
   <value enum='XAR' description='ORDER_AMEND_REJECT'/>
   <value enum='XCN' description='ORDER_CANCEL_REQUEST_AND_NEW_ORDER_SINGLE'/>
   <value enum='XLQ' description='LIMIT_QUERY'/>
   <value enum='XLR' description='LIMIT_RESPONSE'/>
  </field>
  <field number='37' name='OrderID' type='INT'/>
  <field number='38' name='OrderQty' type='QTY'/>
  <field number='39' name='OrdStatus' type='CHAR'>
   <value enum='0' description='NEW'/>
   <value enum='1' description='PARTIALLY_FILLED'/>
   <value enum='2' description='FILLED'/>
   <value enum='4' description='CANCELED'/>
   <value enum='6' description='PENDING_CANCEL'/>
   <value enum='8' description='REJECTED'/>
   <value enum='A' description='PENDING_NEW'/>
   <value enum='C' description='EXPIRED'/>
  </field>
  <field number='40' name='OrdType' type='CHAR'>
   <value enum='1' description='MARKET'/>
   <value enum='2' description='LIMIT'/>
   <value enum='3' description='STOP'/>
   <value enum='4' description='STOP_LIMIT'/>
  </field>
  <field number='41' name='OrigClOrdID' type='STRING'/>
  <field number='44' name='Price' type='PRICE'/>
  <field number='45' name='RefSeqNum' type='INT'/>
  <field number='49' name='SenderCompID' type='STRING'/>
  <field number='52' name='SendingTime' type='UTCTIMESTAMP'/>
  <field number='54' name='Side' type='CHAR'>
   <value enum='1' description='BUY'/>
   <value enum='2' description='SELL'/>
  </field>
  <field number='55' name='Symbol' type='STRING'/>
  <field number='56' name='TargetCompID' type='STRING'/>
  <field number='58' name='Text' type='STRING'/>
  <field number='59' name='TimeInForce' type='CHAR'>
   <value enum='1' description='GOOD_TILL_CANCEL'/>
   <value enum='3' description='IMMEDIATE_OR_CANCEL'/>
   <value enum='4' description='FILL_OR_KILL'/>
  </field>
  <field number='60' name='TransactTime' type='UTCTIMESTAMP'/>
  <field number='66' name='ListID' type='INT'/>
  <field number='70' name='AllocID' type='INT'/>
  <field number='73' name='NoOrders' type='NUMINGROUP'/>
  <field number='95' name='RawDataLength' type='LENGTH'/>
  <field number='96' name='RawData' type='DATA'/>
  <field number='98' name='EncryptMethod' type='INT'>
   <value enum='0' description='NONE'/>
  </field>
  <field number='103' name='OrdRejReason' type='INT'>
   <value enum='99' description='OTHER'/>
  </field>
  <field number='108' name='HeartBtInt' type='INT'/>
  <field number='111' name='MaxFloor' type='QTY'/>
  <field number='112' name='TestReqID' type='STRING'/>
  <field number='136' name='NoMiscFees' type='NUMINGROUP'/>
  <field number='137' name='MiscFeeAmt' type='QTY'/>
  <field number='138' name='MiscFeeCurr' type='STRING'/>
  <field number='139' name='MiscFeeType' type='INT'>
   <value enum='4' description='EXCHANGE_FEES'/>
  </field>
  <field number='141' name='ResetSeqNumFlag' type='BOOLEAN'>
   <value enum='Y' description='YES'/>
   <value enum='N' description='NO'/>
  </field>
  <field number='148' name='Headline' type='STRING'/>
  <field number='150' name='ExecType' type='CHAR'>
   <value enum='0' description='NEW'/>
   <value enum='4' description='CANCELED'/>
   <value enum='5' description='REPLACED'/>
   <value enum='8' description='REJECTED'/>
   <value enum='F' description='TRADE'/>
   <value enum='C' description='EXPIRED'/>
  </field>
  <field number='151' name='LeavesQty' type='QTY'/>
  <field number='152' name='CashOrderQty' type='QTY'/>
  <field number='371' name='RefTagID' type='INT'/>
  <field number='372' name='RefMsgType' type='STRING'/>
  <field number='373' name='SessionRejectReason' type='INT'>
   <value enum='0' description='INVALID_TAG_NUMBER'/>
   <value enum='1' description='REQUIRED_TAG_MISSING'/>
   <value enum='2' description='TAG_NOT_DEFINED_FOR_THIS_MESSAGE_TYPE'/>
   <value enum='3' description='UNDEFINED_TAG'/>
   <value enum='5' description='VALUE_IS_INCORRECT'/>
   <value enum='6' description='INCORRECT_DATA_FORMAT_FOR_VALUE'/>
   <value enum='8' description='SIGNATURE_PROBLEM'/>
   <value enum='10' description='SENDINGTIME_ACCURACY_PROBLEM'/>
   <value enum='13' description='TAG_APPEARS_MORE_THAN_ONCE'/>
   <value enum='14' description='TAG_SPECIFIED_OUT_OF_REQUIRED_ORDER'/>
   <value enum='15' description='REPEATING_GROUP_FIELDS_OUT_OF_ORDER'/>
   <value enum='16' description='INCORRECT_NUMINGROUP_COUNT_FOR_REPEATING_GROUP'/>
   <value enum='99' description='OTHER'/>
  </field>
  <field number='429' name='ListStatusType' type='INT'>
   <value enum='2' description='RESPONSE'/>
   <value enum='4' description='EXEC_STARTED'/>
   <value enum='5' description='ALL_DONE'/>
   <value enum='100' description='UPDATED'/>
  </field>
  <field number='431' name='ListOrderStatus' type='INT'>
   <value enum='3' description='EXECUTING'/>
   <value enum='6' description='ALL_DONE'/>
   <value enum='7' description='REJECT'/>
  </field>
  <field number='434' name='CxlRejResponseTo' type='CHAR'>
   <value enum='1' description='ORDER_CANCEL_REQUEST'/>
  </field>
  <field number='530' name='MassCancelRequestType' type='CHAR'>
   <value enum='1' description='CANCEL_SYMBOL_ORDERS'/>
  </field>
  <field number='531' name='MassCancelResponse' type='CHAR'>
   <value enum='0' description='CANCEL_REQUEST_REJECTED'/>
   <value enum='1' description='CANCEL_SYMBOL_ORDERS'/>
  </field>
  <field number='532' name='MassCancelRejectReason' type='INT'>
   <value enum='99' description='OTHER'/>
  </field>
  <field number='533' name='TotalAffectedOrders' type='INT'/>
  <field number='553' name='Username' type='STRING'/>
  <field number='574' name='MatchType' type='STRING'>
   <value enum='1' description='ONE_PARTY_TRADE_REPORT'/>
   <value enum='4' description='AUTO_MATCH'/>
  </field>
  <field number='636' name='WorkingIndicator' type='BOOLEAN'/>
  <field number='811' name='PriceDelta' type='INT'/>
  <field number='847' name='TargetStrategy' type='INT'/>
  <field number='1003' name='TradeID' type='INT'/>
  <field number='1057' name='AggressorIndicator' type='BOOLEAN'>
   <value enum='Y' description='ORDER_INITIATOR_IS_AGGRESSOR'/>
   <value enum='N' description='ORDER_INITIATOR_IS_PASSIVE'/>
  </field>
  <field number='1100' name='TriggerType' type='CHAR'>
   <value enum='4' description='PRICE_MOVEMENT'/>
  </field>
  <field number='1101' name='TriggerAction' type='CHAR'>
   <value enum='1' description='ACTIVATE'/>
  </field>
  <field number='1102' name='TriggerPrice' type='PRICE'/>
  <field number='1107' name='TriggerPriceType' type='CHAR'>
   <value enum='2' description='LAST_TRADE'/>
  </field>
  <field number='1109' name='TriggerPriceDirection' type='CHAR'>
   <value enum='U'
          description='TRIGGER_IF_THE_PRICE_OF_THE_SPECIFIED_TYPE_GOES_UP_TO_OR_THROUGH_THE_SPECIFIED_TRIGGER_PRICE'/>
   <value enum='D'
          description='TRIGGER_IF_THE_PRICE_OF_THE_SPECIFIED_TYPE_GOES_DOWN_TO_OR_THROUGH_THE_SPECIFIED_TRIGGER_PRICE'/>
  </field>
  <field number='1385' name='ContingencyType' type='INT'>
   <value enum='1' description='ONE_CANCELS_THE_OTHER'/>
   <value enum='2' description='ONE_TRIGGERS_THE_OTHER'/>
  </field>
  <field number='1386' name='ListRejectReason' type='INT'>
   <value enum='99' description='OTHER'/>
  </field>
  <field number='6136' name='ReqID' type='STRING'/>
  <field number='7940' name='StrategyID' type='INT'/>
  <field number='9406' name='DropCopyFlag' type='BOOLEAN'/>
  <field number='25000' name='RecvWindow' type='INT'/>
  <field number='25001' name='SelfTradePreventionMode' type='CHAR'>
   <value enum='1' description='NONE'/>
   <value enum='2' description='EXPIRE_TAKER'/>
   <value enum='3' description='EXPIRE_MAKER'/>
   <value enum='4' description='EXPIRE_BOTH'/>
   <value enum='5' description='DECREMENT'/>
  </field>
  <field number='25002' name='CancelRestrictions' type='INT'>
   <value enum='1' description='ONLY_NEW'/>
   <value enum='2' description='ONLY_PARTIALLY_FILLED'/>
  </field>
  <field number='25003' name='NoLimitIndicators' type='NUMINGROUP'/>
  <field number='25004' name='LimitType' type='CHAR'>
   <value enum='1' description='ORDER_LIMIT'/>
   <value enum='2' description='MESSAGE_LIMIT'/>
  </field>
  <field number='25005' name='LimitCount' type='INT'/>
  <field number='25006' name='LimitMax' type='INT'/>
  <field number='25007' name='LimitResetInterval' type='INT'/>
  <field number='25008' name='LimitResetIntervalResolution' type='CHAR'>
   <value enum='s' description='SECOND'/>
   <value enum='m' description='MINUTE'/>
   <value enum='h' description='HOUR'/>
   <value enum='d' description='DAY'/>
  </field>
  <field number='25009' name='TriggerTrailingDeltaBips' type='INT'/>
  <field number='25010' name='NoListTriggeringInstructions' type='NUMINGROUP'/>
  <field number='25011' name='ListTriggerType' type='CHAR'>
   <value enum='1' description='ACTIVATED'/>
   <value enum='2' description='PARTIALLY_FILLED'/>
   <value enum='3' description='FILLED'/>
  </field>
  <field number='25012' name='ListTriggerTriggerIndex' type='INT'/>
  <field number='25013' name='ListTriggerAction' type='CHAR'>
   <value enum='1' description='RELEASE'/>
   <value enum='2' description='CANCEL'/>
  </field>
  <field number='25014' name='ClListID' type='STRING'/>
  <field number='25015' name='OrigClListID' type='STRING'/>
  <field number='25016' name='ErrorCode' type='INT'/>
  <field number='25017' name='CumQuoteQty' type='QTY'/>
  <field number='25018' name='OrderCreationTime' type='UTCTIMESTAMP'/>
  <field number='25021' name='WorkingFloor' type='INT'>
   <value enum='1' description='EXCHANGE'/>
   <value enum='2' description='BROKER'/>
   <value enum='3' description='SOR'/>
  </field>
  <field number='25022' name='TrailingTime' type='UTCTIMESTAMP'/>
  <field number='25023' name='WorkingTime' type='UTCTIMESTAMP'/>
  <field number='25024' name='PreventedMatchID' type='INT'/>
  <field number='25025' name='PreventedExecutionPrice' type='PRICE'/>
  <field number='25026' name='PreventedExecutionQty' type='QTY'/>
  <field number='25027' name='TradeGroupID' type='INT'/>
  <field number='25028' name='CounterSymbol' type='STRING'/>
  <field number='25029' name='CounterOrderID' type='INT'/>
  <field number='25030' name='PreventedQty' type='QTY'/>
  <field number='25031' name='LastPreventedQty' type='QTY'/>
  <field number='25032' name='SOR' type='BOOLEAN'/>
  <field number='25033' name='OrderCancelRequestAndNewOrderSingleMode' type='INT'>
   <value enum='1' description='STOP_ON_FAILURE'/>
   <value enum='2' description='ALLOW_FAILURE'/>
  </field>
  <field number='25034' name='CancelClOrdID' type='STRING'/>
  <field number='25035' name='MessageHandling' type='INT'>
   <value enum='1' description='UNORDERED'/>
   <value enum='2' description='SEQUENTIAL'/>
  </field>
  <field number='25036' name='ResponseMode' type='INT'>
   <value enum='1' description='EVERYTHING'/>
   <value enum='2' description='ONLY_ACKS'/>
  </field>
  <field number='25037' name='UUID' type='STRING'/>
  <field number='25038' name='OrderRateLimitExceededMode' type='INT'>
   <value enum='1' description='DO_NOTHING'/>
   <value enum='2' description='CANCEL_ONLY'/>
  </field>
 </fields>
</fix>
)";
}

FixConfig::FixConfig(IConfiguration &config) {

  // prepare fix file store
  // delete old files that contain state
  prepareFixFileStore(config.getFixFileStorePath());

  // write schemas to disk
  auto tmpMd = writeSchemaToTemp(FixMdSchema(), "spot-fix-md.xml");
  auto tmpOe = writeSchemaToTemp(FixOeSchema(), "spot-fix-oe.xml");

  // build config string
  std::string confString = R"(
  # default settings for sessions
  [DEFAULT]
  StartTime=00:00:00
  EndTime=00:00:00
  HeartBtInt=30
  FileStorePath=)" + config.getFixFileStorePath() +
                           R"(
  ConnectionType=initiator
  TargetCompID=SPOT
  DefaultApplVerID=FIX.4.4
  BeginString=FIX.4.4
    
  # set TCP_NODELAY (disable Nagle's algorithm)
  # this is required for low latency
  SocketNodelay=Y
)";

  // hide screen logging of FIX messages unless highest verbosity used
  if (config.getLogLevel() > 0) {
    confString += R"(
  # silence logging
  ScreenLogShowOutgoing=N
  ScreenLogShowIncoming=N
)";
  }

  // hide events when not in trace or debug mode
  if (config.getLogLevel() > 1) {
    confString += R"(
  # silence logging
  ScreenLogShowEvents=N
  )";
  }

  confString += R"(    
  # sessions
  [SESSION]
  SenderCompID=HARJUSM1
  SessionQualifier=MARKETDATA
  DataDictionary=)" +
                tmpMd +
                R"(
  SocketConnectHost=)" +
                config.getBinanceFIXApiHostnameMarketData() +
                R"(
  SocketConnectPort=)" +
                config.getBinanceFIXApiPortMarketData() +
                R"(
    
  [SESSION]
  SenderCompID=HARJUSM2
  SessionQualifier=MARKETDATA
  DataDictionary=)" +
                tmpMd +
                R"(
  SocketConnectHost=)" +
                config.getBinanceFIXApiHostnameMarketData() +
                R"(
  SocketConnectPort=)" +
                config.getBinanceFIXApiPortMarketData() +
                R"(

  [SESSION]
  SenderCompID=HARJUSOE
  SessionQualifier=ORDERENTRY
  DataDictionary=)" +
                tmpOe +
                R"(
  SocketConnectHost=)" +
                config.getBinanceFIXApiHostnameOrderEntry() +
                R"(
  SocketConnectPort=)" +
                config.getBinanceFIXApiPortOrderEntry() +
                R"(
  )";

  _configString = confString;
}

FIX::SessionSettings FixConfig::sessionSettings() const {
  std::istringstream fixConfigStream{_configString};
  return FIX::SessionSettings{fixConfigStream};
}