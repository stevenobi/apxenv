"@REM oad.cmd"  
  
@REM ---------------------------------------------------------------------
@REM odev.bat
@echo off
setlocal enableextensions
@REM =====================================================================
@REM script variables
set _SCRIPT=%~n0
set _SCRIPTNAME=%0
set _SCRIPT_BANNER="------------   SPM - Software Project Maker 2023 ------------"
@REM =====================================================================
@REM @echo Params "%*"
@REM =====================================================================
@REM check mandatory parameter
if "[%*]"=="[]" (
   @echo. & @echo Usage: %_SCRIPT% ^(options^) ^[params^]
   @echo Type %_SCRIPT% -h for more information.
   endlocal
   exit /b)

@REM =====================================================================
@REM script variables

@REM Folders
set _SCRIPTDIR=%~dp0
set _ARCDIR=%_SCRIPTDIR%arc
set _BLDDIR=%_SCRIPTDIR%bld
set _DOCDIR=%_SCRIPTDIR%doc
set _LIBDIR=%_SCRIPTDIR%lib
set _LOGDIR=%_SCRIPTDIR%log
set _SRCDIR=%_SCRIPTDIR%src
set _TMPDIR=%_SCRIPTDIR%tmp

@REM Subfolders
set _SCRIPT_SUBFOLDERS=arc,arc\builds,arc\sources,arc\documents,bld,doc,lib,log,src,tmp

@REM Files and gitignores
set _GITIGNORE=.gitignore
set _CURRENT_PROJECT_FILE=_current_project
set _LOGFILE=%_SCRIPT%.log

set _READMETXT=README.txt
set _HTDOCMD=README.md
set _HELPTXT=%_SCRIPT%_help.txt

@REM full qualified filenames
set _README=%_SCRIPTDIR%%_READMETXT%
set _HTDOC=%_DOCDIR%\%_HTDOCMD%
set _HELP_FILE=%_DOCDIR%\%_HELPTXT%
set _LOG_FILE=%_LOGDIR%\%_LOGFILE%

set _SCRIPT_GITIGNORE_OBJETCS=%_CURRENT_PROJECT_FILE%,arc,log,tmp

@REM Scripts
set _INI=%_SCRIPTDIR%%_SCRIPT%.ini
set _UTILS=%_SCRIPTDIR%%_SCRIPT%utl.cmd
set _MACROS=%_SCRIPTDIR%%_SCRIPT%mac.cmd
set _DEFAULTS=%_SCRIPTDIR%%_SCRIPT%def.cmd
set _FUNCTIONS=%_SCRIPTDIR%%_SCRIPT%fnc.cmd

@REM Settings
set "LogLevels[OFF]=0"
set "LogLevels[INFO]=1"
set "LogLevels[DEBUG]=2"
set "LogLevels[TRACE]=3"

set "LogSeverities[0]=OFF"
set "LogSeverities[1]=INFO"
set "LogSeverities[2]=DEBUG"
set "LogSeverities[3]=TRACE"

@REM Values
set "_TRUE_VALS=TRUE,true,YES,yes,Y,y,0"
set "_FALSE_VALS=FALSE,false,NO,no,N,n,1"

@REM =====================================================================
@REM script defaults

@REM =====================================================================
@REM calling macros
call %_MACROS%


@REM =====================================================================
@REM calling defaults
call %_DEFAULTS%

@REM =====================================================================
@REM Initialize
call :_log_debug %_line% "BOTH"
call :_log_debug "%_SCRIPT_BANNER%" "BOTH"
call :_log_debug %_line% "BOTH"
call :_log_debug "Initializing %_SCRIPT%..."
call :_log_trace %_line%
call :_log_trace "Script: %_SCRIPT%"
call :_log_trace "Script Current Parameter: %*"
call :_log_trace "Script Log Mode: %_LOG_MODE%"
call :_log_trace "Script Ini File: %_INI%"
call :_log_trace "Script Log File: %_LOG_FILE%"
call :_log_trace "Script Help File: %_HELP_FILE%"
call :_log_trace "Script Util File: %_UTILS%"
call :_log_trace "Script Macros File: %_MACROS%"
call :_log_trace "Script Defaults File: %_DEFAULTS%"
call :_log_trace "Script Functions File: %_FUNCTIONS%"

@REM =====================================================================
@REM calling INI
call :_log_debug "%_SCRIPT%: Reading INI File: %_INI%"
for /f "tokens=1* delims==" %%a in ('type %_INI%^|findstr /V /R "^;.*" ') do (
    call set "%%a=%%b"
    )

@REM =====================================================================
@REM calling Current Project
if exist %_SCRIPTDIR%%_CURRENT_PROJECT_FILE% (
   call :_log_debug %_line%
   call :_log_debug "%_SCRIPT%: Setting Project from %_CURRENT_PROJECT_FILE%"
   for /f "tokens=1* delims==" %%a in ('type %_SCRIPTDIR%%_CURRENT_PROJECT_FILE%') do (
      call set "%%a=%%b"
      )
)
if exist %_SCRIPTDIR%%_CURRENT_PROJECT_FILE% (
   if not [%_PROJECT%]==[] (
      call :_log_debug "%_SCRIPT%: Current Project is: %_PROJECT%"
   ) else (
      call :_log_warning "%_SCRIPT%: No Project set."
   )
)

@REM =====================================================================
@REM Setting Log Level
@REM (ini directive: _LOG_LEVEL)
call :_set-log-level %_LOG_LEVEL%

@REM =====================================================================
@REM create missing files and folders
@REM (ini directives: _CREATE_IF_NOT_EXISTS and _CREATE_GITIGNORE)
call :_make_gitignore "%_SCRIPTDIR%%_GITIGNORE%" "%_SCRIPT_GITIGNORE_OBJETCS%"
call :_create_project_folders "%_SCRIPTDIR%" "%_SCRIPT_SUBFOLDERS%"

@REM =====================================================================
@REM make Help Files and README if not exist
@REM (def directives: _CREATE_README, _CREATE_HTDOC, _CREATE_HELP)
call :_make_helpfiles "%_SCRIPT%" "%_README%" "%_HTDOC%" "%_HELP_FILE%"


@REM =====================================================================
@REM call arg parser
call :_log_debug %_line% "BOTH"
call :_log_debug "%_SCRIPT%: Running Parse Arguments" "BOTH"
call :parse_args %*

@REM =====================================================================
@REM --- process results and set runtime variables by options and params

@REM =====================================================================
@REM set encoding and codepage
SET NLS_LANG=%_ENCODING%
chcp %_CODEPAGE%>nul
call :_log_trace "%_SCRIPT%: Encoding: %NLS_LANG% - Codepage: %_CODEPAGE%"
call :_log_debug %_line% "BOTH"

@REM =====================================================================
@REM display help and exit
if exist "%_HELP_FILE%" (
   if "%_DISPLAY_HELP%" == "Y" (
      call :_help
      goto:eof
      )
) else (
   call :_log_warning "%_SCRIPT%: No Help found."
   goto:eof
)

