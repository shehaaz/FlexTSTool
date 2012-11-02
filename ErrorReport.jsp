<%-- /////////////////////////////////////////////////////////////////////////////////////--%>
<%-- //////////////////////////////// PAGE DOCUMENTATION//////////////////////////////////--%>
<%-- /////////////////////////////////////////////////////////////////////////////////////--%>

<%-- /////////////////////////////////////////////////////////////////////////////////////--%>
<%-- //////////////////////////////////// HTML ///////////////////////////////////////////--%>
<%-- /////////////////////////////////////////////////////////////////////////////////////--%>
<%@page language="java" import="com.lcs.wc.classification.ClassificationTreeLoader,
                com.lcs.wc.client.Activities,
                java.io.*,
                com.lcs.wc.client.web.*,
                java.io.*,
    		  com.lcs.wc.db.*,
				com.lcs.wc.db.*,
                java.util.*,
				java.lang.*,
                wt.util.WTProperties,
                wt.util.*,
                com.lcs.wc.util.*,
				com.lcs.wc.client.web.*,
				java.util.Collection,
				java.util.Iterator"
                session="true"%>


<%-- /////////////////////////////////////////////////////////////////////////////////////--%>
<%-- //////////////////////////////// BEAN INITIALIZATIONS ///////////////////////////////--%>
<%-- /////////////////////////////////////////////////////////////////////////////////////--%>
<jsp:useBean id="tg" scope="request" class="com.lcs.wc.client.web.TableGenerator" />
<jsp:useBean id="fg" scope="request" class="com.lcs.wc.client.web.FormGenerator" />
<jsp:useBean id="flexg" scope="request" class="com.lcs.wc.client.web.FlexTypeGenerator" />
<jsp:useBean id="lcsContext" class="com.lcs.wc.client.ClientContext" scope="session"/>
<%!
	public static final String URL_CONTEXT = LCSProperties.get("flexPLM.urlContext.override");
    private static boolean GENERIC_EXCEPTIONS = LCSProperties.getBoolean("jsp.exception.GenericExceptionPage.enabled");
    public static final String PACKAGE_ERROR_PAGE = PageManager.getPageURL("PACKAGE_ERROR_PAGE", null);

    public static String instance = "";
    public static String systemName = "";
    private static boolean getRemoteHost = LCSProperties.getBoolean("flexpdm.getRemoteHost");


	public static final String subURLFolder = LCSProperties.get("flexPLM.windchill.subURLFolderLocation");
    public static final String JSPNAME = "ExceptionController";
    public static final boolean DEBUG = LCSProperties.getBoolean("jsp.main.ExceptionController.verbose");
    public static final String MAINTEMPLATE = PageManager.getPageURL("MAINTEMPLATE", null);
    String fileEncoding = com.lcs.wc.load.LoadCommon.getFileEncoding();
    public static String WindchillContext = "/Windchill";
    public static String wt_home = "";
    public static String serverName = "";

	public static String supportPackageSaveLocation = "";

    static {
        try {
            instance = wt.util.WTProperties.getLocalProperties().getProperty ("wt.federation.ie.VMName");
            systemName = wt.util.WTProperties.getLocalProperties().getProperty ("java.rmi.server.hostname");
            WTProperties wtproperties = WTProperties.getLocalProperties();
			WindchillContext = "/" + wtproperties.getProperty("wt.webapp.name");
            wt_home =  wtproperties.getProperty("wt.home");
            serverName = wtproperties.getProperty("java.rmi.server.hostname");
			String fileSaveLocation = wt_home + File.separator + "logs" + File.separator + "ErrorPackages";
			supportPackageSaveLocation = LCSProperties.get("jsp.exception.SupportPackageLocation",fileSaveLocation);


        } catch(Throwable e){
            e.printStackTrace();
        }
    }

    public static final String CSS_FILE = PageManager.getPageURL("CSS", null);
%>

