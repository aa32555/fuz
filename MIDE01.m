MIDE01 ; version code name ZUBAIR
	;
	;#################################################################
	;#                                                               #
	;# Copyright (c) 2024 ahmedatefuzy@gmail                         #
	;# All rights reserved.                                          #
	;#                                                               #
	;#   This source code contains the intellectual property         #
	;#   of its copyright holder(s), and is made available           #
	;#   under a license.  If you do not know the terms of           #
	;#   the license, please stop and do not read further.           #
	;#                                                               #
	;#################################################################		
	Q
	;
	; # to run the zubair 
	;
	; * export ydb_routines=`ydb -run %XCMD 'W $P($P($ZRO,"(",1,2),")")_" "_"/root/mide01/src"_")"_$P($ZRO,")",2,$L($ZRO,")"))'` 
	; * ydb -run Start^MIDE01
	;
ROUTES
	N IDEVERSION
	S IDEVERSION="MIDE01"
	S ZUBAIR(":WS","ROUTES","POST","zubairapi","API^"_IDEVERSION)=""
	S ZUBAIR(":WS","ROUTES","OPTIONS","zubairapi","API^"_IDEVERSION)=""
	S ZUBAIR(":WS","ROUTES","GET","Zubair","SERVESTATIC^"_IDEVERSION)=""
	;
	Q	
	;
Start(PORT) ;
	K (PORT)
	I '$G(PORT) S PORT=6969
	S NOGLB=1
	I 1 J JOB(PORT) H 1 I '$T W !,"Zubair Web Server could not be started!" Q
	S JOB=$ZJOB
	I '$$DirectoryExists("~/tmp") D
	. W !,"Creating /tmp ..."
	. W:$$CreateDirectoryTree("~/tmp") " succeeded" 
	ZSY "echo ""PID:"_JOB_",Port:"_PORT_""" > ~/tmp/zubair.info"
	W !,"Zubair Web Server started, brother "_$J_". Port: ",PORT," - PID: ",JOB,!
	Q
Stop;
	K
	W ! N SRC,LINE
	S SRC="~/tmp/zubair.info"
	O SRC:(readonly)
	U SRC R LINE C SRC S LINE=$TR(LINE,$C(13))
	N PORT,PID
	S PID=$P($P(LINE,","),":",2)
	S PORT=$P($P(LINE,",",2),":",2)
	I 'PID W !!,"Zubair Web Server could not be stopped!" Q
	ZSY "kill "_PID
	W !,"Killed PID: "_PID_". Zubair Web Server stopped in a very Indian Way.",!
	Q
	;
Check
	K
	W ! N SRC,LINE
	S SRC="~/tmp/zubair.info"
	O SRC:(readonly)
	U SRC R LINE C SRC S LINE=$TR(LINE,$C(13))
	N PORT
	S PORT=$P($P(LINE,",",2),":",2)
	ZSY "netstat -ano -p tcp | grep "_PORT
	Q 
	;       
RUN(HTTPREQ,HTTPRSP,HTTPARGS)
	S HTTPRSP("mime")="text/html"
	W ! N SRC,LINE
	S SRC="~/tmp/zubair.info"
	O SRC:(readonly)
	U SRC R LINE C SRC S LINE=$TR(LINE,$C(13))
	N PORT,PID
	S PID=$P($P(LINE,","),":",2)
	S PORT=$P($P(LINE,",",2),":",2)
	S @HTTPRSP@(1)="Zubair web server running binshodily"
	S @HTTPRSP@(1)=@HTTPRSP@(1)_" PID: "_PID_" and "_"Port: "_PORT
	Q       
	;
JOB(TCPPORT)
	S @("$ZINTERRUPT=""I $$JOBEXAM^MIDE01($ZPOSITION)""")
	S TCPIO="SCK$"_TCPPORT
	O TCPIO:(LISTEN=TCPPORT_":TCP":delim=$C(13,10):attach="server":chset="M"):15:"socket" 
	E  U 0 W !,"error cannot open port "_TCPPORT Q
	U TCPIO:(CHSET="M")
	W /LISTEN(5)
	N PARSOCK S PARSOCK=$P($KEY,"|",2)
	N CHILDSOCK
LOOP
	D  G LOOP
	. F  W /WAIT Q:$KEY]""
	. I $P($KEY,"|")="CONNECT" D 
	. . S CHILDSOCK=$P($KEY,"|",2)
	. . U TCPIO:(detach=CHILDSOCK)
	. . N Q S Q=""""
	. . N ARG S ARG=Q_"SOCKET:"_CHILDSOCK_Q
	. . N J S J="CHILD($G(TLSCONFIG),$G(NOGBL)):(input="_ARG_":output="_ARG_")"
	. . J @J
	Q
JOBEXAM(%ZPOS)
	QUIT 1
CHILD(TLSCONFIG,NOGBL)
	N %WTCP S %WTCP=$GET(TCPIO,$PRINCIPAL)
	S HTTPLOG=0
	S HTTPLOG("DT")=+$H
	D INCRLOG
	N $ET S $ET="G ETSOCK^MIDE01"
	;
NEXT
	K HTTPREQ,HTTPRSP,HTTPERR
WAIT
	U %WTCP:(delim=$C(13,10):chset="M")
	R TCPX:10 I '$T G ETDC
	I '$L(TCPX) G ETDC
	S HTTPREQ("method")=$P(TCPX," ")
	S HTTPREQ("path")=$P($P(TCPX," ",2),"?")
	S HTTPREQ("query")=$P($P(TCPX," ",2),"?",2,999)
	S HTTPREQ("body")="ZUBAIRBODY" K @HTTPREQ("body")
	I $E($P(TCPX," ",3),1,4)'="HTTP" G NEXT
	F  S TCPX=$$RDCRLF() Q:'$L(TCPX)  D ADDHEAD(TCPX)
	I $G(HTTPREQ("header","expect"))="100-continue" D
	. W "HTTP/1.1 100 Continue",$C(13,10,13,10),!
	U %WTCP:(nodelim)
	I $$LOW($G(HTTPREQ("header","transfer-encoding")))="chunked" D
	. D RDCHNKS
	. I HTTPLOG>2
	I $G(HTTPREQ("header","content-length"))>0 D
	. D RDLEN(HTTPREQ("header","content-length"),99)
	S $ETRAP="G ETCODE^MIDE01"
	S HTTPERR=0
	D RESPOND
	S $ETRAP="G ETSOCK^MIDE01"
	U %WTCP:(nodelim:chset="M")
	I $G(HTTPERR) D RSPERROR
	D SENDATA C %WTCP  HALT
	I $G(HTTPRSP("header","Connection"))="close" C %WTCP
	G NEXT
RDCRLF() ;:PRIVATE:
	N X,LINE,RETRY
	S LINE=""
	F RETRY=1:1 R X:1 S LINE=LINE_X Q:$A($ZB)=13  Q:RETRY>10
	Q LINE
RDCHNKS ;:PRIVATE:
	Q
RDLEN(REMAIN,TIMEOUT) ;:PRIVATE:
	N X,LINE,LENGTH
	S LINE=0
RDLOOP ;:PRIVATE:
	S LENGTH=REMAIN I LENGTH>1600 S LENGTH=1600
	R X#LENGTH:TIMEOUT
	I '$T S LINE=LINE+1,@HTTPREQ("body")@(LINE)=X Q
	S REMAIN=REMAIN-$L(X),LINE=LINE+1,@HTTPREQ("body")@(LINE)=X
	G:REMAIN RDLOOP
	Q
ADDHEAD(LINE) ;:PRIVATE:
	N NAME,VALUE
	S NAME=$$LOW($$LTRIM($P(LINE,":")))
	S VALUE=$$LTRIM($P(LINE,":",2,99))
	I LINE'[":" S NAME="",VALUE=LINE
	I '$L(NAME) S NAME=$G(HTTPREQ("header"))
	I '$L(NAME) Q
	I $D(HTTPREQ("header",NAME)) D
	. S HTTPREQ("header",NAME)=HTTPREQ("header",NAME)_","_VALUE
	E  D
	. S HTTPREQ("header",NAME)=VALUE,HTTPREQ("header")=NAME
	Q
ETSOCK
	D LOGERR
	C %WTCP
	H
ETCODE
	S $ETRAP="G ETBAIL^MIDE01"
	I $TLEVEL TROLLBACK
	D LOGERR,SETERROR(501,"Log ID:"_HTTPLOG("ID")),RSPERROR,SENDATA
	S $ETRAP="Q:$ESTACK&$QUIT 0 Q:$ESTACK  S $ECODE="""" G NEXT"
	Q