@REM =====================================================================
@REM setting log_level again
@REM (ini directive: _LOG_LEVEL can be modified by -d and -t option)
call :_set-log-level "%_LOG_LEVEL%"
call :_log_debug "%_line%" "BOTH"
call :_log_debug "%_SCRIPT%: Setting Log Level %_LOG_LEVEL%..." "BOTH"

@REM =====================================================================
@REM set options and defaults
@REM =====================================================================
@REM trace call after parse args
call :_log_trace "%_line%"
call :_log_trace "%_SCRIPT%: Script Parameter: _PARAM=%_PARAM%"

@REM =====================================================================
@REM initialize log
call :_log_info %_line% "BOTH"
call :_log_info %_SCRIPT_BANNER% "BOTH"
call :_log_info %_line% "BOTH"

@REM =====================================================================
@REM CONFIG
:_CONF
if not "%_PARAM%"=="CONFIG" goto:_MAKE

@REM valid config options for script
set "_CONFIG_OPTIONS=set-project,sp,set-ticket,st,sl,set-log-level,set-keep-files,sk,set-create-if-not-exist,sce"
set "_KEEP_VALS=ARCHIVE,archive,ALL,all,N,NONE,n,none,MOVE,move,COPY,copy"

@REM modify config options
set _OPT_VAL=%_OPTION_VALUE:"=%
set _OPT_VAL=%_OPT_VAL::=%
set _OPT_VAL=%_OPT_VAL:+=%

call :_log_trace "%_SCRIPT%: _OPTION_VALUE=%_OPTION_VALUE% _OPT_VAL="%_OPT_VAL%""

if "%_OPT_VAL%."=="." (
   call :_log_info  "%_SCRIPT%: Usage: %_SCRIPT% [-c config] [/opt1 value (/opt2 value /opt3 value...)])."
   call :_log_debug "%_SCRIPT%: Config Options: %_CONFIG_OPTIONS%"
   call :_log_error "%_SCRIPT%: Parameter: %_PARAM% No Option provided..."
   goto:eof
   ) else (
      @REM Option provided, so check it
      call :_log_debug "%_SCRIPT%: Parameter: %_PARAM% Checking Options..."
      call :_parse_config_options "%_OPTION_VALUE%" _PROJECT _TICKET _KEEP_FILES _CREATE_IF_NOT_EXISTS _LOG_LEVEL
   )
   if %ERRORLEVEL% GTR 0 (
      call :_log_error "%_SCRIPT%: Parameter "%_PARAM%" returned with errors. Ckeck your inputs..." %ERRORLEVEL%
      call :_log_error %_line%
      goto:eof
      )

if not [%_PROJECT%]==[] (
   call :_log_info "%_SCRIPT%: Project configured: %_PROJECT%" "BOTH"
   call :_log_debug "%_SCRIPT%: _PROJECT_ROOT=%_PROJECT_ROOT%"
   call :_write_project_conf %_PROJECT%
   )

@REM Directories based on _PROJECT_ROOT
set "_PROJECT_FOLDER=%_PROJECT_ROOT%\%_PROJECT_FOLDER_PREFIX%%_PROJECT%\"
set _PRJDOC=%_PROJECT_FOLDER%%_PROJECT_DOC_DIR%

@REM Project Doc Directory
call :_log_debug "%_SCRIPT%: _PRJDOC=%_PRJDOC%"

if exist %_PROJECT_FOLDER% (
   call :_log_info "%_SCRIPT%: Project Folder %_PROJECT_FOLDER% exists." "BOTH"
   call :_make_project_subfolders "%_PROJECT_FOLDER%" "%_PROJECT_SUBFOLDERS%"
   call :_make_helpfiles "%_PROJECT%" "%_PROJECT_FOLDER%\%_READMETXT%" "%_PRJDOC%\%_HTDOCMD%" "%_PRJDOC%\%_HELPTXT%"
   )

@REM set subfolder variables (excluding sub-subfolders)
for %%g in (%_PROJECT_SUBFOLDERS%) do (
   setlocal enabledelayedexpansion
   for /f "tokens=*" %%y in ('@echo %%g^|findstr /V /R "^.*\\.*$"') do (
      call set "_PROJECT_%%y_DIR=%_PROJECT_FOLDER%%%y"
      call :_log_trace "%_SCRIPT%: Setting _PROJECT_%%y_DIR=%%y"
   )
)
endlocal

@REM Check if Ticket is set
if [%_TICKET%]==[] (
   if not [%_PROJECT%]==[] (
         call :_log_info "%_SCRIPT%: Ticket NOT set. Try setting it from Project name." "BOTH"
         call :_log_debug "%_SCRIPT%: PROJECT_KEYS=%_PROJECT_KEYS:"=%"
         call :_get-ticket-from-project %_PROJECT_KEYS% "%_PROJECT%"
      )
   )

if not [%_TICKET%]==[] (
   call :_log_info "%_SCRIPT%: Ticket set: %_TICKET%" "BOTH"
) else (
   call :_log_warning "%_SCRIPT%: Ticket not set. GIT functionality will not be available." "BOTH"
)

@REM Script Option Processing (only visible in DEBUG mode)

@REM Log Level
:_LOGLEV
if [%_LOG_LEVEL%]==[] goto :_KEEPFILES
call :_log_debug "%_SCRIPT%: Option LOG_LEVEL set: %_LOG_LEVEL%"

@REM check KEEP_FILES
:_KEEPFILES
if [%_KEEP_FILES%]==[] goto:_CINE
call :_check_option_value "%_KEEP_FILES%" "%_KEEP_VALS%" _NOTFOUND
   if "%_NOTFOUND%" NEQ "0" (
      call :_log_error "%_SCRIPT%: Invalid KEEP_FILES Value: %_KEEP_FILES%" & goto:eof
      ) else (
         call :_log_debug "%_SCRIPT%: Option KEEP_FILES set: %_KEEP_FILES%"
      )

@REM check CreateIfNotExists
:_CINE
if [%_CREATE_IF_NOT_EXISTS%]==[] goto :EOF_CONFIG
call :_check_option_value "%_CREATE_IF_NOT_EXISTS%" "%_TRUE_VALS%" _NOTFOUND
   if "%_NOTFOUND%" NEQ "0" (
      call :_log_error "%_SCRIPT%: Invalid CREATE_IF_NOT_EXISTS Value: %_CREATE_IF_NOT_EXISTS%" & goto:eof
      ) else (
         call :_log_debug "%_SCRIPT%: Option CREATE_FOLDER_IF_NOT_EXISTS set: %_CREATE_IF_NOT_EXISTS%"
      )

@REM EOF Config
:EOF_CONFIG

@REM =====================================================================
@REM MAKE
:_MAKE
if not "%_PARAM%"=="MAKE" goto:_RUN

@REM valid make options for script
set "_MAKE_OPTIONS=project,p,build,b,install,i,clean,c"
set _MAKE_OPT_ARG=

call :_log_trace "%_SCRIPT%: %_PARAM% _MAKE_WHAT=%_MAKE_WHAT% _MAKE_VALUE=%_MAKE_VALUE% _MAKE_OPT_ARG=%_MAKE_OPT_ARG%"

