@echo off
@REM ---------------------------------------------------------------------
@REM sample.cmd to demonstrate macros, sourcing and functions
@REM 2023-05-13 sob01: created
@REM ---------------------------------------------------------------------
@REM
@REM Variable expansion means replace a variable enclosed in % or ! by its value.
@REM The %normal% expansion happen just once, before a line is executed. This means that a %variable% expansion have the same value no matters if the line is executed several times (like in a for command).
@REM The !delayed! expansion is performed each time that the line is executed.
@REM See this example:
@REM
@REM @echo off
@REM setlocal EnableDelayedExpansion
@REM set "var=Original"
@REM set "var=New" & echo Normal: "%var%", Delayed: "!var!"
@REM Output: Normal: "Original", Delayed: "New"
@REM
@REM Another one:
@REM
@REM @echo off
@REM setlocal EnableDelayedExpansion
@REM set "var1=Normal"
@REM set "var2=Delayed"
@REM for /L %%i in (1,1,10) do (
@REM    set "var1=%var1% %%i"
@REM    set "var2=!var2! %%i"
@REM )
@REM echo Normal:  "%var1%"
@REM echo Delayed: "%var2%"
@REM Output:
@REM
@REM Normal:  "Normal 10"
@REM Delayed: "Delayed 1 2 3 4 5 6 7 8 9 10"
@REM Normal expansion is not necessarily a disadvantage, but depends on the specific situation it is used. For example, in any other programming languages, to exchange the value of two variables you need the aid of a third one, but in Batch it can be done in just one line:
@REM
@REM set "var1=%var2%" & set "var2=%var1%"
@REM
@REM echo Full path and filename: %~f0
@REM echo Drive: %~d0
@REM echo Path: %~p0
@REM echo Drive and path: %~dp0
@REM echo Filename without extension: %~n0
@REM echo Filename with    extension: %~nx0
@REM echo Extension: %~x0
@REM echo file date time : %~t0
@REM echo file size: %~z0
@REM
@REM The related rules are following.
@REM
@REM %~I         - expands %I removing any surrounding quotes ("")
@REM %~fI        - expands %I to a fully qualified path name
@REM %~dI        - expands %I to a drive letter only
@REM %~pI        - expands %I to a path only
@REM %~nI        - expands %I to a file name only
@REM %~xI        - expands %I to a file extension only
@REM %~sI        - expanded path contains short names only
@REM %~aI        - expands %I to file attributes of file
@REM %~tI        - expands %I to date/time of file
@REM %~zI        - expands %I to size of file
@REM %~$PATH:I   - searches the directories listed in the PATH
@REM                environment variable and expands %I to the
@REM                fully qualified name of the first one found.
@REM                If the environment variable name is not
@REM                defined or the file is not found by the
@REM                search, then this modifier expands to the
@REM                empty string
@REM
@REM You can get the file name, but you can also get the full path,
@REM depending what you place between the '%~' and the '0'. Take your pick from
@REM d -- drive
@REM p -- path
@REM n -- file name without extension
@REM x -- extension
@REM f -- full path
@REM Argument Handling Example
@REM :: Take the host pattern
@REM SET FIRST_ARG=%1
@REM shift
@REM :: Get the last argument
@REM set ARG=""
@REM IF "%1"=="" GOTO Continue
@REM set ARG=%1
@REM shift
@REM :Loop
@REM IF "%~1"=="" GOTO Continue
@REM set ARG=%ARG% %1
@REM SHIFT
@REM GOTO Loop
@REM :Continue
@REM
@REM ---------------------------------------------------------------------
@REM Setting script variables
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
if "[%*]"=="[]" (
   @echo. & @echo Usage: %_SCRIPT% ^(options^) ^[params^]
   @echo Type %_SCRIPT% -h for more information.
   endlocal
   exit /b)

@REM =====================================================================
@REM script variables
set _SCRIPTDIR=%~dp0
set _LOGDIR=%_SCRIPTDIR%log
set _LOG_FILE=%_LOGDIR%\%_SCRIPT%.log
set _HELP_FILE=%_SCRIPTDIR%%_SCRIPT%.txt
set _INI=%_SCRIPTDIR%%_SCRIPT%.ini
set _UTILS=%_SCRIPTDIR%%_SCRIPT%utl.cmd
set _MACROS=%_SCRIPTDIR%%_SCRIPT%mac.cmd
set _DEFAULTS=%_SCRIPTDIR%%_SCRIPT%def.cmd
set _FUNCTIONS=%_SCRIPTDIR%%_SCRIPT%fnc.cmd

