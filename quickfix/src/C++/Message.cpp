/****************************************************************************
** Copyright (c) 2001-2014
**
** This file is part of the QuickFIX FIX Engine
**
** This file may be distributed under the terms of the quickfixengine.org
** license as defined by quickfixengine.org and appearing in the file
** LICENSE included in the packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://www.quickfixengine.org/LICENSE for licensing information.
**
** Contact ask@quickfixengine.org if any conditions of this licensing are
** not clear to you.
**
****************************************************************************/

#ifdef _MSC_VER
#include "stdafx.h"
#else
#include "config.h"
#endif

#include "Message.h"
#include "Utility.h"
#include "Values.h"
#include <iomanip>
#include <memory>

namespace FIX
{

    int const headerOrder[] = {FIELD::BeginString, FIELD::BodyLength, FIELD::MsgType};

    std::unique_ptr<DataDictionary> Message::s_dataDictionary;

    Message::Message()
        : m_validStructure(true),
          m_tag(0) {}

    Message::Message(const message_order &headerOrder, const message_order &trailerOrder, const message_order &order)
        : FieldMap(order),
          m_header(headerOrder),
          m_trailer(trailerOrder),
          m_validStructure(true) {}

    Message::Message(const std::string &string, bool validate) EXCEPT(InvalidMessage)
        : m_validStructure(true),
          m_tag(0)
    {
        setString(string, validate);
    }

    Message::Message(const std::string &string, const DataDictionary &dataDictionary, bool validate) EXCEPT(InvalidMessage)
        : m_validStructure(true),
          m_tag(0)
    {
        setString(string, validate, &dataDictionary, &dataDictionary);
    }

    Message::Message(
        const std::string &string,
        const DataDictionary &sessionDataDictionary,
        const DataDictionary &applicationDataDictionary,
        bool validate) EXCEPT(InvalidMessage)
        : m_validStructure(true),
          m_tag(0)
    {
        setString(string, validate, &sessionDataDictionary, &applicationDataDictionary);
    }

    Message::Message(
        const message_order &headerOrder,
        const message_order &trailerOrder,
        const message_order &order,
        const std::string &string,
        const DataDictionary &dataDictionary,
        bool validate) EXCEPT(InvalidMessage)
        : FieldMap(order),
          m_header(headerOrder),
          m_trailer(trailerOrder),
          m_validStructure(true)
    {
        setString(string, validate, &dataDictionary, &dataDictionary);
    }

    Message::Message(
        const message_order &headerOrder,
        const message_order &trailerOrder,
        const message_order &order,
        const std::string &string,
        const DataDictionary &sessionDataDictionary,
        const DataDictionary &applicationDataDictionary,
        bool validate) EXCEPT(InvalidMessage)
        : FieldMap(order),
          m_header(headerOrder),
          m_trailer(trailerOrder),
          m_validStructure(true)
    {
        setStringHeader(string);
        if (isAdmin())
        {
            setString(string, validate, &sessionDataDictionary, &sessionDataDictionary);
        }
        else
        {
            setString(string, validate, &sessionDataDictionary, &applicationDataDictionary);
        }
    }

    Message::Message(const BeginString &beginString, const MsgType &msgType)
        : m_validStructure(true),
          m_tag(0)
    {
        m_header.setField(beginString);
        m_header.setField(msgType);
    }

    Message::~Message() = default;

    auto Message::InitializeXML(const std::string &url) -> bool
    {
        try
        {
            s_dataDictionary = std::make_unique<DataDictionary>(url);
            return true;
        }
        catch (ConfigError &)
        {
            return false;
        }
    }