if [%_MAKE_VALUE%]==[] (
   call :_log_info  "%_SCRIPT%: Usage: %_SCRIPT% [-m make] [/opt1 value (/opt2 value /opt3 value...)])."
   call :_log_debug "%_SCRIPT%: MAKE Options: %_MAKE_OPTIONS%"
   call :_log_error "%_SCRIPT%: Parameter: %_PARAM% no Value provided for Option %_MAKE_WHAT%..."
   goto:eof
   ) else (
      @REM Option provided, so check it
      call :_log_debug "%_SCRIPT%: Parameter: %_PARAM% Checking Option %_MAKE_WHAT%..."
      call :_parse_make_options "%_MAKE_WHAT%" "%_MAKE_OPTIONS%"
   )
   if %ERRORLEVEL% GTR 0 (
      call :_log_error "%_SCRIPT%: Parameter "%_PARAM%" returned with errors. Ckeck your inputs..." %ERRORLEVEL%
      call :_log_error %_line%
      set _MAKE_OPT_ARG=
      goto:eof
      )

@REM determine what to make
call :_log_info "%_SCRIPT%: MAKE Option: %_MAKE_WHAT% Value: %_MAKE_VALUE% %_MAKE_OPT_ARG%"

if "%_MAKE_WHAT%" == "project" goto:_PROJ
if "%_MAKE_WHAT%" == "p" goto:_PROJ

if "%_MAKE_WHAT%" == "build" goto:_BUILD
if "%_MAKE_WHAT%" == "b" goto:_BUILD

if "%_MAKE_WHAT%" == "install" goto:_INSTALL
if "%_MAKE_WHAT%" == "i" goto:_INSTALL
goto :_RUN

:_PROJ
call :_log_info "%_SCRIPT%: Making %_MAKE_WHAT%: %_MAKE_VALUE% %_MAKE_OPT_ARG%"
call :_log_info %_line%%

@REM =====================================================================
@REM Your great Project here
@REM =====================================================================

@REM Directories based on _MAKE_VALUE
SET "_PROJECT_FOLDER=%_PROJECT_ROOT%\%_PROJECT_FOLDER_PREFIX%%_MAKE_VALUE%\"
set _PRJDOC=%_PROJECT_FOLDER%%_PROJECT_DOC_DIR%
call :_log_debug "%_SCRIPT%: Project Documents: %_PRJDOC%"

if not exist %_PROJECT_FOLDER% (
   call :_log_info "%_SCRIPT%: Making Project Folder %_PROJECT_FOLDER%..."
   call :_make_folder %_PROJECT_FOLDER% && call :_log_info "%_SCRIPT%: Done..."
   goto :_MAKE_SUBFOLDERS
   )

@REM @echo _MAKE_OPT_ARG=%_MAKE_OPT_ARG%

if exist %_PROJECT_FOLDER% (
   if not ["%_MAKE_OPT_ARG%"]==["clean"] (
     call :_log_error "%_SCRIPT%: Project Folder %_PROJECT_FOLDER% exists."
     call :_log_error "%_SCRIPT%: Consider renaming your Project..." && %_ex_error%
   )
)

:_MAKE_SUBFOLDERS
if exist %_PROJECT_FOLDER% (
   call :_make_project_subfolders "%_PROJECT_FOLDER%" "%_PROJECT_SUBFOLDERS%"
   call :_make_helpfiles "%_PROJECT%" "%_PROJECT_FOLDER%\%_READMETXT%" "%_PRJDOC%\%_HTDOCMD%" "%_PRJDOC%\%_HELPTXT%"
   )

goto:_RUN

:_BUILD
call :_log_info "%_SCRIPT%: Making %_MAKE_WHAT%: %_MAKE_VALUE% %_MAKE_CLEAN%"
@REM Your great Build Script here
goto:_RUN

:_INSTALL
call :_log_info "%_SCRIPT%: Making %_MAKE_WHAT%: %_MAKE_VALUE% %_MAKE_CLEAN%"
@REM Your great Install Script here
goto :_RUN


@REM =====================================================================
@REM RUN
:_RUN
if not "%_PARAM%"=="RUN" goto:_GET
if "%_PARAM%"=="MAKE" (
   call :_log_info "%_SCRIPT%: Parameter: %_PARAM% Checking Options..."
   call :_log_info "%_SCRIPT%: no %_PARAM% options currently supported..."
)


@REM =====================================================================
@REM GET / SHOW Parameters and Options
:_GET
if not "%_PARAM%"=="GET" goto:_continue
if "%_PARAM%"=="GET" (
   call :_log_info "%_SCRIPT%: Parameter: %_PARAM% Checking Options..."
   call :_log_info "%_SCRIPT%: no %_PARAM% options currently supported..."
)


@REM =====================================================================
@REM End of Params and Options
@REM =====================================================================
@REM trace call after config
call :_log_trace %_line%
call :_log_trace "Script Variables: _KEEP_FILES=%_KEEP_FILES%"
call :_log_trace "Script Variables: _CREATE_IF_NOT_EXISTS=%_CREATE_IF_NOT_EXISTS%"
call :_log_trace "Runtime Variables: _DEBUG=%_DEBUG%, _DISPLAY_HELP=%_DISPLAY_HELP%"
@REM debug call
call :_log_debug %_line%
call :_log_debug "Current Project: %_PROJECT%" "BOTH"
call :_log_debug "Project Conf: %_PROJECT_CONF%"
call :_log_debug "Project Root Folder: %_PROJECT_ROOT%"
call :_log_debug "Project Keys: %_PROJECT_KEYS:"=%"
call :_log_debug "Project Folder: %_PROJECT_FOLDER%"
call :_log_debug "Project Current Ticket: %_TICKET%"
call :_log_debug %_line%
call :_log_debug "Project Doc Directory=%_PROJECT_DOC_DIR%"
call :_log_debug "Project Log Directory=%_PROJECT_LOG_DIR%"
call :_log_debug "Project Temp Directory=%_PROJECT_TMP_DIR%"
call :_log_debug "Project Source Directory=%_PROJECT_SRC_DIR%"
call :_log_debug "Project Export Directory=%_PROJECT_EXP_DIR%"
call :_log_debug "Project Lib Directory=%_PROJECT_LIB_DIR%"


@REM =====================================================================
@REM continue, so emit one empty line first
@echo.


@REM =====================================================================
@REM all good so far, so...
:_continue
call :_log_info %_line% "BOTH"
call :_log_info "%_SCRIPT%: Starting %_SCRIPT%" "BOTH"

@REM =====================================================================
@REM processing
call :_log_info %_line% "BOTH"
call :_log_info "----- Processing" "BOTH"



call :_log_info %_line%
call :_log_info "Done %_SCRIPT% [%ERRORLEVEL%]" "BOTH"
call :_log_info %_line% "BOTH"

@REM =====================================================================
@REM Skip all SUB ROUTINES
goto:eof

@REM =====================================================================
@REM Function Parse Args (kept here, since script specific)
:parse_args

@REM help
if "%1" == "-h"              set "_DISPLAY_HELP=Y" && goto:eof
if "%1" == "-?"              set "_DISPLAY_HELP=Y" && goto:eof
if "%1" == "help"            set "_DISPLAY_HELP=Y" && goto:eof