set "LogLevels[OFF]=0"
set "LogLevels[INFO]=1"
set "LogLevels[DEBUG]=2"
set "LogLevels[TRACE]=3"

set "LogSeverities[0]=OFF"
set "LogSeverities[1]=INFO"
set "LogSeverities[2]=DEBUG"
set "LogSeverities[3]=TRACE"

@REM =====================================================================
@REM reset variables
set _RC=
set _DEBUG=
set _TRACE=

@REM runtime variables
set _CREATE_FOLDER_IF_NOT_EXISTS=
set _KEEP_FILES=

@REM project variables
set _PROJECT=
set _PROJECT_FOLDER=

@REM =====================================================================
@REM calling defaults
call %_DEFAULTS%

@REM calling functions and utilities on demand (see bottom of script)

@REM =====================================================================
@REM calling INI
for /f "tokens=1* delims==" %%a in ('type %_INI%^|findstr /V /R "^@.*" ') do (
   @REM @echo setting %%a=%%b
   call set "%%a=%%b"
   )

@REM =====================================================================
@REM calling macros
call %_MACROS%

@REM =====================================================================
@REM process defaults
for %%g in (%_FOLDERS%) do (
   if not exist  %_SCRIPTDIR%%%g (
       call :_make_folder %_SCRIPTDIR%%%g
   )
)

@REM =====================================================================
@REM make Help File if not exist
if not exist "%_HELP_FILE%" call :_make_help

@REM =====================================================================
@REM call arg parser
call :parse_args %*

@REM =====================================================================
@REM --- process results and set runtime variables by options and params
@REM =====================================================================

@REM test functions
@REM echo %_LOGINFO%
@REM set _LOGINFO=FALSE
set _LOG_LEVEL=1

call :_set-log-level %_LOG_LEVEL%

@echo _LOG_SEVERITY=%_LOG_SEVERITY%


call :_log_info "What an Info message"
set _TRACE=
set _DEBUG=TRACE
set _DEBUG=DEBUG

if %_DEBUG%==TRACE (
   set _DEBUG=DEBUG
   set _TRACE=TRUE
   )
call :_log_debug "What a Debug message"
call :_log_trace "What a Trace message"
set _DEBUG=FALSE
@REM no debug needed
call :_log_warning "What a Warning message"
call :_log_error "What an Error message"

@REM display help and exit
if "%_DISPLAY_HELP%" == "Y" call :_help && goto:eof



@REM config
if %_PARAM%==CONFIG SET _RUN=%_SCRIPT%_%_PARAM%.cmd
if exist %_RUN%  call %_RUN% %_WHAT% %_VALUE%
if %ERRORLEVEL% GTR 0 (
   %_log_error% Parameter "%_PARAM%" returned with errors. Ckeck your inputs...
   goto:eof
)


call :_get-project
%_log_info% Main Project: %_PROJECT%


goto:eof


@REM =====================================================================
@REM continue, so emit one empty line first
@echo.

@REM =====================================================================
@REM set options and defaults




@REM =====================================================================
@REM all good so far, so...
:continue

%_log_info% Starting %_SCRIPT%

@REM =====================================================================
@REM trace call
if "%_TRACE%" == "TRUE" (
       %_log_trace% %_line%
       %_log_trace% Script: "%_SCRIPT%"
       %_log_trace% Script Current Parameter: "%*"
       %_log_trace% Script Ini File: "%_INI%"
       %_log_trace% Script Log File: "%_LOG_FILE%"
       %_log_trace% Script Help File: "%_HELP_FILE%"
       %_log_trace% Script Util File: "%_UTILS%"
       %_log_trace% Script Macros File: "%_MACROS%"
       %_log_trace% Script Defaults File: "%_DEFAULTS%"
       %_log_trace% Script Functions File: "%_FUNCTIONS%"
       %_log_trace% %_line%
       %_log_trace% Script Variables: _KEEP_FILES="%_KEEP_FILES%",
       %_log_trace% Script Variables: _KEEP_FILES_METHOD="%_KEEP_FILES_METHOD%",
       %_log_trace% Script Variables: _CREATE_FOLDER_IF_NOT_EXISTS="%_CREATE_FOLDER_IF_NOT_EXISTS%",
)

