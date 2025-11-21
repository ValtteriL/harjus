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

#include "PUGIXML_DOMDocument.h"
#include <sstream>

namespace FIX
{
  auto PUGIXML_DOMAttributes::get( const std::string& name, std::string& value ) -> bool
  {
    pugi::xml_attribute result = m_pNode.attribute(name.c_str());
    if( !result ) return false;
    value = result.value();
    return true;
  }

  auto PUGIXML_DOMAttributes::toMap() -> DOMAttributes::map
  {
    return {};
  }

  auto PUGIXML_DOMNode::getFirstChildNode() -> DOMNodePtr
  {
    pugi::xml_node pNode = m_pNode.first_child();
    if( !pNode ) return {};
    return DOMNodePtr(new PUGIXML_DOMNode(pNode));
  }

  auto PUGIXML_DOMNode::getNextSiblingNode() -> DOMNodePtr
  {
    pugi::xml_node pNode = m_pNode.next_sibling();
    if( !pNode ) return {};
    return DOMNodePtr(new PUGIXML_DOMNode(pNode));
  }

  auto PUGIXML_DOMNode::getAttributes() -> DOMAttributesPtr
  {
    return DOMAttributesPtr(new PUGIXML_DOMAttributes(m_pNode));
  }

  auto PUGIXML_DOMNode::getName() -> std::string
  {
    return m_pNode.name();
  }

  auto PUGIXML_DOMNode::getText() -> std::string
  {
    return m_pNode.value();
  }

  PUGIXML_DOMDocument::PUGIXML_DOMDocument() EXCEPT ( ConfigError )
  = default;

  PUGIXML_DOMDocument::~PUGIXML_DOMDocument()
  {
    //xmlFreeDoc(m_pDoc);
  }

  auto PUGIXML_DOMDocument::load( std::istream& stream ) -> bool
  {
    try
    {
      return m_pDoc.load(stream);
    }
    catch( ... ) { return false; }
  }

  auto PUGIXML_DOMDocument::load( const std::string& url ) -> bool
  {
    try
    {
      return m_pDoc.load_file(url.c_str());
    }
    catch( ... ) { return false; }
  }

  auto PUGIXML_DOMDocument::xml( std::ostream& out ) -> bool
  {
    return false;
  }

  auto PUGIXML_DOMDocument::getNode( const std::string& XPath ) -> DOMNodePtr
  {
    pugi::xpath_node result = m_pDoc.select_node(XPath.c_str());
    if( !result ) return {};

    return DOMNodePtr(new PUGIXML_DOMNode(result.node()));
  }
}