    void Message::reverseRoute(const Header &header)
    {
        // required routing tags
        BeginString beginString;
        SenderCompID senderCompID;
        TargetCompID targetCompID;

        m_header.removeField(beginString.getTag());
        m_header.removeField(senderCompID.getTag());
        m_header.removeField(targetCompID.getTag());

        if (header.getFieldIfSet(beginString))
        {
            if (beginString.getValue().size())
            {
                m_header.setField(beginString);
            }

            OnBehalfOfLocationID onBehalfOfLocationID;
            DeliverToLocationID deliverToLocationID;

            m_header.removeField(onBehalfOfLocationID.getTag());
            m_header.removeField(deliverToLocationID.getTag());

            if (beginString >= BeginString_FIX41)
            {
                if (header.getFieldIfSet(onBehalfOfLocationID))
                {
                    if (onBehalfOfLocationID.getValue().size())
                    {
                        m_header.setField(DeliverToLocationID(onBehalfOfLocationID));
                    }
                }

                if (header.getFieldIfSet(deliverToLocationID))
                {
                    if (deliverToLocationID.getValue().size())
                    {
                        m_header.setField(OnBehalfOfLocationID(deliverToLocationID));
                    }
                }
            }
        }

        if (header.getFieldIfSet(senderCompID))
        {
            if (senderCompID.getValue().size())
            {
                m_header.setField(TargetCompID(senderCompID));
            }
        }

        if (header.getFieldIfSet(targetCompID))
        {
            if (targetCompID.getValue().size())
            {
                m_header.setField(SenderCompID(targetCompID));
            }
        }

        // optional routing tags
        OnBehalfOfCompID onBehalfOfCompID;
        OnBehalfOfSubID onBehalfOfSubID;
        DeliverToCompID deliverToCompID;
        DeliverToSubID deliverToSubID;

        m_header.removeField(onBehalfOfCompID.getTag());
        m_header.removeField(onBehalfOfSubID.getTag());
        m_header.removeField(deliverToCompID.getTag());
        m_header.removeField(deliverToSubID.getTag());

        if (header.getFieldIfSet(onBehalfOfCompID))
        {
            if (onBehalfOfCompID.getValue().size())
            {
                m_header.setField(DeliverToCompID(onBehalfOfCompID));
            }
        }

        if (header.getFieldIfSet(onBehalfOfSubID))
        {
            if (onBehalfOfSubID.getValue().size())
            {
                m_header.setField(DeliverToSubID(onBehalfOfSubID));
            }
        }

        if (header.getFieldIfSet(deliverToCompID))
        {
            if (deliverToCompID.getValue().size())
            {
                m_header.setField(OnBehalfOfCompID(deliverToCompID));
            }
        }

        if (header.getFieldIfSet(deliverToSubID))
        {
            if (deliverToSubID.getValue().size())
            {
                m_header.setField(OnBehalfOfSubID(deliverToSubID));
            }
        }
    }

    auto Message::toString(int beginStringField, int bodyLengthField, int checkSumField) const -> std::string
    {
        std::string str;
        toString(str, beginStringField, bodyLengthField, checkSumField);
        return str;
    }

    auto Message::toString(std::string &str, int beginStringField, int bodyLengthField, int checkSumField) const -> std::string &
    {
        size_t length = bodyLength(beginStringField, bodyLengthField, checkSumField);
        m_header.setField(IntField(bodyLengthField, static_cast<int>(length)));
        m_trailer.setField(CheckSumField(checkSumField, checkSum(checkSumField)));

#if defined(_MSC_VER) && _MSC_VER < 1300
        str = "";
#else
        str.clear();
#endif

        /*small speculation about the space needed for FIX string*/
        str.reserve(length + 64);

        m_header.calculateString(str);
        FieldMap::calculateString(str);
        m_trailer.calculateString(str);

        return str;
    }

    auto Message::toXML() const -> std::string
    {
        std::string str;
        toXML(str);
        return str;
    }

    auto Message::toXML(std::string &str) const -> std::string &
    {
        std::stringstream stream;
        stream << "<message>" << '\n'
               << std::setw(2) << " " << "<header>" << '\n'
               << toXMLFields(getHeader(), 4) << std::setw(2) << " " << "</header>" << '\n'
               << std::setw(2) << " " << "<body>" << '\n'
               << toXMLFields(*this, 4) << std::setw(2) << " " << "</body>" << '\n'
               << std::setw(2) << " " << "<trailer>" << '\n'
               << toXMLFields(getTrailer(), 4) << std::setw(2) << " " << "</trailer>" << '\n'
               << "</message>";

        return str = stream.str();
    }