@REM debug call
if "%_DEBUG%" == "TRUE" (
       %_log_debug% %_line%
       %_log_debug% Current Project: "%_PROJECT%"
       %_log_debug% Project Root: %_ROOT%
       %_log_debug% Project Root Folder: %_PROJECT_ROOT%
       %_log_debug% Project Keys: %_PROJECT_KEYS%
       %_log_debug% %_line%
       %_log_debug% Run Variables: _DEBUG="%_DEBUG%", _DISPLAY_HELP="%_DISPLAY_HELP%",
       %_log_debug% Run Variables: _SET_PROJECT="%_SET_PROJECT%", _SET_PROJECT_NAME="%_SET_PROJECT_NAME%",
       %_log_debug% Run Variables: _PROJECT_NAME_CONTAINS_TICKET=%_PROJECT_NAME_CONTAINS_TICKET%,
       %_log_debug% Run Variables: _SET_TICKET="%_SET_TICKET%", _SET_TICKET_NAME="%_SET_TICKET_NAME%",
       %_log_debug% Run Variables: _MAKE="%_MAKE%", _MAKE_PROJECT="%_MAKE_PROJECT%", _MAKE_PROJECT_NAME="%_MAKE_PROJECT_NAME%",
       %_log_debug% Run Variables: _MAKE_FILE="%_MAKE_FILE%", _MAKE_FILE_NAME="%_MAKE_FILE_NAME%",
       %_log_debug% Run Variables: _MAKE_FOLDER="%_MAKE_FOLDER%", _MAKE_FOLDER_NAME="%_MAKE_FOLDER_NAME%".
)

@REM =====================================================================
@REM processing
%_log_info% %_line%
%_log_info% ----- Processing

%_log_info% %_line%
%_log_info% Done %_SCRIPT%

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
@REM debug (no quotes: pseudo boolean handling)
if "%1" == "-d"              set "_DEBUG=TRUE"
if "%1" == "debug"           set "_DEBUG=TRUE"
if "%1" == "-t"              set "_DEBUG=TRUE" && set "_TRACE=TRUE"
if "%1" == "trace"           set "_DEBUG=TRUE" && set "_TRACE=TRUE"


@REM consider moving to CONFIG

@REM set options (if mutually exclusive - goto:eof)
if "%1" == "-kf"             set "_KEEP_FILES=Y" && set "_KEEP_FILES_METHOD=%~2"
if "%1" == "set-keep-files"  set "_KEEP_FILES=Y" && set "_KEEP_FILES_METHOD=%~2"
if "%1" == "-cf"             set "_CREATE_FOLDER_IF_NOT_EXISTS=%~2"
if "%1" == "set-create-folder-if-not-exist"           set "_CREATE_FOLDER_IF_NOT_EXISTS=%~2"
@REM set project and ticket options
if "%1" == "-sp"             set "_SET_PROJECT=Y"  && set "_SET_PROJECT_NAME=%~2"
if "%1" == "set-project"     set "_SET_PROJECT=Y"  && set "_SET_PROJECT_NAME=%~2"
if "%1" == "-st"             set "_SET_TICKET=Y"   && set "_SET_TICKET_NAME=%~2"   && goto:eof
if "%1" == "set-ticket"      set "_SET_TICKET=Y"   && set "_SET_TICKET_NAME=%~2"   && goto:eof

@REM param CONFIG
if "%1" == "-c"              set "_PARAM=CONFIG" && set "_WHAT=%~2" && set "_VALUE=%~3"  && goto:eof
if "%1" == "config"            set "_PARAM=CONFIG" && set "_WHAT=%~2" && set "_VALUE=%~3"  && goto:eof

@REM param SHOW
if "%1" == "-s"              set "_PARAM=SHOW" && set "_WHAT=%~2" && set "_VALUE=%~3"  && goto:eof
if "%1" == "show"            set "_PARAM=SHOW" && set "_WHAT=%~2" && set "_VALUE=%~3"  && goto:eof

@REM param MAKE
if "%1" == "-m"              set "_PARAM=MAKE" && set "_WHAT=%~2" && set "_VALUE=%~3"  && goto:eof
if "%1" == "make"            set "_PARAM=MAKE" && set "_WHAT=%~2" && set "_VALUE=%~3"  && goto:eof


@REM EO Parse Args
shift
if "[%1]"=="[]" goto:eof
goto:parse_args