ETDC
	C $P
	HALT
ETBAIL
	U %WTCP
	W "HTTP/1.1 500 Internal Server Error-",$C(13,10),$C(13,10),!
	;W "HTTP/1.1 500 Internal Server Error-",$C(13,10)
	;W "X-Server-Error: "_$ZSTATUS_$C(13,10)_$C(13,10),!
	C %WTCP
	HALT
INCRLOG
	N DT,ID
	S DT=+$H
	S ID=$H_"."_$J S HTTPLOG("ID")=ID
	Q
LOGERR
	Q
LTRIM(%X)
	N %L,%R
	S %L=1,%R=$L(%X)
	F %L=1:1:$L(%X) Q:$A($E(%X,%L))>32
	Q $E(%X,%L,%R)
RESPOND
	N ROUTINE,LOCATION,HTTPARGS,HTTPBODY,ADS
	S ROUTINE=""
	D MATCH(.ROUTINE,.HTTPARGS) I $G(HTTPERR) Q
	D QSPLIT(.HTTPARGS) I $G(HTTPERR) QUIT
	S HTTPRSP="ZUBAIRRESP" k @HTTPRSP
	I ROUTINE="" S ROUTINE="RUN"
	D @(ROUTINE_"(.HTTPREQ,.HTTPRSP,.HTTPARGS)")
	Q
QSPLIT(QUERY)
	N I,X,NAME,VALUE
	F I=1:1:$L(HTTPREQ("query"),"&") D
	. S X=$$URLDEC($P(HTTPREQ("query"),"&",I))
	. S NAME=$P(X,"="),VALUE=$P(X,"=",2,999)
	. I $L(NAME) S QUERY($$LOW(NAME))=VALUE
	Q
MATCH(ROUTINE,ARGS)
	N AUTHNODE
	S ROUTINE=""
	D MATCHF(.ROUTINE,.ARGS,.AUTHNODE) Q
	I ROUTINE="" S ROUTINE="RUN"
	Q
MATCHF(ROUTINE,ARGS,AUTHNODE)
	N PATH S PATH=HTTPREQ("path")
	S:$E(PATH)="/" PATH=$E(PATH,2,$L(PATH))
	N DONE S DONE=0
	N PATH1 S PATH1=$$URLDEC($P(PATH,"/",1,9999),1)
	N PATH1 S PATH1=$$URLDEC($P(PATH,"/",1),1)
	N PATTERN S PATTERN=PATH1
	I PATTERN="" S PATTERN="/"
	I PATTERN=""  S PATTERN="Zubair"
	I PATTERN="/" S PATTERN="Zubair"
	I '$D(ZUBAIR(":WS","ROUTES")) D ROUTES
	I $D(ZUBAIR(":WS","ROUTES",HTTPREQ("method"),PATTERN)) D
	. S ROUTINE=$O(ZUBAIR(":WS","ROUTES",HTTPREQ("method"),PATTERN,""))
	Q