    auto Message::toXMLFields(const FieldMap &fields, int space) const -> std::string
    {
        std::stringstream stream;
        std::string name;
        for (const FieldMap::value_type &field : fields)
        {
            int tag = field.getTag();
            const std::string& value = field.getString();

            stream << std::setw(space) << " " << "<field ";
            if (s_dataDictionary.get() && s_dataDictionary->getFieldName(tag, name))
            {
                stream << "name=\"" << name << "\" ";
            }
            stream << "number=\"" << tag << "\"";
            if (s_dataDictionary.get() && s_dataDictionary->getValueName(tag, value, name))
            {
                stream << " enum=\"" << name << "\"";
            }
            stream << ">";
            stream << "<![CDATA[" << value << "]]>";
            stream << "</field>" << '\n';
        }

        for (const FieldMap::g_value_type &group : fields.groups())
        {
            for (const FieldMap *groupFields : group.second)
            {
                stream << std::setw(space) << " " << "<group>" << '\n'
                       << toXMLFields(*groupFields, space + 2) << std::setw(space) << " " << "</group>" << '\n';
            }
        }

        return stream.str();
    }

    void Message::setString(
        const std::string &string,
        bool doValidation,
        const DataDictionary *pSessionDataDictionary,
        const DataDictionary *pApplicationDataDictionary) EXCEPT(InvalidMessage)
    {
        clear();

        std::string::size_type pos = 0;
        int count = 0;

        FIX::MsgType msg;

        field_type type = header;

        while (pos < string.size())
        {
            FieldBase field = extractField(string, pos, pSessionDataDictionary, pApplicationDataDictionary);
            if (count < 3 && headerOrder[count++] != field.getTag())
            {
                if (doValidation)
                {
                    throw InvalidMessage("Header fields out of order");
                }
            }

            if (isHeaderField(field, pSessionDataDictionary))
            {
                if (type != header)
                {
                    if (m_tag == 0)
                    {
                        m_tag = field.getTag();
                    }
                    m_validStructure = false;
                }

                if (field.getTag() == FIELD::MsgType)
                {
                    msg.setString(field.getString());
                    if (isAdminMsgType(msg))
                    {
                        pApplicationDataDictionary = pSessionDataDictionary;
                    }
                }

                m_header.appendField(field);

                if (pSessionDataDictionary)
                {
                    setGroup("_header_", field, string, pos, getHeader(), *pSessionDataDictionary);
                }
            }
            else if (isTrailerField(field, pSessionDataDictionary))
            {
                type = trailer;
                m_trailer.appendField(field);

                if (pSessionDataDictionary)
                {
                    setGroup("_trailer_", field, string, pos, getTrailer(), *pSessionDataDictionary);
                }
            }
            else
            {
                if (type == trailer)
                {
                    if (m_tag == 0)
                    {
                        m_tag = field.getTag();
                    }
                    m_validStructure = false;
                }

                type = body;
                appendField(field);

                if (pApplicationDataDictionary)
                {
                    setGroup(msg, field, string, pos, *this, *pApplicationDataDictionary);
                }
            }
        }

        // sort fields
        m_header.sortFields();
        sortFields();
        m_trailer.sortFields();

        if (doValidation)
        {
            validate();
        }
    }

    void Message::setGroup(
        const std::string &msg,
        const FieldBase &field,
        const std::string &string,
        std::string::size_type &pos,
        FieldMap &map,
        const DataDictionary &dataDictionary)
    {
        int group = field.getTag();
        int delim = 0;
        const DataDictionary *pDD = nullptr;
        if (!dataDictionary.getGroup(msg, group, delim, pDD))
        {
            return;
        }
        std::unique_ptr<Group> pGroup;

        while (pos < string.size())
        {
            std::string::size_type oldPos = pos;
            FieldBase field = extractField(string, pos, &dataDictionary, &dataDictionary, pGroup.get());

            // Start a new group because...
            if ( // found delimiter
                (field.getTag() == delim) ||
                // no delimiter, but field belongs to group OR field already processed
                (pDD->isField(field.getTag()) && (pGroup.get() == nullptr || pGroup->isSetField(field.getTag()))))
            {
                if (pGroup.get())
                {
                    map.addGroupPtr(group, pGroup.release(), false);
                }
                pGroup = std::make_unique<Group>(field.getTag(), delim, pDD->getOrderedFields());
            }
            else if (!pDD->isField(field.getTag()))
            {
                if (pGroup.get())
                {
                    map.addGroupPtr(group, pGroup.release(), false);
                }
                pos = oldPos;
                return;
            }

            if (!pGroup.get())
            {
                return;
            }
            pGroup->addField(field);
            setGroup(msg, field, string, pos, *pGroup, *pDD);
        }
    }