@REM debug or trace as option (using LogLevels array)
if "%1" == "-d"              set "_LOG_LEVEL=%LogLevels[DEBUG]%"
if "%1" == "debug"           set "_LOG_LEVEL=%LogLevels[DEBUG]%"
if "%1" == "-t"              set "_LOG_LEVEL=%LogLevels[TRACE]%"
if "%1" == "trace"           set "_LOG_LEVEL=%LogLevels[TRACE]%"

@REM param RUN
if "%1" == "-r"              set "_PARAM=RUN" && set "_RUN_WHAT=%~2" && set "_RUN_VALUE=%~3"
if "%1" == "run"             set "_PARAM=RUN" && set "_RUN_WHAT=%~2" && set "_RUN_VALUE=%~3"

@REM param GET
if "%1" == "-g"              set "_PARAM=GET" && set "_GET_WHAT=%~2" && set "_GET_VALUE=%~3"
if "%1" == "get"             set "_PARAM=GET" && set "_GET_WHAT=%~2" && set "_GET_VALUE=%~3"
if "%1" == "-s"              set "_PARAM=GET" && set "_GET_WHAT=%~2" && set "_GET_VALUE=%~3"
if "%1" == "show"            set "_PARAM=GET" && set "_GET_WHAT=%~2" && set "_GET_VALUE=%~3"

@REM param CONFIG
if "%1" == "-c"              set "_PARAM=CONFIG" && set _OPTION_VALUE="%~2:%~3+%~4:%~5+%~6:%~7+%~8:%~9"
if "%1" == "config"          set "_PARAM=CONFIG" && set _OPTION_VALUE="%~2:%~3+%~4:%~5+%~6:%~7+%~8:%~9"

@REM param MAKE
if "%1" == "-m"              set "_PARAM=MAKE" && set "_MAKE_WHAT=%~2" && set "_MAKE_VALUE=%~3" && set "_MAKE_OPT_ARG=%~4"
if "%1" == "make"            set "_PARAM=MAKE" && set "_MAKE_WHAT=%~2" && set "_MAKE_VALUE=%~3" && set "_MAKE_OPT_ARG=%~4"

@REM EO Parse Args
shift
if "[%1]"=="[]" goto:eof
goto:parse_args


@REM ==========================================================================
@REM Subroutine Calls to %_FUNCTIONS% and %_UTILS% File

@REM ==========================================================================
@REM framework
:_parse_config_options
   %_FUNCTIONS% %*
   goto:eof

:_check_option_value
   %_FUNCTIONS% %*
   goto:eof

:_set_project
   %_FUNCTIONS% %*
   goto:eof

:_set_ticket
   %_FUNCTIONS% %1
   goto:eof

:_get-ticket-from-project
   %_FUNCTIONS% %1 %2
   goto:eof

:_parse_make_options
   %_FUNCTIONS% %*
   goto:eof

@REM ==========================================================================
@REM Project Conf (script directive: _CURRENT_PROJECT_FILE)
:_write_project_conf
if "%_CREATE_IF_NOT_EXISTS%"=="TRUE" (
   @echo _PROJECT=%~1>%_SCRIPTDIR%\%_CURRENT_PROJECT_FILE%
)
goto:eof

@REM ==========================================================================
@REM (ini directives: _CREATE_GITIGNORE for this script)
:_make_gitignore
if "%_CREATE_IF_NOT_EXISTS%"=="TRUE" (
   if not exist %~1 (
      if "%_CREATE_GITIGNORE%"=="TRUE" (
         call :_log_info %_line%
         call :_log_info "%_SCRIPT%: Making File %~1"
         call :_make_file "%~1"
         @echo.>"%~1"
         call :_write_gitignore "%~1" "%~2"
      )
   )
)
goto:eof

@REM ==========================================================================
@REM (ini directives: _PROJECT_SUBFOLDERS and _CREATE_GITIGNORE)
:_write_gitignore
if exist %~1 (
   call :_log_debug "%_SCRIPT%: Writing Defaults [%~2] to File %~1"
   for %%g in (%~2) do (
      @echo.%%g>>"%~1"
   )
   ATTRIB +H "%~1"
)
goto:eof

@REM ==========================================================================
@REM (ini directives: _PROJECT_SUBFOLDERS and _CREATE_GITIGNORE)
:_create_project_folders
if "%_CREATE_IF_NOT_EXISTS%"=="TRUE" (
   for %%g in (%~2) do (
      if not exist %~1%%g (
         call :_log_info "%_SCRIPT%: Making Directory %~1%%g"
         call :_make_folder %~1%%g
         if "%_CREATE_GITIGNORE%"=="TRUE" (
            call :_log_info "%_SCRIPT%: Making File %~1%%g\%_GITIGNORE%"
            call :_make_file %~1%%g\%_GITIGNORE% && (
               ATTRIB +H %~1%%g\%_GITIGNORE%
            )
         )
      )
   )
)
goto:eof

:_make_project_subfolders
setlocal
set _PRJ_FLDR=%~1
set _PRJ_SUBFLDRS=%~2
call :_log_debug "%_SCRIPT%: Checking PROJECT_FOLDERs .gitignore..."
call :_make_gitignore "%_PRJ_FLDR%%_GITIGNORE%" "%_GITIGNORE_OBJECTS%"
call :_log_debug "%_SCRIPT%: Checking PROJECT_FOLDERs subfolders..."
call :_create_project_folders "%_PRJ_FLDR%" "%_PRJ_SUBFLDRS%"
endlocal
goto:eof

@REM ==========================================================================
@REM utility functions
:_make_folder
   %_UTILS% %1
   goto:eof

:_make_file
   %_UTILS% %1
   goto:eof

:_make_help
   %_UTILS% %*
   goto:eof

:_make_readme
   %_UTILS% %*
   goto:eof

:_make_htdoc
   %_UTILS% %*
   goto:eof

@REM ==========================================================================
@REM help functions
:_usage
   %_FUNCTIONS% %_SCRIPT%
   goto:eof

:_help
   %_FUNCTIONS% %_HELP_FILE%
   goto:eof

@REM ==========================================================================
@REM helpfiles (defaults: _CREATE_README _CREATE_HTDOC _CREATE_HELP)
:_make_helpfiles
setlocal
set _CONTENT=%~1
set _README_FILE=%~2
set _HTDOC_FILE=%~3
set _HELPFILE=%~4
@REM Helpfile
if not exist "%_HELPFILE%" (
   if "%_CREATE_HELP%"=="TRUE" (
      call :_log_info "%_SCRIPT%: Making "%_HELPFILE%" file."
      call :_make_help %_HELPFILE% %_CONTENT%
   )
)
@REM Readme.txt
if not exist "%_README_FILE%" (
   if "%_CREATE_README%"=="TRUE" (
      call :_log_info "%_SCRIPT%: Making "%_README_FILE%" file."
      call :_make_readme %_README_FILE% %_CONTENT% %_HELPFILE% %_HTDOC_FILE%
   )
)
@REM Readme.md
if not exist "%_HTDOC_FILE%" (
   if "%_CREATE_HTDOC%"=="TRUE" (
      call :_log_info "%_SCRIPT%: Making "%_HTDOC_FILE%" file."
      call :_make_htdoc %_HTDOC_FILE% %_CONTENT% %_HELPFILE% %_README_FILE%
   )
)
endlocal
goto:eof