SENDATA
	N %WBUFF S %WBUFF=""
	N SIZE,RSPTYPE,PREAMBLE,START,LIMIT
	S RSPTYPE=$S($E($G(HTTPRSP))="%":2,$E($G(HTTPRSP))'="^":1,1:2)
	I RSPTYPE=1 S SIZE=$$VARSIZE(.HTTPRSP)
	I RSPTYPE=2 S SIZE=$$REFSIZE(.HTTPRSP)
	D W($$RSPLINE()_$C(13,10))
	;D W("Date: "_$$GMT_$C(13,10))
	I $D(HTTPREQ("Content-Disposition")) D
	. D W("Content-Disposition: "_HTTPREQ("Content-Disposition")_$C(13,10))
	I $D(HTTPREQ("X-Accel-Redirect")) D
	. D W("X-Accel-Redirect: "_HTTPREQ("X-Accel-Redirect")_$C(13,10))
	I $D(HTTPREQ("set_cookie")) D
	. D W("Set-Cookie: "_HTTPREQ("set_cookie")_$C(13,10))
	I $D(HTTPREQ("location")) D
	. D W("Location: "_HTTPREQ("location")_$C(13,10))
	I $D(HTTPRSP("auth")) D
	. D W("WWW-Authenticate: "_HTTPRSP("auth")_$C(13,10)) K HTTPRSP("auth")
	I $D(HTTPRSP("header")) d
	. n tmp s tmp="" f  s tmp=$o(HTTPRSP("header",tmp)) q:tmp=""  D
	. . d W(tmp_": "_HTTPRSP("header",tmp)_$c(13,10))
	. k HTTPRSP("header")
	I $D(HTTPRSP("mime")) D
	. D W("Content-Type: "_HTTPRSP("mime")_$C(13,10)) K HTTPRSP("mime")
	E  D W("Content-Type: application/json; charset=utf-8"_$C(13,10))
	D W("Content-Length: "_SIZE_$C(13,10)_$C(13,10))
	I 'SIZE D FLUSH Q
	N I,J,IND
	I RSPTYPE=1 D
	. I $D(HTTPRSP)#2 D W(HTTPRSP)
	. I $D(HTTPRSP)>1 S I=0 F  S I=$O(HTTPRSP(I)) Q:'I  D W(HTTPRSP(I))
	I RSPTYPE=2 D
	. I $D(@HTTPRSP)#2 D W(@HTTPRSP)
	. I $D(@HTTPRSP)>1 S I=0 F  S I=$O(@HTTPRSP@(I)) Q:'I  D
	. . S IND=@HTTPRSP@(I)
	. . I $ZE(IND,1,4)="$NA(" D  Q
	. . . S TMP=$P($P(IND,"$NA(",2),")",1,$ZL(IND,")")-1) I '$D(@TMP) Q
	. . . D W(@TMP)
	. . D W(IND) Q
	D FLUSH
	Q
W(DATA)
	I ($ZL(%WBUFF)+$ZL(DATA))>4080 D FLUSH
	S %WBUFF=%WBUFF_DATA
	Q
FLUSH
	W %WBUFF
	S %WBUFF=""
	Q
RSPERROR
	S HTTPRSP("header","X-Server-Error")=$ZSTATUS
	Q
RSPLINE()
	I $D(HTTPRSP("partial")) Q "HTTP/1.1 206 Partial Content"
	I '$G(HTTPERR),'$D(HTTPREQ("location")) Q "HTTP/1.1 200 OK"
	I '$G(HTTPERR),$D(HTTPREQ("location")) Q "HTTP/1.1 201 Created"
	I $G(HTTPERR)=400 Q "HTTP/1.1 400 Bad Request"
	I $G(HTTPERR)=401 Q "HTTP/1.1 401 Unauthorized"
	I $G(HTTPERR)=404 Q "HTTP/1.1 404 Not Found"
	I $G(HTTPERR)=405 Q "HTTP/1.1 405 Method Not Allowed"
	I $G(HTTPERR)=302 Q "HTTP/1.1 302 Moved Temporarily"
	Q "HTTP/1.1 500 Internal Server Error"
SETERROR(ERRCODE,MESSAGE)
	N NEXTERR,ERRNAME,TOPMSG
	S HTTPERR=400,TOPMSG="Bad Request"
	I ERRCODE=101 S ERRNAME="Missing name of index"
	I ERRCODE=102 S ERRNAME="Invalid index name"
	I ERRCODE=103 S ERRNAME="Parameter error"
	I ERRCODE=104 S HTTPERR=404,TOPMSG="Not Found",ERRNAME="Bad key"
	I ERRCODE=105 S ERRNAME="Template required"
	I ERRCODE=106 S ERRNAME="Bad Filter Parameter"
	I ERRCODE=107 S ERRNAME="Unsupported Field Name"
	I ERRCODE=108 S ERRNAME="Bad Order Parameter"
	I ERRCODE=109 S ERRNAME="Operation not supported with this index"
	I ERRCODE=110 S ERRNAME="Order field unknown"
	I ERRCODE=111 S ERRNAME="Unrecognized parameter"
	I ERRCODE=112 S ERRNAME="Filter required"
	I ERRCODE=201 S ERRNAME="Unknown collection"
	I ERRCODE=202 S ERRNAME="Unable to decode JSON"
	I ERRCODE=203 D
	. S HTTPERR=404,TOPMSG="Not Found",ERRNAME="Unable to determine patient"
	I ERRCODE=204 D
	. S HTTPERR=404,TOPMSG="Not Found",ERRNAME="Unable to determine collection"
	I ERRCODE=205 S ERRNAME="Patient mismatch with object"
	I ERRCODE=207 S ERRNAME="Missing UID"
	I ERRCODE=209 S ERRNAME="Missing range or index"
	I ERRCODE=210 S ERRNAME="Unknown UID format"
	I ERRCODE=211 D
	. S HTTPERR=404,TOPMSG="Not Found",ERRNAME="Missing patient identifiers"
	I ERRCODE=212 S ERRNAME="Mismatch of patient identifiers"
	I ERRCODE=213 S ERRNAME="Delete demographics only not allowed"
	I ERRCODE=214 S HTTPERR=404,ERRNAME="Patient ID not found in database"
	I ERRCODE=215 S ERRNAME="Missing collection name"
	I ERRCODE=216 S ERRNAME="Incomplete deletion of collection"
	I ERRCODE=400 S ERRNAME="Bad Request"
	I ERRCODE=401 S ERRNAME="Unauthorized"
	I ERRCODE=404 S ERRNAME="Not Found"
	I ERRCODE=405 S ERRNAME="Method Not Allowed"
	I ERRCODE=501 S ERRNAME="M execution error"
	I ERRCODE=502 S ERRNAME="Unable to lock record"
	I '$L($G(ERRNAME)) S ERRNAME="Unknown error"
	I ERRCODE>500 S HTTPERR=500,TOPMSG="Internal Server Error"
	I ERRCODE<500,ERRCODE>400 S HTTPERR=ERRCODE,TOPMSG=ERRNAME
	Q
URLENC(X)
	N I,Y,Z,LAST
	S Y=$P(X,"%") F I=2:1:$L(X,"%") S Y=Y_"%25"_$P(X,"%",I)
	S X=Y,Y=$P(X,"&") F I=2:1:$L(X,"&") S Y=Y_"%26"_$P(X,"&",I)
	S X=Y,Y=$P(X,"=") F I=2:1:$L(X,"=") S Y=Y_"%3D"_$P(X,"=",I)
	S X=Y,Y=$P(X,"+") F I=2:1:$L(X,"+") S Y=Y_"%2B"_$P(X,"+",I)
	S X=Y,Y=$P(X,"{") F I=2:1:$L(X,"{") S Y=Y_"%7B"_$P(X,"{",I)
	S X=Y,Y=$P(X,"}") F I=2:1:$L(X,"}") S Y=Y_"%7D"_$P(X,"}",I)
	S Y=$TR(Y," ","+")
	S Z="",LAST=1
	F I=1:1:$L(Y) I $A(Y,I)<32 D
	. S CODE=$$DEC2HEX($A(Y,I)),CODE=$TR($J(CODE,2)," ","0")
	. S Z=Z_$E(Y,LAST,I-1)_"%"_CODE,LAST=I+1
	S Z=Z_$E(Y,LAST,$L(Y))
	Q Z
URLDEC(X,PATH)
	N I,OUT,FRAG,ASC
	S:'$G(PATH) X=$TR(X,"+"," ")
	F I=1:1:$L(X,"%") D
	. I I=1 S OUT=$P(X,"%") Q
	. S FRAG=$P(X,"%",I),ASC=$E(FRAG,1,2),FRAG=$E(FRAG,3,$L(FRAG))
	. I $L(ASC) S OUT=OUT_$C($$HEX2DEC(ASC))
	. S OUT=OUT_FRAG
	Q OUT
REFSIZE(ROOT)
	Q:'$D(ROOT) 0 Q:'$L(ROOT) 0
	N SIZE,I
	S SIZE=0
	I $D(@ROOT)#2 S SIZE=$ZL(@ROOT)
	I $D(@ROOT)>1 S I=0 F  S I=$O(@ROOT@(I)) Q:'I  D
	. I $ZE(@ROOT@(I),1,4)="$NA(" D  Q
	. . S TMP=$P($P(@ROOT@(I),"$NA(",2),")",1,$ZL(@ROOT@(I),")")-1)
	. . S SIZE=SIZE+$ZL(@TMP) Q
	. S SIZE=SIZE+$ZL(@ROOT@(I))
	Q SIZE
VARSIZE(V)
	Q:'$D(V) 0
	N SIZE,I
	S SIZE=0
	I $D(V)#2 S SIZE=$L(V)
	I $D(V)>1 S I="" F  S I=$O(V(I)) Q:'I  S SIZE=SIZE+$L(V(I))
	Q SIZE
GMT()
	N OUT
	I $$UP($ZV)["GT.M" D  Q OUT
	. N D S D="datetimepipe"
	. N OLDIO S OLDIO=$I
	. O D:(shell="/bin/sh":command="date -u +'%a, %d %b %Y %H:%M:%S %Z'|sed 's/UTC/GMT/g'")::"pipe"
	. U D R OUT:1
	. U OLDIO C D
	QUIT "UNIMPLEMENTED"
ENCODE(VVROOT,VVJSON,VVERR)
	I '$L($G(VVROOT)) Q
	I '$L($G(VVJSON)) Q
	N VVLINE,VVMAX,VVERRORS
	S VVLINE=1,VVMAX=4080,VVERRORS=0
	S @VVJSON@(VVLINE)=""
	D SEROBJ(VVROOT)
	Q
SEROBJ(VVROOT)
	N VVFIRST,VVSUB,VVNXT
	S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_"{"
	S VVFIRST=1
	S VVSUB="" F  S VVSUB=$O(@VVROOT@(VVSUB)) Q:VVSUB=""  D
	. S:'VVFIRST @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_"," S VVFIRST=0
	. D SERNAME(VVSUB)
	. I $$ISVALUE(VVROOT,VVSUB) D SERVAL(VVROOT,VVSUB) Q
	. I $D(@VVROOT@(VVSUB))=10 S VVNXT=$O(@VVROOT@(VVSUB,"")) D  Q
	. . I +VVNXT D SERARY($NA(@VVROOT@(VVSUB))) I 1
	. . E  D SEROBJ($NA(@VVROOT@(VVSUB)))
	. D ERRX("SOB",VVSUB)
	S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_"}"
	Q
SERARY(VVROOT)
	N VVFIRST,VVI,VVNXT
	S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_"["
	S VVFIRST=1
	S VVI=0 F  S VVI=$O(@VVROOT@(VVI)) Q:'VVI  D
	. S:'VVFIRST @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_"," S VVFIRST=0
	. I $$ISVALUE(VVROOT,VVI) D SERVAL(VVROOT,VVI) Q 
	. I $D(@VVROOT@(VVI))=10 S VVNXT=$O(@VVROOT@(VVI,"")) D  Q
	. . I +VVNXT D SERARY($NA(@VVROOT@(VVI))) I 1
	. . E  D SEROBJ($NA(@VVROOT@(VVI)))
	. D ERRX("SAR",VVI)
	S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_"]"
	Q
SERNAME(VVSUB)
	I ($L(VVSUB)+$L(@VVJSON@(VVLINE)))>VVMAX S VVLINE=VVLINE+1,@VVJSON@(VVLINE)=""
	S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_""""_VVSUB_""""_":"
	Q
SERVAL(VVROOT,VVSUB)
	N VVX,VVI
	I $D(@VVROOT@(VVSUB,":")) D  Q
	. S VVX=$G(@VVROOT@(VVSUB,":")) D:$L(VVX) CONCAT
	. S VVI=0 F  S VVI=$O(@VVROOT@(VVSUB,":",VVI)) Q:'VVI  S VVX=@VVROOT@(VVSUB,":",VVI) D CONCAT
	S VVX=$G(@VVROOT@(VVSUB))
	I '$D(@VVROOT@(VVSUB,"\s")),$$NUMERIC(VVX) D CONCAT QUIT
	I (VVX="true")!(VVX="false")!(VVX="null") D CONCAT QUIT
	S VVX=""""_$$ESC(VVX)
	D CONCAT
	I $D(@VVROOT@(VVSUB,"\")) D
	. S VVI=0 F  S VVI=$O(@VVROOT@(VVSUB,"\",VVI)) Q:'VVI   D
	. . S VVX=$$ESC(@VVROOT@(VVSUB,"\",VVI))
	. . D CONCAT
	S VVX="""" D CONCAT
	Q
CONCAT
	I ($L(VVX)+$L(@VVJSON@(VVLINE)))>VVMAX S VVLINE=VVLINE+1,@VVJSON@(VVLINE)=""
	S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_VVX
	Q
ISVALUE(VVROOT,VVSUB)
	I $D(@VVROOT@(VVSUB))#2 Q 1
	N VVX S VVX=$O(@VVROOT@(VVSUB,""))
	Q:VVX="\" 1
	Q:VVX=":" 1
	Q 0
NUMERIC(X) 
	I $L(X,".")>2 Q 0
	I $E(X,1,2)="-." Q 0
	I X=+X,$L(X)'=$L(+X) Q 0
	I $E(X)="." Q 0
	I X=+X Q 1
	Q 0
ESC(X)
	N Y,%DH
	S Y=X
	I X["\"  S Y=$$REPLACE(Y,"\","\\")
	I X["""" S Y=$$REPLACE(Y,"""","\""")
	I X["/"  S Y=$$REPLACE(Y,"/","\/")
	I X[$C(8) S Y=$$REPLACE(Y,$C(8),"\"_$C(98))
	I X[$C(12) S Y=$$REPLACE(Y,$C(12),"\"_$C(102))
	I X[$C(10) S Y=$$REPLACE(Y,$C(10),"\"_$C(110))
	I X[$C(13) S Y=$$REPLACE(Y,$C(13),"\"_$C(114))
	I X[$C(9) S Y=$$REPLACE(Y,$C(9),"\"_$C(116))
	N I F I=1:1:$L(X) D
	. I $A($E(X,I))=8   Q 
	. I $A($E(X,I))=12  Q 
	. I $A($E(X,I))=10  Q 
	. I $A($E(X,I))=13  Q 
	. I $A($E(X,I))=9   Q 
	. I $A($E(X,I))>=33 Q
	. S %DH=$A($E(X,I))
	. D ^%DH
	. S Y=$$REPLACE(Y,$E(X,I),"\u"_$E(%DH,$L(%DH)-3,$L(%DH)))
	Q Y 
	;
ERRX(ID,VAL)
	N ERRMSG
	I ID="STL{" S ERRMSG="Stack too large for new object." G XERRX
	I ID="SUF}" S ERRMSG="Stack Underflow - extra } found" G XERRX
	I ID="STL[" S ERRMSG="Stack too large for new array." G XERRX
	I ID="SUF]" S ERRMSG="Stack Underflow - extra ] found." G XERRX
	I ID="OBM" S ERRMSG="Array missmatch - expected ] got }." G XERRX
	I ID="ARM" S ERRMSG="Object mismatch - expected } got ]." G XERRX
	I ID="MPN" S ERRMSG="Missing property name." G XERRX
	I ID="EXT" S ERRMSG="Expected true, got "_VAL G XERRX
	I ID="EXF" S ERRMSG="Expected false, got "_VAL G XERRX
	I ID="EXN" S ERRMSG="Expected null, got "_VAL G XERRX
	I ID="TKN" S ERRMSG="Unable to identify type of token, value was "_VAL G XERRX
	I ID="SCT" S ERRMSG="Stack mismatch - exit stack level was  "_VAL G XERRX
	I ID="EIQ" S ERRMSG="Close quote not found before end of input." G XERRX
	I ID="EIU" S ERRMSG="Unexpected end of input while unescaping." G XERRX
	I ID="RSB" S ERRMSG="Reverse search for \ past beginning of input." G XERRX
	I ID="ORN" S ERRMSG="Overrun while scanning name." G XERRX
	I ID="OR#" S ERRMSG="Overrun while scanning number." G XERRX
	I ID="ORB" S ERRMSG="Overrun while scanning boolean." G XERRX
	I ID="ESC" S ERRMSG="Escaped character not recognized"_VAL G XERRX
	I ID="SOB" S ERRMSG="Unable to serialize node as object, value was "_VAL G XERRX
	I ID="SAR" S ERRMSG="Unable to serialize node as array, value was "_VAL G XERRX
	S ERRMSG="Unspecified error "_ID_" "_$G(VAL)
XERRX
	S @VVERR@(0)=$G(@VVERR@(0))+1
	S @VVERR@(@VVERR@(0))=ERRMSG
	S VVERRORS=VVERRORS+1
	Q
	;
DECODE(VVJSON,VVROOT,VVERR)
DIRECT
	N VVMAX S VVMAX=4080
	I $D(@VVJSON)=1 N VVINPUT S VVINPUT(1)=@VVJSON,VVJSON="VVINPUT"
	S VVROOT=$NA(@VVROOT@("Z")),VVROOT=$E(VVROOT,1,$L(VVROOT)-4) ; make open array ref
	N VVLINE,VVIDX,VVSTACK,VVPROP,VVTYPE,VVERRORS
	S VVLINE=$O(@VVJSON@("")),VVIDX=1,VVSTACK=0,VVPROP=0,VVERRORS=0
	F  S VVTYPE=$$NXTKN() Q:VVTYPE=""  D  I VVERRORS Q
	. I VVTYPE="{" S VVSTACK=VVSTACK+1,VVSTACK(VVSTACK)="",VVPROP=1 D:VVSTACK>64 ERRX("STL{") Q
	. I VVTYPE="}" D:$$NUMERIC(VVSTACK(VVSTACK)) ERRX("OBM") S VVSTACK=VVSTACK-1 D:VVSTACK<0 ERRX("SUF}") Q
	. I VVTYPE="[" S VVSTACK=VVSTACK+1,VVSTACK(VVSTACK)=1 D:VVSTACK>64 ERRX("STL[") Q
	. I VVTYPE="]" D:'$$NUMERIC(VVSTACK(VVSTACK)) ERRX("ARM") S VVSTACK=VVSTACK-1 D:VVSTACK<0 ERRX("SUF]") Q
	. I VVTYPE="," D  Q
	. . I VVSTACK(VVSTACK) S VVSTACK(VVSTACK)=VVSTACK(VVSTACK)+1  ; next in array
	. . E  S VVPROP=1                                   ; or next property name
	. I VVTYPE=":" S VVPROP=0 D:'$L($G(VVSTACK(VVSTACK))) ERRX("MPN") Q
	. I VVTYPE="""" D  Q
	. . I VVPROP S VVSTACK(VVSTACK)=$$NAMPARS() I 1
	. . E  D ADDSTR
	. S VVTYPE=$TR(VVTYPE,"TFN","tfn")
	. I VVTYPE="t"  D  Q
	. . I $L(@VVJSON@(VVLINE))<=VVIDX+2,$D(@VVJSON@(VVLINE+1)) D
	. . . S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_$E(@VVJSON@(VVLINE+1),1,2),@VVJSON@(VVLINE+1)=$E(@VVJSON@(VVLINE+1),3,$L(@VVJSON@(VVLINE+1)))
	. . I $TR($E(@VVJSON@(VVLINE),VVIDX,VVIDX+2),"RUE","rue")="rue" D SETBOOL("true") I 1
	. . E  B  D ERRX("EXT",VVTYPE)
	. I VVTYPE="f" D  Q
	. . I $L(@VVJSON@(VVLINE))<=VVIDX+3,$D(@VVJSON@(VVLINE+1)) D
	. . . S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_$E(@VVJSON@(VVLINE+1),1,3),@VVJSON@(VVLINE+1)=$E(@VVJSON@(VVLINE+1),4,$L(@VVJSON@(VVLINE+1)))
	. . I $TR($E(@VVJSON@(VVLINE),VVIDX,VVIDX+3),"ALSE","alse")="alse" D SETBOOL("false") I 1
	. . E  D ERRX("EXF",VVTYPE)
	. I VVTYPE="n" D  Q
	. . I $L(@VVJSON@(VVLINE))<=VVIDX+2,$D(@VVJSON@(VVLINE+1)) D
	. . . S @VVJSON@(VVLINE)=@VVJSON@(VVLINE)_$E(@VVJSON@(VVLINE+1),1,2),@VVJSON@(VVLINE+1)=$E(@VVJSON@(VVLINE+1),3,$L(@VVJSON@(VVLINE+1)))
	. . I $TR($E(@VVJSON@(VVLINE),VVIDX,VVIDX+2),"ULL","ull")="ull" D SETBOOL("null") I 1
	. . E  D ERRX("EXN",VVTYPE)
	. I "0123456789+-.eE"[VVTYPE S @$$CURNODE()=$$NUMPARS(VVTYPE) Q
	. D ERRX("TKN",VVTYPE_"["_$E(@VVJSON@(VVLINE),VVIDX,VVIDX+2)_"] ")
	I VVSTACK'=0 D ERRX("SCT",VVSTACK)
	Q
NXTKN()
	N VVDONE,VVEOF,VVTOKEN
	S VVDONE=0,VVEOF=0 F  D  Q:VVDONE!VVEOF
	. I VVIDX>$L(@VVJSON@(VVLINE)) S VVLINE=$O(@VVJSON@(VVLINE)),VVIDX=1 I 'VVLINE S VVEOF=1 Q
	. I $A(@VVJSON@(VVLINE),VVIDX)>32 S VVDONE=1 Q
	. S VVIDX=VVIDX+1
	Q:VVEOF ""
	S VVTOKEN=$E(@VVJSON@(VVLINE),VVIDX),VVIDX=VVIDX+1
	Q VVTOKEN
ADDSTR
	N VVEND,VVX
	S VVEND=$F(@VVJSON@(VVLINE),"""",VVIDX)
	I VVEND,($E(@VVJSON@(VVLINE),VVEND-2)'="\") D SETSTR  Q
	I VVEND,$$ISCLOSEQ(VVLINE) D SETSTR Q
	N VVDONE,VVTLINE
	S VVDONE=0,VVTLINE=VVLINE
	F  D  Q:VVDONE  Q:VVERRORS
	. I 'VVEND S VVTLINE=VVTLINE+1,VVEND=1 I '$D(@VVJSON@(VVTLINE)) D ERRX("EIQ") Q
	. S VVEND=$F(@VVJSON@(VVTLINE),"""",VVEND)
	. I VVEND,$E(@VVJSON@(VVTLINE),VVEND-2)'="\" S VVDONE=1 Q
	. S VVDONE=$$ISCLOSEQ(VVTLINE)
	Q:VVERRORS
	D UESEXT
	S VVLINE=VVTLINE,VVIDX=VVEND
	Q
SETSTR
	N VVX
	S VVX=$E(@VVJSON@(VVLINE),VVIDX,VVEND-2),VVIDX=VVEND
	S @$$CURNODE()=$$UES(VVX)
	I VVIDX>$L(@VVJSON@(VVLINE)) S VVLINE=VVLINE+1,VVIDX=1
	Q
UESEXT
	N VVI,VVY,VVSTART,VVSTOP,VVDONE,VVBUF,VVNODE,VVMORE,VVTO
	S VVNODE=$$CURNODE(),VVBUF="",VVMORE=0,VVSTOP=VVEND-2
	S VVI=VVIDX,VVY=VVLINE,VVDONE=0
	F  D  Q:VVDONE  Q:VVERRORS
	. S VVSTART=VVI,VVI=$F(@VVJSON@(VVY),"\",VVI)
	. I (VVY=VVTLINE) S VVTO=$S('VVI:VVSTOP,VVI>VVSTOP:VVSTOP,1:VVI-2) I 1
	. E  S VVTO=$S('VVI:99999,1:VVI-2)
	. D ADDBUF($E(@VVJSON@(VVY),VVSTART,VVTO))
	. I (VVY'<VVTLINE),(('VVI)!(VVI>VVSTOP)) S VVDONE=1 QUIT
	. I 'VVI S VVY=VVY+1,VVI=1 QUIT 
	. I VVI>$L(@VVJSON@(VVY)) S VVY=VVY+1,VVI=1 I '$D(@VVJSON@(VVY)) D ERRX("EIU")
	. D ADDBUF($$REALCHAR($E(@VVJSON@(VVY),VVI),@VVJSON@(VVY),.VVI))
	. S VVI=VVI+1
	. I (VVY'<VVTLINE),(VVI>VVSTOP) S VVDONE=1
	Q:VVERRORS
	D SAVEBUF
	Q
ADDBUF(VVX)
	I $L(VVX)+$L(VVBUF)>VVMAX D SAVEBUF
	S VVBUF=VVBUF_VVX
	Q
SAVEBUF
	I 'VVMORE S @VVNODE=VVBUF S:+VVBUF=VVBUF @VVNODE@("\s")="" I 1
	E  S @VVNODE@("\",VVMORE)=VVBUF
	S VVMORE=VVMORE+1,VVBUF=""
	Q
ISCLOSEQ(VVBLINE)
	N VVBACK,VVBIDX
	S VVBACK=0,VVBIDX=VVEND-2
	F  D  Q:$E(@VVJSON@(VVBLINE),VVBIDX)'="\"  Q:VVERRORS
	. S VVBACK=VVBACK+1,VVBIDX=VVBIDX-1
	. I (VVBLINE=VVLINE),(VVBIDX=VVIDX) Q
	. Q:VVBIDX
	. S VVBLINE=VVBLINE-1 I VVBLINE<VVLINE D ERRX("RSB") Q
	. S VVBIDX=$L(@VVJSON@(VVBLINE))
	Q VVBACK#2=0
NAMPARS()
	N VVEND,VVDONE,VVNAME
	S VVDONE=0,VVNAME=""
	F  D  Q:VVDONE  Q:VVERRORS
	. S VVEND=$F(@VVJSON@(VVLINE),"""",VVIDX)
	. I VVEND S VVNAME=VVNAME_$E(@VVJSON@(VVLINE),VVIDX,VVEND-2),VVIDX=VVEND,VVDONE=1
	. I 'VVEND S VVNAME=VVNAME_$E(@VVJSON@(VVLINE),VVIDX,$L(@VVJSON@(VVLINE)))
	. I 'VVEND!(VVEND>$L(@VVJSON@(VVLINE))) S VVLINE=VVLINE+1,VVIDX=1 I '$D(@VVJSON@(VVLINE)) D ERRX("ORN")
	Q VVNAME
NUMPARS(VVDIGIT)
	N VVDONE,VVNUM
	S VVDONE=0,VVNUM=VVDIGIT
	F  D  Q:VVDONE  Q:VVERRORS
	. I '("0123456789+-.eE"[$E(@VVJSON@(VVLINE),VVIDX)) S VVDONE=1 Q
	. S VVNUM=VVNUM_$E(@VVJSON@(VVLINE),VVIDX)
	. S VVIDX=VVIDX+1 I VVIDX>$L(@VVJSON@(VVLINE)) S VVLINE=VVLINE+1,VVIDX=1 I '$D(@VVJSON@(VVLINE)) D ERRX("OR#")
	Q VVNUM
SETBOOL(VVX)
	S @$$CURNODE()=VVX
	S VVIDX=VVIDX+$L(VVX)-1
	N VVDIFF S VVDIFF=VVIDX-$L(@VVJSON@(VVLINE))
	I VVDIFF>0 S VVLINE=VVLINE+1,VVIDX=VVDIFF I '$D(@VVJSON@(VVLINE)) D ERRX("ORB")
	Q
CURNODE()
	N VVI,VVSUBS
	S VVSUBS=""
	F VVI=1:1:VVSTACK S:VVI>1 VVSUBS=VVSUBS_"," D
	. I $$NUMERIC(VVSTACK(VVI))  S VVSUBS=VVSUBS_VVSTACK(VVI)
	. E  S VVSUBS=VVSUBS_""""_VVSTACK(VVI)_""""
	Q VVROOT_VVSUBS_")"
UES(X)
	N POS,Y,START
	S POS=0,Y=""
	F  S START=POS+1 D  Q:START>$L(X)
	. S POS=$F(X,"\",POS+1)
	. I 'POS S Y=Y_$E(X,START,$L(X)),POS=$L(X) I 1
	. E  S Y=Y_$E(X,START,POS-2)_$$REALCHAR($E(X,POS),X,.POS)
	Q Y
REALCHAR(C,X,POS)
	N OPOS
	I C="""" Q """"
	I C="/" Q "/"
	I C="\" Q "\"
	I C="b" Q $C(8)
	I C="f" Q $C(12)
	I C="n" Q $C(10)
	I C="r" Q $C(13)
	I C="t" Q $C(9)
	I C="u" S OPOS=POS S POS=POS+4 Q $C($$FUNC^%HD($E(X,OPOS+1,OPOS+4)))
	Q C
	;
HASH(X)
	Q $$CRC32(X)
SYSID() ;
	S X=$SYSTEM
	QUIT $$CRC16HEX(X)
CRC16HEX(X)
	QUIT $$BASE($$CRC16(X),10,16)
CRC32HEX(X)
	QUIT $$BASE($$CRC32(X),10,16)
DEC2HEX(NUM)
	Q $$BASE(NUM,10,16)
HEX2DEC(HEX)
	Q $$BASE(HEX,16,10)
CRC32(string,seed) ;
	N I,J,R
	I '$D(seed) S R=4294967295
	E  I seed'<0,seed'>4294967295 S R=4294967295-seed
	E  S $ECODE=",M28,"
	F I=1:1:$L(string) D
	. S R=$$XOR($A(string,I),R,8)
	. F J=0:1:7 D
	. . I R#2 S R=$$XOR(R\2,3988292384,32)
	. . E  S R=R\2
	. . Q
	. Q
	Q 4294967295-R
XOR(a,b,w) N I,M,R
	S R=b,M=1
	F I=1:1:w D
	. S:a\M#2 R=R+$S(R\M#2:-M,1:M)
	. S M=M+M
	. Q
	Q R
BASE(%X1,%X2,%X3)
	I (%X2<2)!(%X2>16)!(%X3<2)!(%X3>16) Q -1
	Q $$CNV($$DEC(%X1,%X2),%X3)
DEC(N,B) ;Cnv N from B to 10
	Q:B=10 N N I,Y S Y=0
	F I=1:1:$L(N) S Y=Y*B+($F("0123456789ABCDEF",$E(N,I))-2)
	Q Y
CNV(N,B) ;Cnv N from 10 to B
	Q:B=10 N N I,Y S Y=""
	F I=1:1 S Y=$E("0123456789ABCDEF",N#B+1)_Y,N=N\B Q:N<1
	Q Y
CRC16(string,seed) ;
	N I,J,R
	I '$D(seed) S R=0
	E  I seed'<0,seed'>65535 S R=seed\1
	E  S $ECODE=",M28,"
	F I=1:1:$L(string) D
	. S R=$$XOR($A(string,I),R,8)
	. F J=0:1:7 D
	. . I R#2 S R=$$XOR(R\2,40961,16)
	. . E  S R=R\2
	. . Q
	. Q
	Q R
	;
HTFM(%H,%F)
	N X,%,%T,%Y,%M,%D S:'$D(%F) %F=0
	I $$HR(%H) Q -1 ;Check Range
	I '%F,%H[",0" S %H=(%H-1)_",86400"
	D YMD S:%T&('%F) X=X_%T
	Q X
YMD ;
	S %=(%H>21608)+(%H>94657)+%H-.1,%Y=%\365.25+141,%=%#365.25\1
	S %D=%+306#(%Y#4=0+365)#153#61#31+1,%M=%-%D\29+1
	S X=%Y_"00"+%M_"00"+%D,%=$P(%H,",",2)
	S %T=%#60/100+(%#3600\60)/100+(%\3600)/100 S:'%T %T=".0"
	Q
HR(%V)
	Q (%V<2)!(%V>99999)
HTE(%H,%F)
	Q:$$HR(%H) %H ;Range Check
	N Y,%T,%R
	S %F=$G(%F,1) S Y=$$HTFM(%H,0)
T2 S %T="."_$E($P(Y,".",2)_"000000",1,7)
	D FMT Q %R
FMT ;
	N %G S %G=+%F
	G F1:%G=1,F2:%G=2,F3:%G=3,F4:%G=4,F5:%G=5,F6:%G=6,F7:%G=7,F8:%G=8,F9:%G=9,F1
	Q
F1 ;
	S %R=$P($$M()," ",$S($E(Y,4,5):$E(Y,4,5)+2,1:0))_$S($E(Y,4,5):" ",1:"")_$S($E(Y,6,7):$E(Y,6,7)_", ",1:"")_($E(Y,1,3)+1700)
TM  ;
	N %,%S Q:%T'>0!(%F["D")
	I %F'["P" S %R=%R_"@"_$E(%T,2,3)_":"_$E(%T,4,5)_$S(%F["M":"",$E(%T,6,7)!(%F["S"):":"_$E(%T,6,7),1:"")
	I %F["P" D
	. S %R=%R_" "_$S($E(%T,2,3)>12:$E(%T,2,3)-12,+$E(%T,2,3)=0:"12",1:+$E(%T,2,3))_":"_$E(%T,4,5)_$S(%F["M":"",$E(%T,6,7)!(%F["S"):":"_$E(%T,6,7),1:"")
	. S %R=%R_$S($E(%T,2,7)<120000:" am",$E(%T,2,3)=24:" am",1:" pm")
	. Q
	Q
M() Q "  Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
F2  ;
	S %R=$J(+$E(Y,4,5),2)_"/"_$J(+$E(Y,6,7),2)_"/"_$E(Y,2,3)
	S:%F["Z" %R=$TR(%R," ","0") S:%F'["F" %R=$TR(%R," ")
	G TM
F3  ;
	S %R=$J(+$E(Y,6,7),2)_"/"_$J(+$E(Y,4,5),2)_"/"_$E(Y,2,3)
	S:%F["Z" %R=$TR(%R," ","0") S:%F'["F" %R=$TR(%R," ")
	G TM
F4  ;
	S %R=$E(Y,2,3)_"/"_$J(+$E(Y,4,5),2)_"/"_$J(+$E(Y,6,7),2)
	S:%F["Z" %R=$TR(%R," ","0") S:%F'["F" %R=$TR(%R," ")
	G TM
F5  ;
	S %R=$J(+$E(Y,4,5),2)_"/"_$J(+$E(Y,6,7),2)_"/"_($E(Y,1,3)+1700)
	S:%F["Z" %R=$TR(%R," ","0") S:%F'["F" %R=$TR(%R," ")
	G TM
F6  ;
	S %R=$J(+$E(Y,6,7),2)_"/"_$J(+$E(Y,4,5),2)_"/"_($E(Y,1,3)+1700)
	S:%F["Z" %R=$TR(%R," ","0") S:%F'["F" %R=$TR(%R," ")
	G TM
F7  ;
	S %R=($E(Y,1,3)+1700)_"/"_$J(+$E(Y,4,5),2)_"/"_$J(+$E(Y,6,7),2)
	S:%F["Z" %R=$TR(%R," ","0") S:%F'["F" %R=$TR(%R," ")
	G TM
F8  ;
	S %R=$S($E(Y,6,7):$E(Y,6,7)_" ",1:"")_$P($$M()," ",$S($E(Y,4,5):$E(Y,4,5)+2,1:0))_$S($E(Y,4,5):" ",1:"")_$E(Y,2,3)
	G TM
F9  ;
	S %R=$S($E(Y,6,7):$E(Y,6,7)_" ",1:"")_$P($$M()," ",$S($E(Y,4,5):$E(Y,4,5)+2,1:0))_$S($E(Y,4,5):" ",1:"")_($E(Y,1,3)+1700)
	G TM
	;
PARSE10(BODY,PARSED)
	N LL S LL=""
	N L S L=1 
	K PARSED
	N I S I="" F  S I=$O(BODY(I)) Q:'I  D 
	. N J F J=1:1:$L(BODY(I),$C(10)) D 
	. . S:(J=1&(L>1)) L=L-1 
	. . S PARSED(L)=$TR($P(BODY(I),$C(10),J),$C(13)) 
	. . S:(J=1&(L>1)) PARSED(L)=LL_PARSED(L)
	. . S LL=PARSED(L)
	. . S L=L+1
	QUIT
	;
ADDCRLF(RESULT)
	I $E($G(RESULT))="^" D  QUIT  ; Global
	. N V,QL S V=RESULT,QL=$QL(V) F  S V=$Q(@V) Q:V=""  Q:$NA(@V,QL)'=RESULT  S @V=@V_$C(13,10)
	E  D
	. I $D(RESULT)#2 S RESULT=RESULT_$C(13,10)
	. N V S V=$NA(RESULT) F  S V=$Q(@V) Q:V=""  S @V=@V_$C(13,10)
	QUIT
	;
ENCODE64(X)
	N RGZ,RGZ1,RGZ2,RGZ3,RGZ4,RGZ5,RGZ6
	S RGZ=$$INIT64,RGZ1=""
	F RGZ2=1:3:$L(X) D
	. S RGZ3=0,RGZ6=""
	. F RGZ4=0:1:2 D
	. . S RGZ5=$A(X,RGZ2+RGZ4),RGZ3=RGZ3*256+$S(RGZ5<0:0,1:RGZ5)
	. F RGZ4=1:1:4 S RGZ6=$E(RGZ,RGZ3#64+2)_RGZ6,RGZ3=RGZ3\64
	. S RGZ1=RGZ1_RGZ6
	S RGZ2=$L(X)#3
	S:RGZ2 RGZ3=$L(RGZ1),$E(RGZ1,RGZ3-2+RGZ2,RGZ3)=$E("==",RGZ2,2)
	Q RGZ1
DECODE64(X)
	N RGZ,RGZ1,RGZ2,RGZ3,RGZ4,RGZ5,RGZ6
	S RGZ=$$INIT64,RGZ1=""
	F RGZ2=1:4:$L(X) D
	. S RGZ3=0,RGZ6=""
	. F RGZ4=0:1:3 D
	. . S RGZ5=$F(RGZ,$E(X,RGZ2+RGZ4))-3
	. . S RGZ3=RGZ3*64+$S(RGZ5<0:0,1:RGZ5)
	. F RGZ4=0:1:2 S RGZ6=$C(RGZ3#256)_RGZ6,RGZ3=RGZ3\256
	. S RGZ1=RGZ1_RGZ6
	Q $E(RGZ1,1,$L(RGZ1)-$L(X,"=")+1)
INIT64() Q "=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
REPLACE(s,f,t)
	i $tr(s,f)=s q s
	n o,i s o="" f i=1:1:$l(s,f)  s o=o_$s(i<$l(s,f):$p(s,f,i)_t,1:$p(s,f,i))
	q o
GetMimeType(EXT)
	I $G(EXT)="" S EXT="*"
	S EXT=$$LOW(EXT)
	I '$D(ZUBAIR(":WS","MIME")) D
	. S ZUBAIR(":WS","MIME","html")="text/html" 
	. S ZUBAIR(":WS","MIME","htm")="text/html" 
	. S ZUBAIR(":WS","MIME","shtml")="text/html"
	. S ZUBAIR(":WS","MIME","css")="text/css"
	. S ZUBAIR(":WS","MIME","xml")="text/xml"
	. S ZUBAIR(":WS","MIME","gif")="image/gif"
	. S ZUBAIR(":WS","MIME","jpeg")="image/jpeg" 
	. S ZUBAIR(":WS","MIME","jpg")="image/jpeg"
	. S ZUBAIR(":WS","MIME","js")="application/javascript"
	. S ZUBAIR(":WS","MIME","atom")="application/atom+xml"
	. S ZUBAIR(":WS","MIME","rss")="application/rss+xml"
	. S ZUBAIR(":WS","MIME","mml")="text/mathml"
	. S ZUBAIR(":WS","MIME","txt")="text/plain"
	. S ZUBAIR(":WS","MIME","jad")="text/vnd.sun.j2me.app-descriptor"
	. S ZUBAIR(":WS","MIME","wml")="text/vnd.wap.wml"
	. S ZUBAIR(":WS","MIME","htc")="text/x-component"
	. S ZUBAIR(":WS","MIME","png")="image/png"
	. S ZUBAIR(":WS","MIME","tif")="image/tiff" 
	. S ZUBAIR(":WS","MIME","tiff")="image/tiff"
	. S ZUBAIR(":WS","MIME","wbmp")="image/vnd.wap.wbmp"
	. S ZUBAIR(":WS","MIME","ico")="image/x-icon"
	. S ZUBAIR(":WS","MIME","jng")="image/x-jng"
	. S ZUBAIR(":WS","MIME","bmp")="image/x-ms-bmp"
	. S ZUBAIR(":WS","MIME","svg")="image/svg+xml"
	. S ZUBAIR(":WS","MIME","svgz")="image/svg+xml"
	. S ZUBAIR(":WS","MIME","webp")="image/webp"
	. S ZUBAIR(":WS","MIME","woff")="application/font-woff"
	. S ZUBAIR(":WS","MIME","jar")="application/java-archive" 
	. S ZUBAIR(":WS","MIME","war")="application/java-archive"
	. S ZUBAIR(":WS","MIME","ear")="application/java-archive"
	. S ZUBAIR(":WS","MIME","json")="application/json"
	. S ZUBAIR(":WS","MIME","hqx")="application/mac-binhex40"
	. S ZUBAIR(":WS","MIME","doc")="application/msword"
	. S ZUBAIR(":WS","MIME","pdf")="application/pdf"
	. S ZUBAIR(":WS","MIME","ps")="application/postscript" 
	. S ZUBAIR(":WS","MIME","eps")="application/postscript" 
	. S ZUBAIR(":WS","MIME","ai")="application/postscript"
	. S ZUBAIR(":WS","MIME","rtf")="application/rtf"
	. S ZUBAIR(":WS","MIME","m3u8")="application/vnd.apple.mpegurl"
	. S ZUBAIR(":WS","MIME","xls")="application/vnd.ms-excel"
	. S ZUBAIR(":WS","MIME","eot")="application/vnd.ms-fontobject"
	. S ZUBAIR(":WS","MIME","ppt")="application/vnd.ms-powerpoint"
	. S ZUBAIR(":WS","MIME","wmlc")="application/vnd.wap.wmlc"
	. S ZUBAIR(":WS","MIME","kml")="application/vnd.google-earth.kml+xml"
	. S ZUBAIR(":WS","MIME","kmz")="application/vnd.google-earth.kmz"
	. S ZUBAIR(":WS","MIME","7z")="application/x-7z-compressed"
	. S ZUBAIR(":WS","MIME","cco")="application/x-cocoa"
	. S ZUBAIR(":WS","MIME","jardiff")="application/x-java-archive-diff"
	. S ZUBAIR(":WS","MIME","jnlp")="application/x-java-jnlp-file"
	. S ZUBAIR(":WS","MIME","run")="application/x-makeself"
	. S ZUBAIR(":WS","MIME","pl")="application/x-perl"
	. S ZUBAIR(":WS","MIME","pm")="application/x-perl"
	. S ZUBAIR(":WS","MIME","prc")="application/x-pilot" 
	. S ZUBAIR(":WS","MIME","pdb")="application/x-pilot"
	. S ZUBAIR(":WS","MIME","rar")="application/x-rar-compressed"
	. S ZUBAIR(":WS","MIME","rpm")="application/x-redhat-package-manager"
	. S ZUBAIR(":WS","MIME","sea")="application/x-sea"
	. S ZUBAIR(":WS","MIME","swf")="application/x-shockwave-flash"
	. S ZUBAIR(":WS","MIME","sit")="application/x-stuffit"
	. S ZUBAIR(":WS","MIME","tcl")="application/x-tcl"
	. S ZUBAIR(":WS","MIME","tk")="application/x-tcl"
	. S ZUBAIR(":WS","MIME","der")="application/x-x509-ca-cert"
	. S ZUBAIR(":WS","MIME","pem")="application/x-x509-ca-cert"
	. S ZUBAIR(":WS","MIME","crt")="application/x-x509-ca-cert"
	. S ZUBAIR(":WS","MIME","xpi")="application/x-xpinstall"
	. S ZUBAIR(":WS","MIME","xhtml")="application/xhtml+xml"
	. S ZUBAIR(":WS","MIME","xspf")="application/xspf+xml"
	. S ZUBAIR(":WS","MIME","zip")="application/zip"
	. S ZUBAIR(":WS","MIME","bin")="application/octet-stream" 
	. S ZUBAIR(":WS","MIME","exe")="application/octet-stream" 
	. S ZUBAIR(":WS","MIME","dll")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","deb")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","dmg")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","iso")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","img")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","msi")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","msp")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","msm")="application/octet-stream"
	. S ZUBAIR(":WS","MIME","docx")="application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	. S ZUBAIR(":WS","MIME","xlsx")="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
	. S ZUBAIR(":WS","MIME","pptx")="application/vnd.openxmlformats-officedocument.presentationml.presentation"
	. S ZUBAIR(":WS","MIME","mid")="audio/midi"
	. S ZUBAIR(":WS","MIME","midi")="audio/midi"
	. S ZUBAIR(":WS","MIME","kar")="audio/midi"
	. S ZUBAIR(":WS","MIME","mp3")="audio/mpeg"
	. S ZUBAIR(":WS","MIME","ogg")="audio/ogg"
	. S ZUBAIR(":WS","MIME","m4a")="audio/x-m4a"
	. S ZUBAIR(":WS","MIME","ra")="audio/x-realaudio"
	. S ZUBAIR(":WS","MIME","3gpp")="video/3gpp"
	. S ZUBAIR(":WS","MIME","3gp")="video/3gpp"
	. S ZUBAIR(":WS","MIME","ts")="video/mp2t"
	. S ZUBAIR(":WS","MIME","mp4")="video/mp4"
	. S ZUBAIR(":WS","MIME","mpeg")="video/mpeg"
	. S ZUBAIR(":WS","MIME","mpg")="video/mpeg"
	. S ZUBAIR(":WS","MIME","mov")="video/quicktime"
	. S ZUBAIR(":WS","MIME","webm")="video/webm"
	. S ZUBAIR(":WS","MIME","flv")="video/x-flv"
	. S ZUBAIR(":WS","MIME","m4v")="video/x-m4v"
	. S ZUBAIR(":WS","MIME","mng")="video/x-mng"
	. S ZUBAIR(":WS","MIME","asx")="video/x-ms-asf"
	. S ZUBAIR(":WS","MIME","asf")="video/x-ms-asf"
	. S ZUBAIR(":WS","MIME","wmv")="video/x-ms-wmv"
	. S ZUBAIR(":WS","MIME","avi")="video/x-msvideo"
	I $D(ZUBAIR(":WS","MIME",EXT)) Q ZUBAIR(":WS","MIME",EXT)
	E  Q "application/octet-stream"
RoutinePaths(DIR)
	N ZRO,PIECE,I,CNT,PATH
	S ZRO=$ZROUTINES
	S CNT=1
	K DIR
	F  Q:($E(ZRO)'=" ")  S ZRO=$E(ZRO,2,$L(ZRO))
	F I=1:1:$L(ZRO," ") S PIECE=$P(ZRO," ",I) D
	. Q:$P(PIECE,".",2)="so"
	. Q:$P(PIECE,".",2)="o"
	. I PIECE["(",PIECE[")" S PATH=$P($P(PIECE,"(",2),")")
	. I PIECE["(" S PATH=$P(PIECE,"(",2)
	. I PIECE[")" S PATH=$P(PIECE,")")
	. I PIECE'[")",PIECE'["("  S PATH=PIECE
	. I $$DirectoryExists(PATH) S DIR(CNT)=PATH
	. S CNT=CNT+1
	Q
DeleteFile(FILE)
	N RET,COMMMAND
	S COMMAND="rm "_FILE
	D RunShellCommand(COMMAND,.RET)
	Q
RunShellCommand(command,return)
	N device,counter,string,currentdevice set counter=0
	S currentdevice=$io
	S device="runshellcommmandpipe"_$job
	O device:(shell="/bin/sh":command=command:readonly)::"pipe"
	U device for  quit:$zeof=1  read string:2 set return($increment(counter))=string quit:'$test
	C device if $get(return(counter))="" kill return(counter)
	U currentdevice
	Q
DirectoryExists(path)
	Q $zsearch(path)]""
FileExists(path)
	Q $zsearch(path)]""
CreateDirectoryTree(path)
	N return,commmand
	S command="mkdir -p "_path
	D RunShellCommand(command,.return)
	I $$DirectoryExists(path) quit 1
	Q 0
GetRoutineList(%ZR,pattern)
	I $G(pattern)="" S pattern="*"
	D SILENT^%RSEL(pattern)
	Q
ReadFileByLine(file,return)
	N source,line,counter,currentdevice
	S source=file,currentdevice=$io
	O source:(readonly:chset="m")
	F  U source read line:2 Q:$zeof  Q:'$test  D
	. I $ZE(line,$L(line))=$C(13) S line=$ZE(line,1,$L(line)-1)
	. I $ZE(line,$L(line))=$C(10) S line=$ZE(line,1,$L(line)-1)
	. S return($I(counter))=line
	C source U currentdevice
	Q
ReadFileByChunk(file,chunk,return)
	N source,line,counter,currentdevice
	S currentdevice=$io
	S source=file
	O source:(readonly:fixed:recordsize=chunk:chset="m")
	F  U source R line:2 Q:$zeof  Q:'$T  D
	. S return($increment(counter))=line
	C source
	U currentdevice
	Q
WriteFile(file,data)
	N currentdevice S currentdevice=$io
	O file:(newversion)
	N line S line="" F  S line=$O(data(line)) Q:line=""  U file W data(line),!
	C file
	U currentdevice
	Q
UP(string)	Q $zconvert(string,"u")
LOW(string) Q $zconvert(string,"l")
APIERR 
		Q
API(%Q,%R,%A)
	s $ET="D APIERR"
	N %J
	S %R("mime")="application/json"
	S %R("header","Access-Control-Allow-Origin")="*"
	S %R("header","Access-Control-Allow-Headers")="Origin, X-Requested-With, Content-Type, Accept"
	I '$D(@%Q("body")) Q
	N %RR D DECODE(%Q("body"),"%RR")
	N %ROUTINE S %ROUTINE=%RR("routine")
	K %RR("routine") K %J
	N (%RR,%J,%WTCP,%ROUTINE,%Q,%R,%A,ZUBAIRRESP)
	D @(%ROUTINE_"(.%RR,.%J)")
	K @%R D ENCODE("%J",%R)
	Q
	;
SERVESTATIC(%Q,%R,%A)	
	N PATH S PATH=$G(%Q("path")) 
	I PATH="" S PATH="/Zubair/index.html"
	I PATH="/" S PATH="/Zubair/index.html"
	I PATH="/Zubair" S PATH="/Zubair/index.html"
	I PATH="/Zubair/" S PATH="/Zubair/index.html"
	I $E(PATH,1,8)'="/Zubair/" D SETERROR(404) Q
	N FILEPATHS
	S FILEPATH="dist/spa/"_$E(PATH,9,$L(PATH))
	I $P(FILEPATH,".",$L(FILEPATH,"."))["?" D
	. S $P(FILEPATH,".",$L(FILEPATH,"."))=$P($P(FILEPATH,".",$L(FILEPATH,".")),"?")
	I '$$FileExists(FILEPATH) D
	. S FILEPATH="dist/spa/index.html"
	N EXT S EXT=$P(FILEPATH,".",$L(FILEPATH,"."))
	S %R("mime")=$$GetMimeType(EXT)
	N OUTPUT
	D ReadFileByChunk(FILEPATH,4080,.OUTPUT)
	M @%R=OUTPUT
	Q
	;	
PING(I,O)
	S O("data","RESULT")="PONG"
	Q