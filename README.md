# Kong plugin: XML Request Handling
This Kong plugin is developed in Python and uses the Python library [lxml.etree](https://pypi.org/project/lxml/)  binding for the GNOME C libraries [libxml2](https://gitlab.gnome.org/GNOME/libxml2#libxml2) and [libxslt](https://gitlab.gnome.org/GNOME/libxslt#libxslt).

The plugin handles the XML Request (in the HTTP body) in this order:
1) Transform the XML with XSLT (XSLTransformation)
2) Replace the values of XPath entries
3) Validate XML against its XSD schema

Each handling is optional.

In case of misconfiguration the Plugin sends to the consumer an HTTP 500 Internal Server Error ```<soap:Fault>``` (with the error detailed message)

## How deploy XML Request Handling plugin
1) Build a new Docker 'Kong Gateway' image with Python dependencies and the plugin code

```
docker build -t kong-gateway-xml-request-handling .
```

2) Create and prepare a PostgreDB called ```kong-database-xml-request-handling```.
[See documentation](https://docs.konghq.com/gateway/latest/install/docker/#prepare-the-database).

3) Start the Kong Gateway
```
./start-kong.sh
```

## How test XML Request Handling plugin with ```calcWebService/Calc.asmx```
### Create a Kong Service and route
1) Create a Kong Service named ```calcWebService``` with this URL: https://ecs.syr.edu/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx.
This simple backend Web Service adds 2 numbers.

2) Create a Route on the Service ```calcWebService``` with the ```path``` value ```/calcWebService```

3) Install the ```xml-hanlding``` plugin on the Service ```calcWebService``` and use the default parameters. The ```XsdSoapSchema``` property checks the entire SOAP XML content against its schema. The default value is defined by W3C, it can be found here: https://schemas.xmlsoap.org/soap/envelope/

