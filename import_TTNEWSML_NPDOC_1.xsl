<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"	
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	 exclude-result-prefixes="#default xhtml xsl">
	
	<!-- För att konvertera TTNEWSML till npExchange för att skapa jobb+artikel i Newspilot.
	
	2015-09-01 JL lade till hantering av tags och geotaggar.
	2015-10-05 JL justeringar för att fungera själv.
	2015-11-02 JL förklarade currentDateTime
	       Komplettering för att klara contentMetaExtPropertys båda varianter. JL 2015-11-04
	2016-05-26 JL Lade till sortkey för bilder
	-->



	<xsl:variable name="npdoc_ns">http://www.infomaker.se/npdoc/2.1</xsl:variable> <!-- NP vill ha namespace på alla element. -->
	<xsl:variable name="npex_ns">http://www.infomaker.se/npexchange/3.5</xsl:variable> <!-- NP vill ha namespace på alla element. -->
	
	<xsl:strip-space elements="*"/>
	
	<xsl:output encoding="UTF-8" indent="yes" method="xml" media-type="text/xml" omit-xml-declaration="no" version="1.0"/>

       <!-- Grund-template -->
	<xsl:template match="/">
		
		<!-- Välj en av de två nedanstående raderna. Den första kör med datum och tid från inkommande xml, vilket kan vara gammalt. Den andra sätter en variabel som exempelvis delphi-programmet ersätter med korrekt värde. -->
		<xsl:variable name="currentDateTime"><xsl:value-of select="newsMessage/header/sent"/></xsl:variable>  <!-- XSLT 1.0 kan inte ta fram datum och tid så här plockar vi den från xml-filen, vilket kan vara ett gammalt datum  -->
		<!--<xsl:variable name="currentDateTime"><xsl:value-of  select="'[#currentDateTime]'"/></xsl:variable>-->  <!-- XSLT 1.0 kan inte ta fram datum och tid så den här variabeln måste fixas sedan av processen och sätta rätt värde.  -->
		
		<xsl:variable name="mainuri" select="newsMessage/itemSet/packageItem/groupSet/group[@role = 'group:main']/itemRef/@residref"/> <!-- Börja med att hämta den id-referens som pekar ut main newsitem i paketet. NewsML-filen har en package item även om det bara är en ensam text. -->
		
		<xsl:variable name="mainslugg" select="substring-before(substring-after(substring-after($mainuri,'/'),'-'),'-')"/>
		<xsl:variable name="renuri" select="substring-after($mainuri,'text/')"/>
		
		
		<xsl:variable name="produktkoder"> <!-- Ta in produkt-kod(erna) för användning i uppsättning av tkod och sektion -->
			<xsl:text>:</xsl:text>
			<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/subject[@type = 'tt:product']">
				<xsl:value-of select="concat(./@literal,':')"/>
			</xsl:for-each>
		</xsl:variable>
		
		
		
		<xsl:variable name="geodata">
			<xsl:if test="newsMessage/itemSet/newsItem[@guid = $mainuri]/assert[geoAreaDetails]">
				<kml xmlns="http://www.opengis.net/kml/2.2"
					xmlns:ns2="http://www.w3.org/2005/Atom"
					xmlns:ns3="urn:oasis:names:tc:ciq:xsdschema:xAL:2.0">
					<Document>
						<ExtendedData>
							<Data name="np_version">
								<value>1.1</value>
							</Data>
						</ExtendedData>
						<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/assert[geoAreaDetails]">
				<xsl:variable name="geonamn" select="./name"/>
				<xsl:variable name="latitud" select="./geoAreaDetails/position/@latitude"/>
				<xsl:variable name="longitud" select="./geoAreaDetails/position/@longitude"/>
				<Placemark>
					<name><xsl:value-of select="$geonamn"/></name>
					<address><xsl:value-of select="$geonamn"/></address>
					<description/>
					<Point>
						<coordinates><xsl:value-of select="$longitud"/>,<xsl:value-of select="$latitud"/></coordinates>
					</Point>
				</Placemark>
				
			</xsl:for-each>
					</Document>
				</kml>
			</xsl:if>
		</xsl:variable>
		
		<xsl:variable name="sektion">
			<xsl:choose>
				<xsl:when test="contains($produktkoder,':FT')">Feature</xsl:when>
				<xsl:when test="contains($produktkoder,':TTINR:')">Inrikes</xsl:when>
				<xsl:when test="contains($produktkoder,':TTUTR:')">Utrikes</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSPT:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSPTPL:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSTJ:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSPR:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':REDINFSPT:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTTBL:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTTTL:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTEKO:')">Ekonomi</xsl:when>
				<xsl:when test="contains($produktkoder,':TTKUL')">Nöje och Kultur</xsl:when>
				<xsl:when test="contains($produktkoder,':TTNOJ')">Nöje och Kultur</xsl:when>
				<xsl:when test="contains($produktkoder,':TTREC')">Nöje och Kultur</xsl:when>
				<xsl:when test="contains($produktkoder,':TTNOJKULN')">Nöje och Kultur</xsl:when>
				<xsl:otherwise>Inrikes</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="department">
			<xsl:choose>
				<xsl:when test="contains($produktkoder,':FT')">Feature</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSPT:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSPTPL:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSTJ:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTSPR:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':REDINFSPT:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTTBL:')">Sport</xsl:when>
				<xsl:when test="contains($produktkoder,':TTTTL:')">Sport</xsl:when>
				<xsl:otherwise>Nyheter</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="headline"><xsl:value-of select="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/headline)"/></xsl:variable> <!-- Rubriken på nyhetsobjektet används som namn i NP. -->
		
		<xsl:variable name="webbprio">
			<xsl:choose>
				<xsl:when test="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/contentMetaExtProperty[@type = 'ttext:webprio']) != ''"><xsl:value-of select="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/contentMetaExtProperty[@type = 'ttext:webprio'])"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/contentMetaExtProperty[@type = 'ttext:webprio']/@literal)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable> <!-- Om nyheten ingår i webbtjänsten har den en speciell webb-prio -->
		
		<xsl:variable name="webbstatus">
			<xsl:choose>
				<xsl:when test="$webbprio = '1'">Topp</xsl:when>
				<xsl:when test="$webbprio = '2'">Huvud</xsl:when>
				<xsl:when test="$webbprio = '3'">Vanlig</xsl:when>
				<xsl:otherwise>Ingen</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="slug"><xsl:value-of select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/slugline"/></xsl:variable>  <!-- TT:s slugg -->
		<xsl:variable name="renslugg"><xsl:call-template name="tvattaAAO"><xsl:with-param name="intext" select="$slug"/></xsl:call-template></xsl:variable>
		
		<xsl:variable name="prio"><xsl:value-of select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/urgency"/></xsl:variable> <!-- Prio på själva nyheten -->
		
		<xsl:variable name="typnamn">
			<xsl:choose>
				<xsl:when test="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/contentMetaExtProperty[@type = 'ttext:profile']) != ''"><xsl:value-of select="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/contentMetaExtProperty[@type = 'ttext:profile'])"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space(newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/contentMetaExtProperty[@type = 'ttext:profile']/@literal)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable> <!-- Ta in vilken status det är. Kan vara PUBL, DATA eller INFO -->
		<xsl:variable name="typid">
			<xsl:choose>
				<xsl:when test="$typnamn = 'INFO'">3</xsl:when>
				<xsl:when test="$typnamn = 'DATA'">2</xsl:when>
				<xsl:otherwise><xsl:value-of select="'1'"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="vecka" select="'0'"/>
		<xsl:variable name="kundareaid" select="'1111'"/>
		<xsl:variable name="kundarea" select="'-FEATUREAREOR-'"/>
		<xsl:variable name="notering"><xsl:value-of select="newsMessage/itemSet/newsItem[@guid = $mainuri]/itemMeta/edNote"/></xsl:variable>  <!-- Info från TT till kunderna -->
		

             <!-- Här börjar vi bygga output -->
		<npexchange xmlns="http://www.infomaker.se/npexchange/3.5" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.5">
			<origin>
				<user>TT System</user>  <!--   usernamn=TT System -->
				<organization>TT Redaktion</organization>  <!--  orgnamn= TT Redaktion -->
				<systemId>TT</systemId>
				<systemVersion>4.7.1.8</systemVersion>
				<systemRelease>rel</systemRelease>
			</origin>
			
			<article refType="Article">
				<department_id><xsl:value-of select="$department"/></department_id>  <!--   department=Nyheter, Sport, Planerat, Dagen, Feature -->
				<description><xsl:value-of select="$notering"/></description>
				<xsl:if test="$geodata != ''">
					<geodata>
				<xsl:copy-of select="$geodata"/>
					</geodata>
				</xsl:if>
				<name><xsl:value-of select="$headline"/></name>      <!-- Namn jobb och artikel ska få i NP -->
				<organization_id>TT Redaktion</organization_id> <!--  orgnamn=TT Redaktion -->
				<prio><xsl:value-of select="$prio"/></prio>    <!-- prio= 3,4.   1 är FLASH!! -->
				<product_id>TT Redaktion</product_id>  <!--  prodnamn=TT Redaktion -->
				<publication_date_id><xsl:value-of select="$currentDateTime"/></publication_date_id>  <!-- pubdate=2010-11-13 -->
				<section_id><xsl:value-of select="$sektion"/></section_id>  <!--  secname=Inrikes, Utrikes, Ekonomi, Sport, Feature, Nöje och kultur -->
				<slug><xsl:value-of select="$slug"/></slug>
				<status>Under produktion</status> <!--  status=Under produktion, Oläst -->
					<tags>
						<tags>
							<!-- Vi måste samla in TAGS -->
							<!-- Vi måste samla in geokoder -->
							
								<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/subject[@type = 'cpnat:person']">
									<xsl:variable name="namnet" select="./name"/>
									<tag category="PERSON" name="{$namnet}" type="entity"/>
								</xsl:for-each>
							
								<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/subject[@type = 'cpnat:organisation']">
									<xsl:variable name="namnet" select="./name"/>
									<tag category="ORGANIZATION" name="{$namnet}" type="entity"/>
								</xsl:for-each>
							
								<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/subject[@type = 'cpnat:abstract']">
									<xsl:variable name="namnet" select="./name"/>
									<tag category="TOPIC" name="{$namnet}" type="topic"/>
								</xsl:for-each>
							
								<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/subject[@type = 'cpnat:place']">
									<xsl:variable name="namnet" select="./name"/>
									<tag category="LOCATION" name="{$namnet}" type="entity"/>
								</xsl:for-each>
							
								<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentMeta/subject[@type = 'cpnat:object']">
									<xsl:variable name="namnet" select="./name"/>
									<tag category="UNKNOWN" name="{$namnet}" type="entity"/>
								</xsl:for-each>
							
						</tags>
					</tags>
				<userdata>
					<userdata>
						<webbprio valueId="{$webbprio}"><xsl:value-of select="$webbstatus"/></webbprio>  <!-- webbprio = 0,2,3  webbstatus = Ingen, Vanlig, Huvud -->
						<texttyp valueId="{$typid}"><xsl:value-of select="$typnamn"/></texttyp>  <!-- typid=1,2,3 typnamn = PUBL, INFO, DATA -->
						<prio valueId="{$prio}"><xsl:value-of select="$prio"/></prio>
						<week valueId="{$vecka}"><xsl:value-of select="$vecka"/></week>  <!-- Veckonummer för feature. 0 om det inte är feature. -->
						<kundarea valueId="{$kundareaid}"><xsl:value-of select="$kundarea"/></kundarea>  <!-- Kundarea för feature. 1111 och -FEATUREAREOR- om inget -->
					</userdata>
				</userdata>
				
				<articleparts>
					<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentSet/inlineXML/html/body/article/section">
						<xsl:variable name="delnr" select="position()"/>
						<xsl:variable name="artikeldelstyp">
							<xsl:choose>
								<xsl:when test="@class = 'quotes'">Citat</xsl:when>
								<xsl:when test="@class = 'facts'">Fakta</xsl:when>
								<xsl:otherwise>Artikel</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<articlepart refType="ArticlePart">
							<article_part_type_id><xsl:value-of select="$artikeldelstyp"/></article_part_type_id>
							<sortkey><xsl:value-of select="position() * 0.25"/></sortkey>
							<data>
								<npdoc xmlns="http://www.infomaker.se/npdoc/2.1" version="2.1" xml:lang="sv">
                                                        <xsl:if test="h1">
                                                        	<xsl:element name="headline" namespace="{$npdoc_ns}"><xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(h1)"/></xsl:element></xsl:element>
                                                        </xsl:if>
								<xsl:if test="$artikeldelstyp = 'Artikel'">
									<xsl:element name="pagedateline" namespace="{$npdoc_ns}"><xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(div[@class = 'dat']/span[@class = 'vignette'])"/></xsl:element></xsl:element>
									<xsl:element name="dateline" namespace="{$npdoc_ns}"><xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(div[@class = 'dat']/span[@class = 'source'])"/></xsl:element></xsl:element>
								</xsl:if>
									<xsl:apply-templates select="h4"/>   <!-- h4 är ingressen -->
									<xsl:element name="body" namespace="{$npdoc_ns}">
										<xsl:apply-templates select="div[@class = 'bodytext']"/>
									</xsl:element>
									
								</npdoc>
							
							</data>
							<xsl:if test="div[@class = 'byline']">
								<bylines>
									<xsl:for-each select="div[@class = 'byline']">
										<xsl:variable name="fornamn">
											<xsl:value-of select="substring-before(.,' ')"/>
										</xsl:variable>
										<xsl:variable name="efternamn">
											<xsl:choose>
												<xsl:when test="contains(.,'/')"><xsl:value-of select="substring-after(substring-before(.,'/'),' ')"/></xsl:when>
												<xsl:otherwise><xsl:value-of select="substring-after(.,' ')"/></xsl:otherwise>
											</xsl:choose>
										</xsl:variable>
										<byline refType="Byline">
											<byline_type_id>Byline</byline_type_id>   
											<userinfo>
												<userdata>
													<titleinfo></titleinfo>
													<lastname><xsl:value-of select="$efternamn"/></lastname>
													<firstname><xsl:value-of select="$fornamn"/></firstname>
												</userdata>
											</userinfo>
										</byline>
									</xsl:for-each>
								</bylines>
							</xsl:if>
							<xsl:if test="./figure">
								<imagecontainers>
									<xsl:for-each select="./figure">
										<xsl:variable name="plats" select="position()"/>
										<xsl:variable name="bildref"><xsl:value-of select="img/@data-assoc-ref"/></xsl:variable>
										<imagecontainer refType="ImageContainer">
											<name><xsl:value-of select="concat('Bild ',$plats)"/></name>
											<sortkey>
												<xsl:value-of select="position() * 0.25"/>
											</sortkey>
											<data> 
												<npdoc xmlns="http://www.infomaker.se/npdoc/2.1" version="2.1" xml:lang="sv">
													<caption>
														<p><xsl:value-of select="./figcaption"/></p>
													</caption>
												</npdoc>
											</data>
											<xsl:if test="./div[@class = 'byline']">
												<xsl:variable name="fornamn">
													<xsl:value-of select="substring-before(./div[@class = 'byline'],' ')"/>
												</xsl:variable>
												<xsl:variable name="efternamn">
													<xsl:choose>
														<xsl:when test="contains(./div[@class = 'byline'],'/')"><xsl:value-of select="substring-after(substring-before(./div[@class = 'byline'],'/'),' ')"/></xsl:when>
														<xsl:otherwise><xsl:value-of select="substring-after(./div[@class = 'byline'],' ')"/></xsl:otherwise>
													</xsl:choose>
												</xsl:variable>
												<byline refType="Byline">
													<byline_type_id>Byline</byline_type_id>   
													<userinfo>
														<userdata>
															<titleinfo></titleinfo>
															<lastname><xsl:value-of select="$efternamn"/></lastname>
															<firstname><xsl:value-of select="$fornamn"/></firstname>
														</userdata>
													</userinfo>
												</byline>
												
											</xsl:if>
											<xsl:variable name="bildnr" select="$bildref"/> <!-- Från 3/10 ska bildnumret som finns här vara med intakt i bildnamnet -->
											<xsl:variable name="bildnamnet" select="concat($renuri,'-',$bildnr,'nh.jpg')"/> <!-- Sätt ihop en referens till vad bildfilen heter -->
											<image refType="Image">
												<name><xsl:value-of select="$bildnamnet"/></name>
												<data src="{$bildnamnet}"/>
											</image>
										</imagecontainer>
									</xsl:for-each>
									
								</imagecontainers>
							</xsl:if>
							
						</articlepart>
					</xsl:for-each>
					
					<xsl:for-each select="newsMessage/itemSet/newsItem[@guid = $mainuri]/contentSet/inlineXML/html/body/article/aside">
						<xsl:variable name="delnr" select="position() + 2"/>
						<xsl:variable name="artikeldelstyp">
							<xsl:choose>
								<xsl:when test="@class = 'quotes'">Citat</xsl:when>
								<xsl:when test="@class = 'facts'">Fakta</xsl:when>
								<xsl:otherwise>Artikel</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<articlepart refType="ArticlePart">
							<article_part_type_id><xsl:value-of select="$artikeldelstyp"/></article_part_type_id>
							<sortkey><xsl:value-of select="$delnr * 0.25"/></sortkey>
							<data>
								<npdoc xmlns="http://www.infomaker.se/npdoc/2.1" version="2.1" xml:lang="sv">
									<xsl:if test="h1">
										<xsl:element name="headline" namespace="{$npdoc_ns}"><xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(h1)"/></xsl:element></xsl:element>
									</xsl:if>
									<xsl:if test="$artikeldelstyp = 'Artikel'">
										<xsl:element name="pagedateline" namespace="{$npdoc_ns}"><xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(div[@class = 'dat']/span[@class = 'vignette'])"/></xsl:element></xsl:element>
										<xsl:element name="dateline" namespace="{$npdoc_ns}"><xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(div[@class = 'dat']/span[@class = 'source'])"/></xsl:element></xsl:element>
									</xsl:if>
									<xsl:apply-templates select="h4"/>   <!-- h4 är ingressen -->
									<xsl:element name="body" namespace="{$npdoc_ns}">
										<xsl:apply-templates select="div[@class = 'bodytext']"/>
									</xsl:element>
									
								</npdoc>
							</data>
							<xsl:if test="./div[@class = 'byline']">
								<xsl:variable name="fornamn">
									<xsl:value-of select="substring-before(./div[@class = 'byline'],' ')"/>
								</xsl:variable>
								<xsl:variable name="efternamn">
									<xsl:choose>
										<xsl:when test="contains(./div[@class = 'byline'],'/')"><xsl:value-of select="substring-after(substring-before(./div[@class = 'byline'],'/'),' ')"/></xsl:when>
										<xsl:otherwise><xsl:value-of select="substring-after(./div[@class = 'byline'],' ')"/></xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<byline refType="Byline">
									<byline_type_id>Byline</byline_type_id>   
									<userinfo>
										<userdata>
											<titleinfo></titleinfo>
											<lastname><xsl:value-of select="$efternamn"/></lastname>
											<firstname><xsl:value-of select="$fornamn"/></firstname>
										</userdata>
									</userinfo>
								</byline>
								
							</xsl:if>
							
							
						</articlepart>
					</xsl:for-each>
				</articleparts>
			</article>
		</npexchange>
	</xsl:template>
	
	
	
	<!-- Separata templates för de olika delarna i HTML5 -->
	
	<xsl:template match="h4">
		<xsl:element name="leadin" namespace="{$npdoc_ns}"><xsl:apply-templates mode="ingress"/></xsl:element>  <!-- Skapa ingressstart som är leadin och bearbeta allt däri -->
	</xsl:template>
	
	<xsl:template match="p" mode="ingress">
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	<xsl:template match="blockquote" mode="ingress">
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:text>&#x2013; </xsl:text><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	
	<xsl:template match="div[@class = 'bodytext']"><xsl:apply-templates/></xsl:template>
	
	<xsl:template match="p">
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	<xsl:template match="h5">
		<xsl:element name="subheadline4" namespace="{$npdoc_ns}"><xsl:attribute name="customname"><xsl:text>Fråga</xsl:text></xsl:attribute><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	<xsl:template match="blockquote">
		<xsl:element name="subheadline2" namespace="{$npdoc_ns}"><xsl:attribute name="customname"><xsl:text>Citat</xsl:text></xsl:attribute><xsl:text>&#x2013; </xsl:text><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	<xsl:template match="div[@class = 'byline']">
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	<xsl:template match="h2">
		<xsl:element name="subheadline1" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(.)"/></xsl:element>
	</xsl:template>
	
	<xsl:template match="figure">
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(figcaption)"/></xsl:element>
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:value-of select="normalize-space(div[@class = 'byline'])"/></xsl:element>
		<xsl:element name="p" namespace="{$npdoc_ns}"><xsl:element name="a" namespace="{$npdoc_ns}"><xsl:attribute name="href"><xsl:value-of select="normalize-space(img/@src)"/></xsl:attribute><xsl:value-of select="normalize-space(img/@src)"/></xsl:element></xsl:element>
	</xsl:template>
	
	<xsl:template match="table">
		
		<xsl:for-each select="tr"><xsl:element name="subheadline4" namespace="{$npdoc_ns}"><xsl:attribute name="customName">Tabell</xsl:attribute></xsl:element><xsl:for-each select="td"><xsl:if test=". != ''"><xsl:text>&#9;</xsl:text><xsl:value-of select="."/></xsl:if></xsl:for-each></xsl:for-each>
		
	</xsl:template>
	
	<xsl:template match="ul">
		<xsl:for-each select="li"><xsl:element name="subheadline5" namespace="{$npdoc_ns}"><xsl:attribute name="customName">Lista</xsl:attribute><xsl:value-of select="."/></xsl:element></xsl:for-each>
	</xsl:template>
	
	<xsl:template match="footer[@class = 'broadcastinfo']"><xsl:element name="pagedatline" namespace="{$npdoc_ns}"><xsl:attribute name="customName">Kanal Dag Tid</xsl:attribute></xsl:element><xsl:apply-templates/></xsl:template>


	<xsl:template name="tvattaAAO">
		<xsl:param name="intext"/>
		
		<xsl:variable name="uttext" select=" translate($intext,'åäöÅÄÖéÉüÜèÈáàÀÁ','aaoAAOeEuUeEaaAA')"/>
		
		<xsl:value-of select="$uttext"/>
		
	</xsl:template>
	

</xsl:stylesheet>