@REM ==========================================================================
@REM Logging
:_set-log-level
   %_FUNCTIONS% %1
   goto:eof

:_set-log-mode
   %_FUNCTIONS% %1
   goto:eof

:_log_info
   if not [%2]==[] (
      set _LOGMODE=%~2
   ) else (
      set _LOGMODE=%_LOG_MODE%
   )
   %_FUNCTIONS% "%_LOGMODE%" "%_LOG_FILE%" "%~1"
   set _LOGMODE=
   goto:eof

:_log_warning
   if not ["%2."]==["."] (
      set _LOGMODE=%~2
   ) else (
      set _LOGMODE=%_LOG_MODE%
   )
   %_FUNCTIONS% "%_LOGMODE%" "%_LOG_FILE%" "%~1"
   set _LOGMODE=
   goto:eof

:_log_trace
      if not ["%2."]==["."] (
      set _LOGMODE=%~2
   ) else (
      set _LOGMODE=%_LOG_MODE%
   )
   %_FUNCTIONS% "%_LOGMODE%" "%_LOG_FILE%" "%~1"
   set _LOGMODE=
   goto:eof

:_log_debug
   if not ["%2."]==["."] (
      set _LOGMODE=%~2
   ) else (
      set _LOGMODE=%_LOG_MODE%
   )
   @REM @echo "_LOGMODE=%_LOGMODE%"
   %_FUNCTIONS% "%_LOGMODE%" "%_LOG_FILE%" "%~1"
   set _LOGMODE=
   goto:eof

:_log_error
   if not ["%2."]==["."] (
      set _LOGMODE=%~2
   ) else (
      set _LOGMODE=%_LOG_MODE%
   )
   %_FUNCTIONS% "%_LOGMODE%" "%_LOG_FILE%" "%~1"
   set _LOGMODE=
   goto:eof

@REM ==========================================================================
@REM EOF
goto:eof

@REM ==========================================================================
@REM close script...
:EOF

@REM ==========================================================================
@REM return to previous directory
popd

endlocal
@REM exit /b %ERRORLEVEL%
%_ex% %ERRORLEVEL%
 
"@REM oadutl.cmd"  
  
@echo off
setlocal enableextensions

@REM ---------------------------------------------------------------------
@REM Utilities

@REM Not to be directly called
exit /b 9009

@REM basic help file
:_make_help
   @echo.>%~1
   @echo.Help for "%~2">>%~1
   @echo.>>%~1
   @echo.Description>>%~1
   @echo.more help will follow...>>%~1
   @echo.>>%~1
   @echo.Options>>%~1
   @echo.-h ^| help    show this help file.>>%~1
   @echo.>>%~1
   @echo.Parameters>>%~1
   @echo.>>%~1
   goto:eof

@REM basic readme file
:_make_readme
   @echo.>%~1
   @echo.Readme for "%~2">>%~1
   @echo.>>%~1
   @echo.Description>>%~1
   @echo.See: %~3>>%~1
   @echo.or %~4>>%~1
   @echo.for more information...>>%~1
   @echo.>>%~1
   @echo.EOF>>%~1
   @echo.>>%~1
   goto:eof

@REM basic markdown help file
:_make_htdoc
   @echo.>%~1
   @echo.# Help for "%~2">>%~1
   @echo.  >>%~1
   @echo.## Description>>%~1
   @echo.  >>%~1
   @echo.See %~3 or %~4 for more information...  >>%~1
   @echo.  >>%~1
   @echo.## Options>>%~1
   @echo.  >>%~1
   @echo.option1, option2...  >>%~1
   @echo.  >>%~1
   @echo.## Parameters>>%~1
   @echo.  >>%~1
   @echo.param1, param2...  >>%~1
   @echo.  >>%~1
   @echo.## Examples>>%~1
   @echo.  >>%~1
   @echo.example1, example2...  >>%~1
   @echo.  >>%~1
   goto:eof


:_make_folder
   if not exist %~1 (
      md %~1>nul
   )
   goto:eof

:_make_file
   if  not exist %~1 (
      echo.>%~1
   )
   goto:eof


@REM https://jakash3.wordpress.com/2009/12/18/arrays-in-batch/
@REM Gets array length. (edited: for character arrays index by int)
@REM Arguments: (
@REM name As "Array name"
@REM var As "Output Variable"
@REM )
@REM Eample Array Name is "books". Return Variable is "length"
@REM call array.bat len book length
@REM echo I'm have %length% books you can borrow.
:_get-chr-array-length
   @REM @echo Params %~1 %~2
   set array.name=%~1
   set array.var=%~2
   for /f "delims=[=] tokens=2*" %%a in ('set %array.name%[') do (
   set %array.var%=%%b
   )
   goto :eof

@REM https://jakash3.wordpress.com/2009/12/18/arrays-in-batch/
@REM Gets array length. (edited: for integer arrays index by character)
@REM see notes in _get-chr-array
:_get-int-array-length
   @REM @echo Params %~1 %~2
   set array.name=%~1
   set array.var=%~2
   for /f "delims=[=] tokens=2*" %%a in ('set %array.name%[') do (
   set %array.var%=%%a
   )
   goto :eof

:_get-array-length
    goto:_get-int-array-length %1 %2
    goto:eof


@REM Exit Utilities
%_ex%
 
"@REM oadmac.cmd"  
  
@REM ---------------------------------------------------------------------
@REM Macros and Variables
@echo off

@REM Exit Subroutines and Scripts
set _ex=exit /b

@REM Status Codes
set _ok=0
set _nok=1
set _warn=-1
set _err=%_nok%
set _default_error=9009

@REM Exit with status
set _ex_ok=%_ex% %_ok%
set _ex_error=%_ex% %_err%
set _ex_warning=%_ex% %_warn%

@REM Message Prefixes
set _log_info=-----[INFO]:
set _log_error=----[ERROR]:
set _log_warn=--[WARNING]:
set _log_debug=----[DEBUG]:
set _log_trace=----[TRACE]:

@REM formatting
set _line="==========================================================================="


@REM Exit Macros
%_ex% 0
 
"@REM README.txt"  
  

Readme for "oad"

Description
See: U:\git\WWS\_DSD\Projects\OAD\doc\oad_help.txt
or U:\git\WWS\_DSD\Projects\OAD\doc\README.md
for more information...

EOF

 
"@REM oadfnc.cmd"  
  
@echo on
setlocal enableextensions
@REM ==========================================================================
@REM Functions

@REM Not to be directly called
exit /b 9009

@REM ---------------------------------------------------------------------
@REM Help
:_help
   more %~1
   goto:eof