@REM =====================================================================
@REM Subroutine Calls in %_FUNCTIONS% and %_UTILS% File


@REM utilities
:_make_folder
   %_UTILS% %1
   goto:eof

:_make_help
   %_UTILS% %_HELP_FILE% %_SCRIPT%
   goto:eof

@REM functions
:_usage
   %_FUNCTIONS% %_SCRIPT%
  goto:eof

:_debug_call
   %_FUNCTIONS% %1
   goto:eof

:_help
   %_FUNCTIONS% %_HELP_FILE%
   goto:eof

@REM framework
:_set_project
   %_FUNCTIONS% %*
   goto:eof

:_get-project
   for /f "tokens=1,2* delims==" %%a in ('set ^| findstr /R "^_PROJECT=.*$"') do (
   @REM @echo %%a %%b
   call set "%%a=%%b"
   )
   goto:eof

:_set_ticket
   %_FUNCTIONS% %1
   goto:eof

:_set-log-level
   %_FUNCTIONS% %1
   goto:eof


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
goto:eof

@REM =====================================================================
@REM reset...
:EOF

popd
endlocal
@REM exit /b ERRORLEVEL
%_ex% %ERRORLEVEL%
@REM odev.ini (overwrites defaults if set)
_PROJECT=
_PROJECT_ROOT=C:\Projects
@REM Levels: 0=OFF 1=INFO 2=DEBUG 3=TRACE
set _LOG_LEVEL=1
@REM log warnings to console
set _LOG_WARNINGS=TRUE
@REM Encoding and Codepage
_ENCODING=.AL32UTF8
_CODEPAGE=65001
_FOLDERS=log,tmp,src,exp,doc
_KEEP_FILES=ARCHIVE
_CREATE_FOLDER_IF_NOT_EXISTS=TRUE
        Help for "odev"

more help will follow...
@REM Defaults
set _PROJECT=
set _PROJECT_ROOT=C:\%USERPROFILE%\Projects
@REM Levels: 0=OFF 1=INFO 2=DEBUG 3=TRACE
set _LOG_LEVEL=1
@REM log warnings to console
set _LOG_WARNINGS=TRUE
@REM Encoding and Codepage
set _ENCODING=.AL32UTF8
set _CODEPAGE=65001
set _FOLDERS=log,tmp,src
set _KEEP_FILES=FALSE
set _CREATE_FOLDER_IF_NOT_EXISTS=TRUE@REM functions
@echo on
setlocal enableextensions
@REM Not to be directly called
exit /b 9009

@REM ---------------------------------------------------------------------
@REM Functions
set NOTFOUND=


:_help
   more %~1
   goto:eof

:_set-log-level
   setlocal enabledelayedexpansion
   set "_LS=!LogSeverities[%~1]!"
   endlocal & set "_LOG_SEVERITY=%_LS%"
   goto:eof


@REM raw log function that processes up to 10 arguments
@REM standard log format for script messages
@REM DATE/TIME  SEVERITY  ([ERRORLEVEL])  MESSAGE
:_log
       set _MSG=
       if not "%~1." == "." set _MSG=%~1
       if not "%~2." == "." set _MSG=%_MSG% %~2
       if not "%~3." == "." set _MSG=%_MSG% %~3
       if not "%~4." == "." set _MSG=%_MSG% %~4
       if not "%~5." == "." set _MSG=%_MSG% %~5
       if not "%_MSG%." == "." @echo.%_MSG%
   goto:eof

:_log_info
   setlocal
   if "%_LOGINFO%" == "TRUE" (
       call:_log "%DATE% %TIME:~0,8%" "%_log_info%" %1
   ) & endlocal
   goto:eof

:_log_debug
   setlocal
   if "%_DEBUG%" == "DEBUG" (
       call:_log "%DATE% %TIME:~0,8%" "%_log_debug%" %1
   ) & endlocal
   goto:eof

:_log_trace
   setlocal
   if "%_TRACE%" == "TRUE" (
       call:_log "%DATE% %TIME:~0,8%" "%_log_trace%" %1
   )  & endlocal
   goto:eof

:_log_warning
   setlocal
   call:_log "%DATE% %TIME:~0,8%" "%_log_warn%" %1 & endlocal
   goto:eof

:_log_error
   setlocal
   if not "%2." == "." set _ERR=^[%~2^]
   if "%2." == "." ( set _ERR=^[%_default_error%^] )
   call:_log "%DATE% %TIME:~0,8%" "%_log_error%" "%_ERR%" %1 & endlocal
   goto:eof