<%
Throwable exception = org.apache.jasper.runtime.JspRuntimeLibrary.getThrowable(request);

    Throwable currentException = null;
    if(exception instanceof javax.servlet.ServletException && ((javax.servlet.ServletException)exception).getRootCause() != null){

        currentException = ((javax.servlet.ServletException)exception).getRootCause();
    }else{
        currentException = (Throwable) request.getAttribute("Exception");
		if(currentException == null && exception != null){
			currentException = exception;
		}
    }

%>
<%
//setting up which RBs to use
Object[] objA = new Object[0];
String ERROR_REPORT_MAIN = "com.lcs.wc.resource.ErrorReportRB";

String errorReport_errorOccured = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_errorOccured", objA ) ;
String errorReport_jsErrorOccured = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_jsErrorOccured", objA ) ;
String returnButton = WTMessage.getLocalizedMessage ( RB.MAIN, "return_Btn", RB.objA ) ;
String errorReport_JSMerrorStackTrace = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_JSMerrorStackTrace", objA ) ;
String errorReport_errorStackTrace = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_errorStackTrace", objA ) ;
String errorReport_requestDump = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_requestDump", objA ) ;
String errorReport_htmlSource = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_htmlSource", objA ) ;

String genericMessageToUser = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_genericEmailMessage", objA ) ;
String errorMessageToUser = currentException.getMessage();
errorMessageToUser = FormatHelper.hasContent(errorMessageToUser) ? errorMessageToUser : genericMessageToUser;

%>

<%
    String pagehref = request.getParameter("pagehref");
    String pagetitle = request.getParameter("pagetitle");
    String pagebodyA = request.getParameter("pagebodyA");
    String pagebodyB = request.getParameter("pagebodyB");

    String pageErrors = request.getParameter("javascripterrors");
    String pageErrorsFM = request.getParameter("javascripterrors");
    String fireFoxIssueStackTraces = request.getParameter("javascripterrors");
    String stackTraces = request.getParameter("javascriptfunstack");

    if(!FormatHelper.hasContent(stackTraces)){
        pageErrors = "";
        stackTraces = fireFoxIssueStackTraces;
    }

    String dumpString = "";
    String dumpStringFM = "";

       String stats = "";
        String stackTrace = "";

        stats += "Date-Time:\t" + new Date().toString() + "\n";
        stats += "User:\t" + lcsContext.getUserName() + "\n";
        stats += "System:\t" + systemName + "\n";
        stats += "User Groups:\t" + lcsContext.getGroups() + "\n";
        stats += "IP:\t" + request.getRemoteAddr() + "\n";

        if(getRemoteHost){ 
          stats += "Host:\t" + request.getRemoteHost()+ "\n";
        }else{
          stats += "Host:\t" + request.getRemoteAddr()+ "\n";
        }

        pagehref = request.getRemoteAddr();


        stats += "Activity:\t" + request.getParameter("activity") + "\n";
        stats += "Action:\t" + request.getParameter("action") + "\n";

        pageErrorsFM += "\n" + stats;
        pageErrors += "<br>" + FormatHelper.replaceCharacter(pageErrorsFM,"\n","<br>");

        Hashtable requestDump = RequestHelper.hashRequest(request);
        Iterator keys = requestDump.keySet().iterator();
        String key;
 

    // on any Throwable page can do
    if(currentException != null){
        if(currentException instanceof wt.util.WTException){
            WTException wtException = (WTException) currentException;
            Throwable throwable = wtException.getNestedThrowable();
            if(throwable != null){
                currentException = (Throwable) throwable;
            }
        }
        if(currentException instanceof wt.util.WTRemoteException){
            WTRemoteException wtRemException = (WTRemoteException) currentException;
            Throwable throwable = wtRemException.getNestedThrowable();
            if(throwable != null){
                currentException = (Throwable) throwable;
            }
        }
        if(currentException instanceof java.rmi.ServerRuntimeException){
            java.rmi.ServerRuntimeException runTime = (java.rmi.ServerRuntimeException) currentException;
            Throwable throwable = runTime.detail;

            if(throwable != null){
                currentException = (Throwable) throwable;
            }
        }
 

        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        currentException.printStackTrace(pw);
        if(currentException != null && currentException.getCause() != null){
	    	pw.println("---++++----");
	        Throwable tempT = currentException;
	        while(tempT != null && tempT.getCause() != null){
	        	tempT = tempT.getCause();
	        	pw.print("--Caused By:");
	        	 StackTraceElement[] ste = tempT.getStackTrace();
	        	 if(ste != null && ste.length > 0){
	        		 int len = ste.length;
	        		 for(int i = 0;i<len;i++){
	        		 	pw.print(ste[i] + "-->");
	        		 }
	        	 }
	        	 pw.println("");
	        }
        }
        stackTrace = sw.toString();


         while(keys.hasNext()){
            key = (String) keys.next();
            dumpString += key + ":   " + requestDump.get(key) + "\n";
        }
       
        stackTraces = "Stack Trace:\n" + stackTrace ;
        dumpString = "Request Dump: \n" + dumpString;


        LCSErrorLog.logRequest(request,stackTrace);
    }else{

        while(keys.hasNext()){
            key = (String) keys.next();
            if(!key.equals("pagebodyB") && !key.equals("pagebodyA") && !key.equals("pagehref") && !key.equals("javascriptfunstack") && !key.equals("javascripterrors")){
                dumpString += key + ":   " + requestDump.get(key) + "\n";
            }
       }
        dumpString = "Request Dump: \n" + dumpString;

    }