@REM Logging
:_set-log-level
   set _THIS=%~n0:_set-log-level
   @REM get length of array to reset higher logging levels
   call :_get-chr-array-length LogLevels ArraySize
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: There are %ArraySize% Log Levels."
   if %~1 GTR %ArraySize% (
      call :_log_warning "%_THIS%: desired Log Level: %~1 will be reset to max level %ArraySize%."
      set "_LL=%ArraySize%"
      ) else (
         set "_LL=%~1"
         )
   setlocal enabledelayedexpansion
   set "_LS=!LogSeverities[%_LL%]!"
   @REM call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Current Log Level: %_LL% (!LogSeverities[%_LL%]!)."
   endlocal & set "_LOG_LEVEL=%_LL%" & set "_LOG_SEVERITY=%_LS%"
   goto:eof

@REM  Set Log Level
:_set-log-mode
   set _THIS=%~n0:_set-log-level
   setlocal enabledelayedexpansion
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Setting Log Mode to: %~1."
   endlocal & set "_LOG_MODE=%~1"
   goto:eof

@REM raw log function that processes up to 9 arguments
@REM standard log format for script messages
@REM DATE/TIME  SEVERITY  ([ERRORLEVEL])  MESSAGE
:_log
   setlocal
   set _MSG=
      if not "%~1." == "." set _MSG=%~1
      if not "%~2." == "." set _MSG=%_MSG% %~2
      if not "%~3." == "." set _MSG=%_MSG% %~3
      if not "%~4." == "." set _MSG=%_MSG% %~4
      if not "%~5." == "." set _MSG=%_MSG% %~5
      if not "%~6." == "." set _MSG=%_MSG% %~6
      if not "%~7." == "." set _MSG=%_MSG% %~7
      if not "%~8." == "." set _MSG=%_MSG% %~8
      if not "%~9." == "." set _MSG=%_MSG% %~9
      @REM if not "%MSG%." == "." @echo.%_MSG%
      @echo.%_MSG%
   endlocal
   goto:eof

:_log_info
   setlocal
   set _LOGMODE=%~1
   set _LOGFILE=%~2
   if %_LOG_LEVEL% GEQ %LogLevels[INFO]% (
      @REM call:_log "%DATE% %TIME:~0,8%" "%_log_info%" %3
      if "%_LOGMODE%"=="CONSOLE" call:_log "%DATE% %TIME:~0,8%" "%_log_info%" %3
      if "%_LOGMODE%"=="FILE" call:_log "%DATE% %TIME:~0,8%" "%_log_info%" %3 >> %_LOGFILE%
      if "%_LOGMODE%"=="BOTH" (
         call:_log "%DATE% %TIME:~0,8%" "%_log_info%" %3
         call:_log "%DATE% %TIME:~0,8%" "%_log_info%" %3 >> %_LOGFILE%
      )
   ) & endlocal
   goto:eof

:_log_debug
   setlocal
   set _LOGMODE=%~1
   set _LOGFILE=%~2
   if %_LOG_LEVEL% GEQ %LogLevels[DEBUG]% (
      if "%_LOGMODE%"=="CONSOLE" call:_log "%DATE% %TIME:~0,8%" "%_log_debug%" %3
      if "%_LOGMODE%"=="FILE" call:_log "%DATE% %TIME:~0,8%" "%_log_debug%" %3>>%_LOGFILE%
      if "%_LOGMODE%"=="BOTH" (
         call:_log "%DATE% %TIME:~0,8%" "%_log_debug%" %3
         call:_log "%DATE% %TIME:~0,8%" "%_log_debug%" %~3>>%_LOGFILE%
      )
   ) & endlocal
   goto:eof

:_log_trace
   setlocal
   set _LOGMODE=%~1
   set _LOGFILE=%~2
   if %_LOG_LEVEL% GEQ %LogLevels[TRACE]% (
      if "%_LOGMODE%"=="CONSOLE" call:_log "%DATE% %TIME:~0,8%" "%_log_trace%" %3
      if "%_LOGMODE%"=="FILE" call:_log "%DATE% %TIME:~0,8%" "%_log_trace%" %3>>%_LOGFILE%
      if "%_LOGMODE%"=="BOTH" (
         call:_log "%DATE% %TIME:~0,8%" "%_log_trace%" %3
         call:_log "%DATE% %TIME:~0,8%" "%_log_trace%" %~3>>%_LOGFILE%
      )
   )  & endlocal
   goto:eof

:_log_warning
   setlocal
   if "%_LOG_WARNINGS%"=="TRUE" (
      if %_LOG_LEVEL% GEQ %LogLevels[INFO]% (
         if "%_LOGMODE%"=="CONSOLE" call:_log "%DATE% %TIME:~0,8%" "%_log_warning%" %3
         if "%_LOGMODE%"=="FILE" call:_log "%DATE% %TIME:~0,8%" "%_log_warning%" %3>>%_LOGFILE%
         if "%_LOGMODE%"=="BOTH" (
            call:_log "%DATE% %TIME:~0,8%" "%_log_warning%" %3
            call:_log "%DATE% %TIME:~0,8%" "%_log_warning%" %~3>>%_LOGFILE%
         )
      )
   ) & endlocal
   goto:eof

:_log_error
   setlocal
   @REM setting Errorlevel
   if not "%4." == "." (
      set _ERR=^[%~4^] ) else (
   @REM reset to %_default_error% if no Errorlevel was passed
   set _ERR=^[%_default_error%^]
   )
   if %_LOG_LEVEL% GEQ %LogLevels[INFO]% (
      @REM call:_log "%~1" "%~2" "%DATE% %TIME:~0,8%" "%_log_error%" %3 "%_ERR%"
      if "%_LOGMODE%"=="CONSOLE" call:_log "%DATE% %TIME:~0,8%" "%_log_error%" %3  "%_ERR%"
      if "%_LOGMODE%"=="FILE" call:_log "%DATE% %TIME:~0,8%" "%_log_error%" %3  "%_ERR%">>%_LOGFILE%
      if "%_LOGMODE%"=="BOTH" (
         call:_log "%DATE% %TIME:~0,8%" "%_log_error%" %3
         call:_log "%DATE% %TIME:~0,8%" "%_log_error%" %~3>>%_LOGFILE%
      )
   ) & endlocal
   goto:eof

:_usage
   @echo.
   @echo.Usage: %~1 (options) [params]. Type %~1 -h for more information.
   goto:eof

@REM =====================================================================
@REM processing options