4) Call the ```calcWebService``` through the Kong Gateway Route by using [httpie](https://httpie.io/) tool
```
http POST http://localhost:8000/calcWebService \
Content-Type:"text/xml; charset=utf-8" \
SOAPAction: "http://tempuri.org/Add" \
--raw "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
  <soap:Body>
    <Add xmlns=\"http://tempuri.org/\">
      <a>5</a>
      <b>7</b>
    </Add>
  </soap:Body>
</soap:Envelope>"
```

The expected result is ```12```:
```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>12</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
### Example #1: adding a Tag in XML request of ```calcWebService```  by using XSLT 
The plugin applies a XSLT Transformation on XML request.
In this example the XSLT **adds the value ```<b>8</b>```** that will be not present in the request.
Configure the plugin with:
- ```XsltTransform``` property with this XSLT definition:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>   
    <xsl:template match="//*[local-name()='a']">
       <xsl:copy-of select="."/>
       <b>8</b>
   </xsl:template>
</xsl:stylesheet>
```
Use request defined at step #4, remove ```<b>7</b>```, the expected result is no longer ```12``` but ```13```:
```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```
### Example #2: renaming a Tag in XML request of ```calcWebService``` by using XSLT
The plugin applies a XSLT Transformation on XML request.
In this example we **change the Tag name from ```<Subtract>...</Subtract>```** (present in the request) **to ```<Add>...</Add>```**.

Configure the plugin with:
- ```XsltTransform``` property with no value

**Without XSLT**: Use request defined at step #4, rename the Tag ```<Add>...</Add>```, to ```<Subtract>...</Subtract>``` the expected result is ```-2```
```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <SubtractResponse xmlns="http://tempuri.org/">
      <SubtractResult>-2</SubtractResult>
    </SubtractResponse>
  </soap:Body>
</soap:Envelope>
```

Configure the plugin with:
- ```XsltTransform``` property with this XSLT definition:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
    <xsl:template match="//*[local-name()='Subtract']">
       <Add xmlns="http://tempuri.org/"><xsl:apply-templates select="@*|node()" /></Add>
   </xsl:template>
</xsl:stylesheet>
```
**With XSLT**: Use request defined at step #4, rename the Tag ```<Add>...</Add>```, to ```<Subtract>...</Subtract>``` the expected result is ```12```:
```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>13</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```

### Example #3: replacing the values of XPath entries in ```calcWebService``` XML request
The plugin searches the 1st XPath entry and replaces the value with new one. In case of we want to change all XPath entries, just enable the ```XPathReplaceAll``` checkbox of the plugin property.

In this example we replace the value of:
- ```<a>```: former: ```5``` to new: ```10```
- ```<b>```: former: ```7``` to new: ```9```

Configure the plugin with:
- ```XsltTransform``` property with no value
- ```XPathReplace``` property with the value 
```.//{http://tempuri.org/}a, .//{http://tempuri.org/}b```
- ```XPathReplaceValue``` property with the value 
```10,9```

Use request defined at step #4, the expected result is no longer ```12``` but ```19```:
```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>19</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```

### Example #4: calling incorrectly ```calcWebService``` and detecting issue with XSD schema
We call incorrectly the Service by injecting a SOAP error; the plugin detects it, sends an error message to the Consumer and Kong doesn't call the SOAP backend API.

Configure the plugin with:
- ```XsltTransform``` property with no value
- ```XPathReplace``` property with no value
- ```XPathReplaceValue``` property with no value
- ```XsdSoapSchema``` property with the default value (defined by W3C) which checks the entire SOAP XML content against its schema 

Use request defined at step #4, **change ```</soap:Envelope>``` by ```</soap:EnvelopeKong>```** => Kong says: 
```xml
<faultstring>XSD validation failed: line 10: b'Opening and ending tag mismatch: Envelope line 2 and EnvelopeKong' (line 10)</faultstring>
```

Configure the plugin with:
- ```XsdApiSchema``` property with this value:
```xml
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="a" minOccurs="1"/>
      <xs:element type="xs:integer" name="b" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```
Use request defined at step #4, **remove ```<a>5</a>```** => there is an error because the ```<a>``` tag has the ```minOccurs="1"``` XSD property and Kong says: 
```xml
<faultstring>XSD validation failed: Element '{http://tempuri.org/}b': This element is not expected. Expected is ( {http://tempuri.org/}a ). (<string>, line 0)</faultstring>
```
Use request defined at step #4, **replace ```<b>7</b>``` by ```<b>ABCD</b>```** => there is an error because the ```<b>``` tag has the ```type="xs:integer"``` XSD property and Kong says: 
 ```xml
 <faultstring>XSD validation failed: "Element '{http://tempuri.org/}b': 'ABCD' is not a valid value of the atomic type 'xs:integer'. (<string>, line 0)<faultstring>
```

### Example #5: chaining all plugin capabilities on ```calcWebService``` call
Configure the plugin with:

- ```XsltTransform``` property with no value
- ```XPathReplace``` property with no value
- ```XPathReplaceValue``` property with no value
- ```XsdApiSchema``` property with the value defined at example #4
- ```XsdSoapSchema``` property with the default value

1) XSD schema Validation

Use request defined at step #4, **remove ```<b>7</b>```** => there is an error because ```<b>``` is not present

2) XSLTransformation + XSD schema Validation

Configure the plugin with:
- ```XsltTransform``` property with this XSLT definition which **adds the value ```<b>ABCD</b>```** that will be not present in the request but injected with a String value (instead of Integer)
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output omit-xml-declaration="yes" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>   
    <xsl:template match="//*[local-name()='a']">
       <xsl:copy-of select="."/>
       <b>ABCD</b>
   </xsl:template>
</xsl:stylesheet>
```
Use request defined at step #4, **remove ```<b>7</b>```** => there is an error because ```<b>``` is present but with a String value instead of Integer

3) XSLTransformation + XPath replacement + XSD schema Validation
- ```XPathReplace``` property with the value ```.//{http://tempuri.org/}b```
- ```XPathReplaceValue``` property with the value 
```7```

Use request defined at step #4, **remove ```<b>7</b>```** => there is no more error because: 
- XSLTransformation adds the ```<b>ABCD</b>```
- Plugin replaces the value of ```<b>``` XPath entry: ```ABCD``` replaced by ```7```
- The SOAP request is validated successfully against its XSD schema

So, the backend Web Service is successfully called and the result is ```12```