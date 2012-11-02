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
				java.text.SimpleDateFormat,
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
    private static boolean EMAIL_ENABLED = LCSProperties.getBoolean("jsp.exception.EmailErrors.enabled");
    private static boolean RemoveFromUserInTo = LCSProperties.getBoolean("jsp.exception.EmailErrors.RemoveFROMUser");
    private static boolean PACKAGE_ERROR_ENABLED = LCSProperties.getBoolean("jsp.exception.PackageErrors.enabled");


	public static final String UsersGroupsToSendExceptionsTo = LCSProperties.get("jsp.exception.UsersGroupsToSendExceptionsTo", "U:Administrator");

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
String errorReport_JSMerrorStackTrace = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_JSMerrorStackTrace", objA ) ;
String errorReport_errorStackTrace = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_errorStackTrace", objA ) ;
String errorReport_requestDump = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_requestDump", objA ) ;
String errorReport_htmlSource = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_htmlSource", objA ) ;

String genericMessageToUser = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_genericEmailMessage", objA ) ;
String errorReport_messageSubject = WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_messageSubject", objA ) ;



%>

<%
    String pagebodyB = request.getParameter("pagebodyB");
    String pageErrors = request.getParameter("pageErrors");
    String stackTraces = request.getParameter("stackTraces");
    String dumpString = request.getParameter("dumpString");
%>


<%

//Gather Files, create Zip section
		String FILE_SEPARATOR = File.separator;

		String zipFileLocation = FormatHelper.formatOSFolderLocation(supportPackageSaveLocation);
        String timeToLive = LCSProperties.get("jsp.exception.SupportPackageLocation.PurgeTimeFrame", "7");
        boolean purgeEnabled = LCSProperties.getBoolean("jsp.exception.SupportPackageLocation.PurgeEnabled");

        String zipFileLocationTempDir = "" ;
        boolean dirCreated = false;
        boolean checkDir = false;
		java.util.Date date = new java.util.Date();
		SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddhhmmss");
		String userName = "-";
		try{
			userName = lcsContext.getUser().getName().toString();
		}catch(wt.util.WTException wte){
			wte.printStackTrace();
		}

        String uniqueName = userName + "_" + formatter.format(date);

        String uniquefolder = zipFileLocation;

		if(PACKAGE_ERROR_ENABLED){
			checkDir = new File(zipFileLocation + FILE_SEPARATOR + uniqueName).exists();


			//Check if directory exists and if does then need to make unique before creating
			if(checkDir){
				int uniqueNumber = 0;
				String temp = uniqueName;
				while(checkDir){
					uniqueNumber = uniqueNumber + 1;

				temp = FILE_SEPARATOR + uniqueName + uniqueNumber;
				checkDir = new File(zipFileLocation + temp).exists();
				uniquefolder = zipFileLocation + temp;
				}
				dirCreated = new File(zipFileLocation + temp).mkdirs();
				zipFileLocationTempDir = zipFileLocation + temp;

			}else{
				dirCreated = new File(zipFileLocation + FILE_SEPARATOR + uniqueName).mkdirs();
				zipFileLocationTempDir = zipFileLocation + FILE_SEPARATOR + uniqueName;
				uniquefolder = zipFileLocation + FILE_SEPARATOR + uniqueName;
			}

			//If directory created then need to zip up all contents within it then create zip file and delete the directory after
			if (dirCreated) {
				boolean checkFile = new File(zipFileLocation + FILE_SEPARATOR + uniqueName + ".zip").exists();

				if(checkFile){
					int uniqueNumber = 0;
					String temp = uniqueName;

					while(checkFile){
					uniqueNumber = uniqueNumber + 1;
					temp = (uniqueName + uniqueNumber).toString();
					checkFile = new File(zipFileLocation + temp + ".zip").exists();
					}
					uniqueName = temp + ".zip";
				}else{
					uniqueName = uniqueName + ".zip";
				}


				try {

						BufferedWriter bw = null;
						if(FormatHelper.hasContent(stackTraces)){
							bw = new BufferedWriter(new FileWriter(uniquefolder + FILE_SEPARATOR + "StackTraceOutput.txt"));
							bw.write(stackTraces);
							bw.close();
						}
						if(FormatHelper.hasContent(dumpString)){
							bw = new BufferedWriter(new FileWriter(uniquefolder + FILE_SEPARATOR + "RequestDumpOutput.txt"));
							bw.write(dumpString);
							bw.close();
						}
						if(FormatHelper.hasContent(pageErrors)){
							bw = new BufferedWriter(new FileWriter(uniquefolder + FILE_SEPARATOR + "RequestInformation.txt"));
							bw.write(serverName);
							bw.newLine();
							while(pageErrors.indexOf("<br>") > -1){
								pageErrors = FormatHelper.replaceString(pageErrors, "<br>", "\r");
							}
							bw.write(pageErrors);
							bw.close();
						}
						if(FormatHelper.hasContent(pagebodyB)){
							bw = new BufferedWriter(new FileWriter(uniquefolder + FILE_SEPARATOR + "UserErrorPage.html"));
							bw.write(pagebodyB);
							bw.close();
						}     

						//capture version information
						bw = new BufferedWriter(new FileWriter(uniquefolder + FILE_SEPARATOR + "ServerAndClientInfo.txt"));
						bw.write(WindchillVersionHelper.getInstalledAssemblyReleaseIdsAndLabelsAsString());
						bw.write(WindchillVersionHelper.getInstalledTempPatchesAsString());
						bw.write(WindchillVersionHelper.getInstalledLocalesAsString());
						bw.write("\r");
						bw.write("Client Browser Information:");
						bw.write("\r");

						bw.write((String)request.getHeader("User-Agent"));
						bw.close();

					} catch (IOException e) {
						System.out.println("Error writing to file " + e);
					}

				 try{ //read in what files to add to the support package in addition to the exception files created during this process
					ZipHelper zh = new ZipHelper(zipFileLocation + FILE_SEPARATOR + uniqueName, zipFileLocationTempDir);
					FileReader fr = new FileReader(wt_home + FILE_SEPARATOR + FormatHelper.formatOSFolderLocation("codebase/rfa/jsp/exception/ExceptionPackageFileList.properties") );
					String additionalProps = LCSProperties.get("com.lcs.wc.util.LCSProperties.additionalProperties");

					BufferedReader br = new BufferedReader(fr);
					String currentLine = " ";

					if(br != null){
						while(currentLine != null){
							currentLine = br.readLine() ;
							if(currentLine == null){
								continue;
							}

							if((currentLine != "" || currentLine != " ") && ! currentLine.startsWith("#")){
								String fileToInclude = FormatHelper.formatOSFolderLocation(currentLine);
								if(FormatHelper.hasContent(fileToInclude) && new File(wt_home + FILE_SEPARATOR + fileToInclude).exists()){
									zh.addFile(wt_home + FILE_SEPARATOR + fileToInclude);
								}
								
							}
						}
					}

					StringTokenizer st = new StringTokenizer(additionalProps, ",");
					while(st.hasMoreTokens()){
						String additonalPropertyFile = wt_home + FILE_SEPARATOR + "codebase" ;
						String FileName = FormatHelper.formatOSFolderLocation(st.nextToken());
						additonalPropertyFile += FileName;
							if(new File(additonalPropertyFile).exists() && (FileName.indexOf("secure") == -1)){
								zh.addFile(additonalPropertyFile);
							}
					}

					zh.zip();

				 }catch(Exception e){
					 System.out.println("Error zipping folder " + e);
				 }
				DeleteFileHelper dFH = new DeleteFileHelper();
				File uniqueFolderFile = new File(uniquefolder);
				dFH.deleteDir(uniqueFolderFile);

				if(purgeEnabled){
					dFH.deleteOldFiles(zipFileLocation,timeToLive);
				}
			 }
		}