:_usage
   @echo.
   @echo.Usage: %~1 (options) [params]. Type %~1 -h for more information.
   goto:eof


:_debug_call
   %_log_debug% %~1
   goto:eof

:_check_option
   setlocal enabledelayedexpansion
   set NOTFOUND=1
   set _OPTIONLIST=%1
   set _OPTION=%~2
   for %%g in (%_OPTIONLIST:"=%) do (
@REM    @echo %%g = !_OPTION!
       if %%g==!_OPTION! set NOTFOUND=0
   )
   %_ex% !NOTFOUND!


:_-st
   call :_set %~1 %~2
   goto:eof

:_set-ticket
   call :_set %~1 %~2
   goto:eof

:_-sp
   call :_set %~1 %~2
   goto:eof

:_set-project
   call :_set _PROJECT %~2

   goto:eof

@REM main _set function
:_set
   call set "%~1=%~2"
   goto:eof

:_-gp
   call :_get %~1
   goto:eof

:_get-project
   call :_get %~1
   goto:eof

@REM main _get function

:_get
   @REM @echo Getting %~1
   set | findstr /R "^%~1=.*$"
   set /A _RC=%ERRORLEVEL%*-1
   %_ex% %_RC%
   goto:eof



@REM exit Functions
%_ex%
@REM macros
@echo off
@REM Macros and Variables
set _ex=exit /b

@REM Messages
set _m=@echo %DATE% %TIME%
@REM set _log_info=%_m%----[INFO]:
@REM set _log_error=%_m%---[ERROR]:
@REM set _log_warn=%_m%-[WARNING]:
@REM set _log_debug=%_m%---[DEBUG]:
@REM Exit Macros

set _default_error=9009

set _log_info=-----[INFO]:
set _log_error=----[ERROR]:
set _log_warn=--[WARNING]:
set _log_debug=----[DEBUG]:
set _log_trace=----[TRACE]:



%_ex%
@REM utils
@echo off
setlocal enableextensions
@REM Not to be directly called
exit /b 9009

@REM ---------------------------------------------------------------------
@REM Utilities

:_make_help
   %_log_info% Making "%~2" Help File
   @echo.>%~1
   @echo.         Help for "%~2">>%~1
   @echo.>>%~1
   @echo  more help will follow...>>%~1
   goto:eof

:_make_folder
     if not exist %~1 (
       %_log_info% Making Directory %1
       md %~1>nul
       )
   goto:eof

%_ex%
@echo off
@REM setlocal enableextensions
@REM =====================================================================
@REM script variables
set _SCRIPT=%~n0
set _SCRIPTNAME=%0
@REM =====================================================================
@REM @echo Params "%*"
@REM =====================================================================
@REM check mandatory parameter
if "[%2]"=="[]" (
   @echo. & @echo Usage: %_SCRIPT% ^(options^) ^[params^]
   @echo Type %_SCRIPT% -h for more information.
   @echo.
   endlocal
   exit /b)

@REM =====================================================================
@REM script variables
set _CONFIG_OPTION=%~1
set _CONFIG_OPTIONS=set-project,-sp,get-project,gp,set-ticket,st,get-ticket,gt
set _CONFIG_VALUE=%~2
set _RC=OK

@REM @echo Script: %_SCRIPT%  Option: %_CONFIG_OPTION%  Value: %_CONFIG_VALUE%

call :_check_option
if %ERRORLEVEL% NEQ 0 (
   set _RC=NOK && %_log_error% Invalid Option: "%_CONFIG_OPTION%" && goto:eof
   ) else (
   %_log_info% %_SCRIPT% option check: %_RC%
)


%_log_info% calling :_%_CONFIG_OPTION%
call :_%_CONFIG_OPTION%

%_log_info% Project set: %_PROJECT%

@REM =====================================================================
@REM skip subroutines
goto:eof

@REM =====================================================================
@REM subroutines

:_check_option
%_FUNCTIONS% "%_CONFIG_OPTIONS%" "%_CONFIG_OPTION%"
goto:eof

:_set-project
%_FUNCTIONS% "_PROJECT" "%_CONFIG_VALUE%"
goto:eof

:_get-project
%_FUNCTIONS% "_PROJECT"
goto:eof


:eof
@REM endlocal
@REM exit /b