@REM parse options
:_parse_config_options
set _THIS=%~n0:_parse_config_options
set _OPTIONS=%1
set _OPT_VAL=%_OPTIONS:"=%
set _OPT_VAL=%_OPT_VAL:+=,%
set _OPT_VAL=%_OPT_VAL:/=%
call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _OPTIONS=%_OPT_VAL%"
set _PROJECT_SET=%~2
set _TICKET_SET=%~3
set _KEEP_FILES_SET=%~4
set _CREATE_FOLDER_SET=%~5
set _LOG_LEVEL_SET=%~6
setlocal enabledelayedexpansion
for %%g in (%_OPT_VAL%) do (
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Check option: %%g"
    for /f "tokens=1,2 delims=:" %%x in ('@echo %%g') do (
        set _CONFIG_OPTION=%%x
        set _CONFIG_VALUE=%%y
        if [!_CONFIG_VALUE!]==[] (
           call :_log_error "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _CONFIG_VALUE empty!"
           %_ex_error%
           )
        call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _CONFIG_OPTION=!_CONFIG_OPTION!"
        call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _CONFIG_VALUE=!_CONFIG_VALUE!"
        call :_check_option "!_CONFIG_OPTIONS!" "!_CONFIG_OPTION!"
        if !ERRORLEVEL! NEQ 0 (
            call :_log_error "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Invalid Option: "!_CONFIG_OPTION!"" "!ERRORLEVEL!"
            %_ex% 1
        ) else (
            call :_log_debug  "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: %_SCRIPT% Option check returned: !ERRORLEVEL!"
            call :_log_debug  "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Calling function :_!_CONFIG_OPTION! with !_CONFIG_VALUE!"
            call :_!_CONFIG_OPTION! !_CONFIG_VALUE!
        )
   )
)
endlocal & set "%_PROJECT_SET%=%_PROJECT%" & set "%_TICKET_SET%=%_TICKET%" & set "%_KEEP_FILES_SET%=%_KEEP_FILES%" & set "%_CREATE_FOLDER_SET%=%_CREATE_IF_NOT_EXISTS%" & set "%_LOG_LEVEL_SET%=%_LOG_LEVEL%" & %_ex% %ERRORLEVEL%
   goto:eof

@REM =====================================================================
@REM parse MALE options
:_parse_make_options
set _THIS=%~n0:_parse_make_options
set _OPTION_VAL=%~1
set _OPTION_LIST=%~2
call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _OPTION_LIST=%_OPTION_LIST% _OPTION_VAL=%_OPTION_VAL%"
setlocal enabledelayedexpansion
for %%g in (%_OPTION_VAL%) do (
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Check option: %%g"
      call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _MAKE_OPTION_LIST=!_OPTION_LIST!"
      call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _MAKE_VALUE=!_OPTION_VAL!"
      call :_check_option "!_OPTION_LIST!" "!_OPTION_VAL!"
      if !ERRORLEVEL! NEQ 0 (
         call :_log_error "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Invalid Option: "!_OPTION_VAL!"" "!ERRORLEVEL!"
         %_ex% 1
      ) else (
         call :_log_debug "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: %_SCRIPT% Option check returned: !ERRORLEVEL!"
      )
   )
endlocal & %_ex% %ERRORLEVEL%
   goto:eof

@REM =====================================================================
@REM check option arguments against array of valid values (exact match)
:_check_option_value
set _THIS=%~n0:_check_option_value
set _VALUE=%~1
set _VALUELIST=%2
set _NOTFOUND_SET=%~3
set NOTFOUND=
setlocal enabledelayedexpansion
set NOTFOUND=1
call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _VALUELIST=%_VALUELIST:"=% _VALUE=%_VALUE%"
for %%g in (%_VALUELIST:"=%) do (
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS% [%%g] = [!_VALUE!]"
   if %%g==!_VALUE! set NOTFOUND=0
)
endlocal & call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS% [%NOTFOUND%]" & set "%_NOTFOUND_SET%=%NOTFOUND%" & %_ex% %NOTFOUND%
goto:eof

@REM =====================================================================
@REM get ticket name from project if contained
:_get-ticket-from-project
   set _THIS=%~n0:_get-ticket-from-project
   set PRJKEYS=%1
   set PRJ=%~2
   @REM check via regexp
   call :_check_option_r %PRJKEYS% "%PRJ%"
   set _ERR=%ERRORLEVEL%
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Return: %_ERR%"
   if "%_ERR%"=="0" (
      call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Ticketprefix found, so continue..."
      setlocal enabledelayedexpansion
      set TICKET=
      for /f "tokens=1,2 delims=_" %%t in ('@echo %PRJ%') do (
         call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: TICKET: %%t"
         set TICKET=%%t
      )
   )
   endlocal & set "_TICKET=%TICKET%" & %_ex_ok%
   goto:eof

@REM check option arguments against array of valid values (exact match)
:_check_option
   set _THIS=%~n0:_check_option
    set NOTFOUND=
    setlocal enabledelayedexpansion
    set NOTFOUND=1
    set _OPTIONLIST=%1
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: _OPTIONLIST=%_OPTIONLIST:"=%"
    set _OPTION=%~2
    for %%g in (%_OPTIONLIST:"=%) do (
      call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS% %%g = !_OPTION!"
      if %%g==!_OPTION! set NOTFOUND=0
    )
   endlocal & %_ex% %NOTFOUND%
   goto:eof

@REM check option arguments against array with regexp
:_check_option_r
   set _THIS=%~n0:_check_option_r
   set NOTFOUND=
   set KEYS=%~1
   set VAL=%~2
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Keys: %KEYS%  Value: %VAL%"
   setlocal enabledelayedexpansion
   set NOTFOUND=1
   for %%g in (%KEYS:"=%) do (
      call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS%: Checking Key %%g"
      echo %VAL% | findstr /R "%%g">nul & set NOTFOUND=%ERRORLEVEL%
   )
   endlocal & %_ex% %NOTFOUND%
   goto:eof


:_st
   call :_set _TICKET %~1
   goto:eof

:_set-ticket
   call :_set _TICKET %~1
   goto:eof

:_sp
   call :_set _PROJECT %~1
   goto:eof

:_set-project
   call :_set _PROJECT %~1
   goto:eof

:_sk
   call :_set _KEEP_FILES %~1
   goto:eof

:_set-keep-files
   call :_set _KEEP_FILES %~1
   goto:eof

:_sce
   call :_set _CREATE_IF_NOT_EXISTS %~1
   goto:eof

:_set-create-if-not-exist
   call :_set _CREATE_IF_NOT_EXISTS %~1
   goto:eof


@REM main _set function
:_set
   call set "%~1=%~2"
   goto:eof

:_gp
   call :_get %~1
   goto:eof

:_get-project
   call :_get %~1
   goto:eof

@REM main _get function
:_get
   set _THIS=%~n0:_get
   call :_log_trace "%_LOG_MODE%" "%_LOG_FILE%" "%_THIS% Getting %~1"
   set | findstr /R "^%~1=.*$"
   set /A _RC=%ERRORLEVEL%*-1
   %_ex% %_RC%
   goto:eof

@REM Utility Functions
:_get-chr-array-length
   %_UTILS% %*
   goto:eof

:_get-int-array-length
   %_UTILS% %*
   goto:eof

:_get-array-length
   %_UTILS% %*
   goto:eof

@REM ==========================================================================
@REM exit Functions
%_ex%
 
"@REM oad.ini"  
  