    auto Message::setStringHeader(const std::string &string) -> bool
    {
        clear();

        std::string::size_type pos = 0;
        int count = 0;

        while (pos < string.size())
        {
            FieldBase field = extractField(string, pos);
            if (count < 3 && headerOrder[count++] != field.getTag())
            {
                return false;
            }

            if (isHeaderField(field))
            {
                m_header.appendField(field);
            }
            else
            {
                break;
            }
        }

        m_header.sortFields();
        return true;
    }

    auto Message::isHeaderField(int field) -> bool
    {
        switch (field)
        {
        case FIELD::BeginString:
        case FIELD::BodyLength:
        case FIELD::MsgType:
        case FIELD::SenderCompID:
        case FIELD::TargetCompID:
        case FIELD::OnBehalfOfCompID:
        case FIELD::DeliverToCompID:
        case FIELD::SecureDataLen:
        case FIELD::MsgSeqNum:
        case FIELD::SenderSubID:
        case FIELD::SenderLocationID:
        case FIELD::TargetSubID:
        case FIELD::TargetLocationID:
        case FIELD::OnBehalfOfSubID:
        case FIELD::OnBehalfOfLocationID:
        case FIELD::DeliverToSubID:
        case FIELD::DeliverToLocationID:
        case FIELD::PossDupFlag:
        case FIELD::PossResend:
        case FIELD::SendingTime:
        case FIELD::OrigSendingTime:
        case FIELD::XmlDataLen:
        case FIELD::XmlData:
        case FIELD::MessageEncoding:
        case FIELD::LastMsgSeqNumProcessed:
        case FIELD::OnBehalfOfSendingTime:
        case FIELD::ApplVerID:
        case FIELD::CstmApplVerID:
        case FIELD::NoHops:
            return true;
        default:
            return false;
        };
    }

    auto Message::isHeaderField(const FieldBase &field, const DataDictionary *pD) -> bool
    {
        return isHeaderField(field.getTag(), pD);
    }

    auto Message::isHeaderField(int field, const DataDictionary *pD) -> bool
    {
        if (isHeaderField(field))
        {
            return true;
        }
        if (pD)
        {
            return pD->isHeaderField(field);
        }
        return false;
    }

    auto Message::isTrailerField(int field) -> bool
    {
        switch (field)
        {
        case FIELD::SignatureLength:
        case FIELD::Signature:
        case FIELD::CheckSum:
            return true;
        default:
            return false;
        };
    }

    auto Message::isTrailerField(const FieldBase &field, const DataDictionary *pD) -> bool
    {
        return isTrailerField(field.getTag(), pD);
    }

    auto Message::isTrailerField(int field, const DataDictionary *pD) -> bool
    {
        if (isTrailerField(field))
        {
            return true;
        }
        if (pD)
        {
            return pD->isTrailerField(field);
        }
        return false;
    }

    auto Message::getSessionID(const std::string &qualifier) const -> SessionID EXCEPT(FieldNotFound)
    {
        return SessionID(
            getHeader().getField<BeginString>(),
            getHeader().getField<SenderCompID>(),
            getHeader().getField<TargetCompID>(),
            qualifier);
    }

    void Message::setSessionID(const SessionID &sessionID)
    {
        getHeader().setField(sessionID.getBeginString());
        getHeader().setField(sessionID.getSenderCompID());
        getHeader().setField(sessionID.getTargetCompID());
    }