%>


<%if(!GENERIC_EXCEPTIONS){%>

<html>
<title>--- <%=errorReport_errorOccured%> ---</title>
<head>
<link href="<%=URL_CONTEXT +CSS_FILE%>" rel="stylesheet">
</head>

<table width="100%">
    <tr>
        <td class="PAGEHEADING">
            <table width="100%" cellspacing="0" cellpadding="0">
                <tr>
					<td >
					</td>
					<td width="1%" nowrap>
						<br>
					   <a class="button" href="javascript:backCancel()"><%=returnButton %></a>
					</td>

                </tr>
				<tr>
                    <td class="ERROR">
					<%=genericMessageToUser%>
					<br>
					<br>
					<br>
					<br>
                        <% 
                         String exceptionDisplay = "";
                         if(currentException != null){%>
                            <%=ERROR_REPORT_MAIN%> &nbsp;
                         <%   exceptionDisplay = currentException.toString();
                         }else{
                            if(!FormatHelper.hasContent(exception.getClass().toString())){%>
                                <%=errorReport_jsErrorOccured%> &nbsp;                            
                            <%}else{
                            %>
                            <%exceptionDisplay= exception.getClass().toString();%>
                         <%
                              }
                         }%>
 

                    <%= exceptionDisplay %>
                    </td>


                </tr>
            </table>
        </td>
    </tr>


</table>


    <%= tg.startGroupBorder() %>
    <%= tg.startTable() %>
    <%= tg.startGroupTitle() %>

    <%String errorsMessage = "Error(s).";
    if(currentException != null || FormatHelper.hasContent(exception.getClass().toString())){
        errorsMessage = "Information.";
    } %>
        <%=errorsMessage%>
    
<br/><br/><%= tg.endTitle() %>
    <%= tg.startGroupContentTable() %>
    <col width="15%"></col><col width="35%"></col>
    <col width="15%"></col><col width="35%"></col>

		<table width="15%">
		<tr>
		<td >
<%=pageErrors%>
		</td>
		</tr>


	<%= tg.endContentTable() %>
    <%= tg.endTable() %>
    <%= tg.endBorder() %>





    <%= tg.startGroupBorder() %>
    <%= tg.startTable() %>
    <%= tg.startGroupTitle() %>

		<% 
		 String stackTraceDisplay = "";
		 if(currentException != null){
		%>

		   <%=errorReport_errorStackTrace%> &nbsp;

		<%
			stackTraceDisplay = currentException.toString();
		 }else{
			if(!FormatHelper.hasContent(exception.getClass().toString())){
		%>
			<%=errorReport_JSMerrorStackTrace%> &nbsp;
		
		<%      
			}else{
				stackTraceDisplay = exception.getClass().toString();
				stackTraces = FormatHelper.formatJavascriptString(exception.getMessage());
			}
		}
		%>

	<%= stackTraceDisplay %>

<br/><br/><%= tg.endTitle() %>
    <%= tg.startGroupContentTable() %>
    <col width="15%"></col><col width="35%"></col>
    <col width="15%"></col><col width="35%"></col>

		<table width="15%">
		<tr>
		<td >

<%
    stackTraces = FormatHelper.replaceCharacter(stackTraces, "\\n", "\n");
    stackTraces = FormatHelper.replaceCharacter(stackTraces, "\\r", "\r");    
    stackTraces = HTMLEncoder.encodeAndFormatForHTMLContent(stackTraces);
%>
<TEXTAREA NAME="stackTraces" ID="stackTraces" wrap="off" READONLY COLS=120 ROWS=15><%= stackTraces %></TEXTAREA>
		</td>
		</tr>


	<%= tg.endContentTable() %>
    <%= tg.endTable() %>
    <%= tg.endBorder() %>


<%if(FormatHelper.hasContent(dumpString)){%>
    <%= tg.startGroupBorder() %>
    <%= tg.startTable() %>
    <%= tg.startGroupTitle() %><%=errorReport_requestDump%><br/><br/><%= tg.endTitle() %>
    <%= tg.startGroupContentTable() %>
    <col width="15%"></col><col width="35%"></col>
    <col width="15%"></col><col width="35%"></col>

		<table width="15%">
		<tr>
		<td >
<TEXTAREA NAME="dumpString" ID="dumpString" wrap="off" READONLY COLS=120 ROWS=8><%= dumpString %></TEXTAREA>

		</td>
		</tr>


	<%= tg.endContentTable() %>
    <%= tg.endTable() %>
    <%= tg.endBorder() %>
<%}%>

    <%if(currentException == null && !FormatHelper.hasContent(exception.getClass().toString())){%>
    <%= tg.startGroupBorder() %>
    <%= tg.startTable() %>
    <%= tg.startGroupTitle() %><%=errorReport_htmlSource%><br/><br/><%= tg.endTitle() %>
    <%= tg.startGroupContentTable() %>
    <col width="15%"></col><col width="35%"></col>
    <col width="15%"></col><col width="35%"></col>

		<table width="15%">
		<tr>
		<td >
<%//=pagebodyA%>
<TEXTAREA NAME="pagebodyB" ID="pagebodyB" wrap="off" READONLY COLS=120 ROWS=6><%= pagebodyB %></TEXTAREA>
<%//STYLE="display:none" %>
<%//=pagebodyB%>
		</td>
		</tr>

 
	<%= tg.endContentTable() %>
    <%= tg.endTable() %>
    <%= tg.endBorder() %>
<%}

%>

<%}else{%>
<html>
<title>--- <%=errorReport_errorOccured%> ---</title>
<head>
<link href="<%=URL_CONTEXT +CSS_FILE%>" rel="stylesheet">

</head>
<table width="100%">
    <tr>
        <td class="PAGEHEADING">
            <table width="100%" cellspacing="0" cellpadding="0">
                <tr>
					<td >
					</td>
					<td width="1%" nowrap>
						<br>
					   <a class="button" href="javascript:backCancel()"><%=returnButton %></a>
					</td>

                </tr>
                <tr>
					<td class="ERROR">
						<br>
						<br>
						<br>
						<br>
							<center><%= errorMessageToUser %></center>
					</td>
                </tr>
            </table>
        </td>
    </tr>


</table>

<%}

	//Performing the JSP include serverside to keep the client from seeing the data in the soruce of the page (ie: errors)
	String url = subURLFolder+ PACKAGE_ERROR_PAGE + "?" + "stackTraces=" + stackTraces + "&dumpString=" + dumpString + "&pagebodyB=" + pagebodyB + "&pageErrors=" + pageErrors  ;
	request.getRequestDispatcher(url).include(request, response);

	//need to print out the stack still so that gets reported in tomcat logs.
	//System.out.println(stackTraces);

%>

			