; ==========================================================================
; odev.ini (overwrites defaults if set)
; [Project]
_PROJECT=
_PROJECT_ROOT=U:\git\WWS\_DSD\Projects
; parent folder to your projects (must provide no leading, but a trailing \)
_PROJECT_FOLDER_PREFIX=WWS\
_PROJECT_CONF=.project.conf
_PROJECT_KEYS="APEX-,SWE-,PIA-,TRAIN"
_PROJECT_DOC_DIR=DOC
; place sub-subfolders that contain \ at end of string
_PROJECT_SUBFOLDERS=ARC,ARC\Builds,ARC\Sources,ARC\Documents,BLD,DOC,LIB,LOG,SRC,TMP
_GITIGNORE_OBJECTS=ARC,LOG,TMP
; Encoding and Codepage
; [Encoding]
_ENCODING=.AL32UTF8
_CODEPAGE=65001
; [Options]
; Levels: 0=OFF 1=INFO 2=DEBUG 3=TRACE
_LOG_LEVEL=1
; log warnings to console [TRUE|FALSE]
_LOG_WARNINGS=TRUE
; _KEEP_FILES [NONE|ARCHIVE|MOVE]
_KEEP_FILES=ARCHIVE
; Folder and File handling
_CREATE_IF_NOT_EXISTS=TRUE
_CREATE_GITIGNORE=TRUE
_CREATE_README=TRUE
_CREATE_HTDOC=TRUE
_CREATE_HELP=TRUE 
"@REM .gitignore"  
  

_current_project
log
tmp
arc
 
"@REM oad_config.cmd"  
  
@REM ---------------------------------------------------------------------
@REM odev_config.cmd
@echo off
setlocal enableextensions
@REM =====================================================================
@REM script variables
set _SCRIPT=%~n0
set _SCRIPTNAME=%0
@REM =====================================================================
@REM @echo Params "%*"
@REM =====================================================================
@REM check mandatory parameter
if "[%1]"=="[]" (
   @echo. & @echo Usage: %_SCRIPT% ^(options^) ^[params^]
   @echo Type %_SCRIPT% -h for more information.
   @echo.
   endlocal
   exit /b)

@REM =====================================================================
@REM script variables
set _RC=

@REM valid options for script
set _CONFIG_OPTIONS="set-project,sp,get-project,gp,set-ticket,st,get-ticket,gt"

@REM setting options
@REM set _OPTIONS=%~1
@REM call :_log_debug "_OPTIONS=%_OPTIONS:+=,%"
@REM set _PROJECT_SET=%~2
@REM @echo _PROJECT_SET=%_PROJECT_SET%
@REM set _TICKET_SET=%~3


call :_parse_options %*
@REM @echo Script: %_SCRIPT%  Option: %_CONFIG_OPTION%  Value: %_CONFIG_VALUE%

if not [%_PROJECT_SET%]==[] call :_log_info "Project set: %_PROJECT_SET%"
if not [%_TICKET_SET%]==[] call :_log_info "Ticket set: %_TICKET_SET%"

@REM =====================================================================
@REM skip subroutines
goto:eof

@REM =====================================================================
@REM subroutines

@REM parse options
:_parse_options
@REM setting options
set _OPTIONS=%~1
call :_log_debug "_OPTIONS=%_OPTIONS:+=,%"
set _PROJECT_SET=%~2
@echo _PROJECT_SET=%_PROJECT_SET%
set _TICKET_SET=%~3

setlocal enabledelayedexpansion
for %%g in (%_OPTIONS:+=,%) do (
    @REM @echo %%g
    for /f "tokens=1,2 delims=:" %%x in ('@echo %%g') do (
        set _CONFIG_OPTION=%%x
        set _CONFIG_VALUE=%%y
        @REM @echo _CONFIG_OPTION=!_CONFIG_OPTION!
        @REM @echo _CONFIG_VALUE=!_CONFIG_VALUE!
        call :_check_option %_CONFIG_OPTIONS% !_CONFIG_OPTION!
        @REM @echo Err: !ERRORLEVEL!
        if !ERRORLEVEL! NEQ 0 (
            call :_log_error "Invalid Option: "!_CONFIG_OPTION!"" "!ERRORLEVEL!" && goto:eof
        ) else (
            call :_log_debug "%_SCRIPT% option check returned: !ERRORLEVEL!"
            call :_log_debug "calling function :_!_CONFIG_OPTION!"
            call :_!_CONFIG_OPTION!
        )
    )
)
endlocal & set "%_PROJECT_SET%=%_PROJECT%" && set "%_TICKET_SET%=%_TICKET%"


@REM check script options
:_check_option
    set NOTFOUND=
    setlocal enabledelayedexpansion
    set NOTFOUND=1
    set _OPTIONLIST=%1
    @REM @echo _OPTIONLIST=%_OPTIONLIST%
    set _OPTION=%~2
    for %%g in (%_OPTIONLIST:"=%) do (
        @REM @echo %%g = !_OPTION!
        if %%g==!_OPTION! set NOTFOUND=0
    )
    endlocal & %_ex% %NOTFOUND%

goto:eof


:_set-project
%_FUNCTIONS% "_PROJECT" "%_CONFIG_VALUE%"
goto:eof

:_sp
%_FUNCTIONS% "_PROJECT" "%_CONFIG_VALUE%"
goto:eof


:_get-project
%_FUNCTIONS% "_PROJECT"
goto:eof

:_gp
call :_get-project "_PROJECT"
goto:eof


:_set-ticket
%_FUNCTIONS% "_TICKET" "%_CONFIG_VALUE%"
goto:eof

:_st
%_FUNCTIONS% "_TICKET" "%_CONFIG_VALUE%"
goto:eof


:_get-ticket
%_FUNCTIONS% "_TICKET"
goto:eof

:_gt
call :_get-ticket "_TICKET"
goto:eof


@REM Logging
:_log_info
   %_FUNCTIONS% %*
   goto:eof

:_log_warning
   %_FUNCTIONS% %*
   goto:eof

:_log_trace
   %_FUNCTIONS% %*
   goto:eof

:_log_debug
   %_FUNCTIONS% %*
   goto:eof

:_log_error
   %_FUNCTIONS% %*
   goto:eof


@REM EOF
:eof

@REM endlocal
@REM exit /b ERRORLEVEL
%_ex% %ERRORLEVEL%
 
"@REM oaddef.cmd"  
  
@REM ==========================================================================
@REM Script Defaults
set _PROJECT=
set _PROJECT_ROOT=C:\%USERPROFILE%\Projects
@REM parent folder to your projects (must provide no leading, but a trailing \)
set _PROJECT_FOLDER_PREFIX=
set _PROJECT_CONF=.project.conf
set _PROJECT_SUBFOLDERS=ARC,ARC\Builds,ARC\Sources,ARC\Documents,BLD,DOC,LIB,LOG,SRC,TMP
set _GITIGNORE_OBJECTS=arc,log,tmp
set _PROJECT_KEYS="JIRA-,APEX-,ORA-"
set _PROJECT_DOC_DIR=DOC
@REM Levels: 0=OFF 1=INFO 2=DEBUG 3=TRACE
set _LOG_LEVEL=1
@REM log warnings to console
set _LOG_WARNINGS=TRUE
@REM Encoding and Codepage
set _ENCODING=.AL32UTF8
set _CODEPAGE=65001
set _FOLDERS=log,tmp,src
set _KEEP_FILES=FALSE
set _CREATE_IF_NOT_EXISTS=FALSE
set _CREATE_GITIGNORE=FALSE
set _CREATE_README=TRUE
set _CREATE_HTDOC=FALSE
set _CREATE_HELP=FALSE 
"@REM _current_project"  
  
_PROJECT=SWE-1234_APX_GRPO
 