    void Message::validate() const
    {
        try
        {
            const auto &aBodyLength = FIELD_GET_REF(m_header, BodyLength);

            const auto expectedLength = static_cast<size_t>(aBodyLength);
            const size_t receivedLength = bodyLength();

            if (expectedLength != receivedLength)
            {
                std::stringstream text;
                text << "Expected BodyLength=" << expectedLength << ", Received BodyLength=" << receivedLength;
                throw InvalidMessage(text.str());
            }

            const auto &aCheckSum = FIELD_GET_REF(m_trailer, CheckSum);

            const int expectedChecksum = (int)aCheckSum;
            const int receivedChecksum = checkSum();

            if (expectedChecksum != receivedChecksum)
            {
                std::stringstream text;
                text << "Expected CheckSum=" << expectedChecksum << ", Received CheckSum=" << receivedChecksum;
                throw InvalidMessage(text.str());
            }
        }
        catch (FieldNotFound &e)
        {
            const std::string fieldName = (e.field == FIX::FIELD::BodyLength) ? "BodyLength" : "CheckSum";
            throw InvalidMessage(fieldName + std::string(" is missing"));
        }
        catch (IncorrectDataFormat &e)
        {
            const std::string fieldName = (e.field == FIX::FIELD::BodyLength) ? "BodyLength" : "CheckSum";
            throw InvalidMessage(fieldName + std::string(" has wrong format: ") + e.detail);
        }
    }

    auto Message::extractField(
        const std::string &string,
        std::string::size_type &pos,
        const DataDictionary *pSessionDD /*= 0*/,
        const DataDictionary *pAppDD /*= 0*/,
        const Group *pGroup /*= 0*/) const -> FIX::FieldBase
    {
        std::string::const_iterator const tagStart = string.begin() + pos;
        std::string::const_iterator const strEnd = string.end();

        std::string::const_iterator const equalSign = std::find(tagStart, strEnd, '=');
        if (equalSign == strEnd)
        {
            throw InvalidMessage("Equal sign not found in field");
        }

        int field = 0;
        if (!IntConvertor::convert(tagStart, equalSign, field))
        {
            throw InvalidMessage(std::string("Field tag is invalid: ") + std::string(tagStart, equalSign));
        }

        std::string::const_iterator const valueStart = equalSign + 1;

        std::string::const_iterator soh = std::find(valueStart, strEnd, '\001');
        if (soh == strEnd)
        {
            throw InvalidMessage("SOH not found at end of field");
        }

        if (IsDataField(field, pSessionDD, pAppDD))
        {
            // Assume length field is 1 less.
            int lenField = field - 1;
            // Special case for Signature which violates above assumption.
            if (field == FIELD::Signature)
            {
                lenField = FIELD::SignatureLength;
            }

            // identify part of the message that should contain length field
            const FieldMap *location = pGroup;
            if (!location)
            {
                if (isHeaderField(lenField, pSessionDD))
                {
                    location = &m_header;
                }
                else if (isTrailerField(lenField, pSessionDD))
                {
                    location = &m_trailer;
                }
                else
                {
                    location = this;
                }
            }

            try
            {
                const FieldBase &fieldLength = location->reverse_find(lenField);
                soh = valueStart + IntConvertor::convert(fieldLength.getString());
            }
            catch (FieldNotFound &)
            {
                throw InvalidMessage(
                    std::string("Data length field ") + IntConvertor::convert(lenField) + std::string(" was not found for data field ") + IntConvertor::convert(field));
            }
            catch (FieldConvertError &e)
            {
                throw InvalidMessage(
                    std::string("Unable to determine SOH for data field ") + IntConvertor::convert(field) + std::string(": ") + e.what());
            }
        }

        std::string::const_iterator const tagEnd = soh + 1;
#if defined(__SUNPRO_CC)
        std::distance(string.begin(), tagEnd, pos);
#else
        pos = std::distance(string.begin(), tagEnd);
#endif

        return {field, valueStart, soh, tagStart, tagEnd};
    }

} // namespace FIX