//Email Section
           if(EMAIL_ENABLED && PACKAGE_ERROR_ENABLED){
				EmailHelper eH = new EmailHelper();


                 try{

                        Vector to = new java.util.Vector();

                        wt.org.WTUser from = UserGroupHelper.getWTUser(lcsContext.getContext().getUser().getName().toString());
						if(!RemoveFromUserInTo){
							to.addElement(from); //force from user to be a to user as well so both user and admin groups get an email about the exception
						}

						StringTokenizer wtprincipals = new StringTokenizer(UsersGroupsToSendExceptionsTo, ",");
						while(wtprincipals.hasMoreTokens()){
							String wtprincipalString = wtprincipals.nextToken();

							if(wtprincipalString.startsWith("U:")){
								to.addElement(UserGroupHelper.getWTUser(wtprincipalString.substring(2,wtprincipalString.length()))); 
							}else if(wtprincipalString.startsWith("G:")){

								try{
									Collection groupMembers = UserCache.getGroupUsers(wtprincipalString.substring(2,wtprincipalString.length())); //Get groups memembers so can drill down

									FlexObject obj = null;
									Iterator iter = groupMembers.iterator();
									
									while(iter.hasNext()){

										try{
											obj = (FlexObject) iter.next();
											String emailAddress = obj.getString("email");
											//Confirm has a email, and is valid
											if(FormatHelper.hasContent(emailAddress) && eH.isValidEmailAddress(emailAddress)){
												to.addElement(UserGroupHelper.getWTUser(obj.getString("Name"))); 
											}else{
												System.out.println("---- Email address for user:" + obj.getString("Name") + " is invalid so not including in email To: list <" + emailAddress + ">.");
											}
										}catch(Exception e){
											//System.out.println("No Group Members");
										}
									}

								}catch(Exception e){
									//System.out.println("GROUP was empty so no users were found " + e);
								}
							}
						}

						
						Object[] emailBodyObj = {uniqueName}; //This was setup to have possibly other information in the email body.

                        String body = ("<br /> <br /> <pre>" +  WTMessage.getLocalizedMessage ( ERROR_REPORT_MAIN, "errorReport_messageBody", emailBodyObj ) + "</pre>");

                        String subject = (errorReport_messageSubject + systemName);
						try{
							to = new Vector(new LinkedHashSet(to)); //Remove any duplicates from to: addresses
							eH.sendMail(to,from,body,subject);
							eH.send();
						}catch(Exception e){
							//An Error occured when trying to create or send email
						}

                 }catch(Throwable e){
                        e.printStackTrace();
                 }

           }




%>