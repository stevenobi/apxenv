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
set _CURDIR=@echo %~dp0
set _SCRIPT=@echo %~n0
set _LOGDIR=%_CURDIR%\log
set _LOG_FILE=%_LOGDIR%\%_SCRIPT%.log
set _HELP_FILE=%_CURDIR%\%_SCRIPT%.txt
@REM calling macros file
call OADMAC.bat %_LOG_FILE% %_HELP_FILE%
@REM ---------------------------------------------------------------------
@REM contents of OADMAC.bat:
@REM
@echo off
@REM check if needed or if accessible already
set _LOGFILE="%1"
set _HELPFILE="%2"
@REM cls
@REM setlocal DisableDelayedExpansion
@REM ---------------------------------------------------------------------
@REM Macro Functions

@REM -- Date Time Functions
@REM Date
set _date=for /F "tokens=2" %%i in ('date /t') do @echo %%i
@REM Time
set _time=@echo %time%
@REM DateTime
set DT=@echo %_date% %_time%

@REM -- Runtime Functions
@REM a macro to run exit /b (ERRORLEVEL optional)
@REM You can then exit a subroutine with: %_ex% (ERRORLEVEL)
set _ex=exit /b %~1

@REM -- Status Values
set _ok=0
set _nok=1
set _warn=2
set _err=%_nok%
set _ex_ok=%_ex% %_ok%
set _ex_error=%_ex% %_err%
set _ex_warning=%_ex% %_warn%

@REM -- Log and Error Functions
@REM Console Logging to console only (call %_log% Message)
set _log_console=@echo %~1
@REM Logging (call %_log% Message File)
set _log_file=@echo %~1>>%2
@REM Console Logging to console and file (call %_log% Message File)
set _log_file_console=@echo %~1| tee -a %2

@REM Logger Shortcuts
set _logc=%_log_console% %~1 %_LOGFILE%
set _logf=%_log_file% %~1 %_LOGFILE%
set _logfc=%_log_file_console% %~1 %_LOGFILE%
@REM using log_file_console as default
set _log=%_logfc% %*

@REM @REM Default Logger???
@REM set _DEFAULT_LOGGER=%_log_console% %~1 %_LOGFILE%
@REM @REM using variable here???
@REM if %_LOGGER% == console      (set _DEFAULT_LOGGER=%_logc% %*)
@REM if %_LOGGER% == file         (set _DEFAULT_LOGGER=%_logf% %*)
@REM if %_LOGGER% == console_file (set _DEFAULT_LOGGER=%_logfc% %*)
@REM set _log=%_DEFAULT_LOGGER% %*

@REM Message (call: %_message% [Severity] [Message] [Errorlevel])
set _message=@echo %DT% %~1 [%~3]: %~2
@REM
@REM Error (call: %_error_msg% Message Errorlevel)
set _error_msg=%_message% "* ERROR:" %~1 %_err%
@REM Warning (call %_warning_msg% Message Errorlevel)
set _warning_msg=%_message% "WARNING:" %~1 %_warn%
@REM Success (call %_success_msg% Message Errorlevel)
set _success_msg=%_message% " SUCESS:" %~1 %_ok%
@REM Info (call %_info_msg% Message Errorlevel)
set _info_msg=%_message% "   INFO:" %~1 %_ok%

@REM Error (call: %_log_error% [Message] ([Logfile]))
set _log_error=set _MSG=%_error_msg% %~1 && %_log% %_MSG%
@REM Warning (call: %_log_warning% [Message] ([Logfile]))
set _log_warning=set _MSG=%_warning_msg% %~1 && %_log% %_MSG%
@REM Success (call: %_log_success% [Message] ([Logfile]))
set _log_success=set _MSG=%_success_msg% %~1 && %_log% %_MSG%
@REM Info (call: %_log_info% [Message] ([Logfile]))
set _log_info=set _MSG=%_info_msg% %~1 && %_log% %_MSG%

@REM :: Examples
::set MSG=%_error_msg% Failed to load file. && %_log% %MSG%
:: or
:: %_error_msg% Failed to load file. | %_log% %~1
:: or
::%_log_error% Failed to load file.
::

@REM Standard Checks and Returns
@REM
@REM Check If a file exists, else exit error
set _check_file=if not exist %~1 (
    %_log_error% File or Directory %~n1 not found^^!
    %_ex_error%) else (%_ex_ok%)
@REM Check if folder exists (wrapper to _check_file)
set _check_folder=%_check_file% %*

@REM :: Examples
:: set _JAVA=C:\%ProgramFiles%\Java\180.05\bin\java.exe
:: if %_check_file% %_JAVA% NEQ 0 %_ex_error%
::

@REM -- Help Functions
@REM Usage text and exit
set _usage=@echo Usage: %~1 & %_ex_warn%
@REM Help Text
set _help=type (%_HELPFILE%) | more & %_ex_warn%

@REM -- File Functions
@REM Codepage for current session
set _set_codepage=chcp %~1>nul

::EOF


@REM ---------------------------------------------------------------------
@REM calling environment file
call OADENV.bat
@REM contents of OADENV.bat
@echo off
set _PROJECT_ROOT=C:\User\Me\Projects
set _PROJECT=
@REM calls Encoding.bat, that contains set _ENCODING=.AL32UTF8
call OADENC.bat && set NLS_LANG=%_ENCODING%
@REM calls Codepage.bat, that contains set _CODEPAGE=65001
call OADCPG.bat && %_set_codepage% %_CODEPAGE%
::EOF

@REM ---------------------------------------------------------------------
@REM Main
@REM
@REM -- Prepare the Command Processor --
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
@REM ---------------------------------------------------------------------
if [%1]==[] (%_usage% "%_SCRIPT% <option> [PROJECT]" && %_ex%)
if [%1]==[-h] set "HELP=Y"
if [%1]==[help] set "HELP=Y"
if "%HELP%" == "Y" (%_help% %_script%.txt && %_ex%)


ENDLOCAL


@echo off
set _SCRIPT=%~n0
set _SCRIPTDIR=%~dp0
set _LOG_FILE=%_SCRIPT%.log
set _HELP_FILE=%_SCRIPT%.txt
set _MACROS=%_SCRIPT%macros.cmd
set _FUNCTIONS=%_SCRIPT%functions.cmd
@REM calling functions
call %_FUNCTIONS%
@REM calling macros
call %_MACROS%
@echo Params %*
if "[%*]"=="[]" goto :usage
goto continue
:usage
@echo.
%_usage%&goto:eof

@REM continue
:continue

@REM setting defaults
set _DISPLAY_HELP=N
set _MAKE=N
set _MAKE_PROJECT=N
set _MAKE_FILE=N
@REM call arg parser
call :parse_args %*
@echo _DISPLAY_HELP=%_DISPLAY_HELP%
@echo _MAKE=%_MAKE%
@echo _MAKE_PROJECT=%_MAKE_PROJECT%
@echo _MAKE_FILE=%_MAKE_FILE%

if %_DISPLAY_HELP% == Y %_help%|more && goto:eof
%_log_info%: Starting %_SCRIPT%

%_log_info%: Done %_SCRIPT%

goto:eof
@REM subroutine parse args
:parse_args
if "%1" == "-h" set _DISPLAY_HELP=Y
if "%1" == "help" set _DISPLAY_HELP=Y
if "%1" == "-m" set _MAKE=Y
if "%1" == "make" set _MAKE=Y
if "%1" == "project" set _MAKE_PROJECT=Y
if "%1" == "file" set _MAKE_FILE=Y
shift
if "[%1]"=="[]" goto:eof
goto:parse_args

::exit /b
%_ex%


mac
@echo off
@REM Testfunctions

@REM utility functions
:make_help
 @echo.>%_HELP_FILE%
 @echo Help for "%_SCRIPT%">>%_HELP_FILE%
 @echo. >>%_HELP_FILE%
 @echo more to follow...>>%_HELP_FILE%
:make_folder
if not "%~1" == "" md %~1


@echo off

@REM Testmacros

if not exist %_HELP_FILE% call :make_help
@REM Variables and Macros
:set_macros
set _ex=exit /b
set _date=
for /f "tokens=2 delims= " %%a in ('@echo %DATE%') do (@echo %%a && set _date=%%a)
set _time=%TIME%
set _m=@echo %_date% %_time%%~1
set _log_info=%_m%    [INFO]
set _log_error=%_m%  [ERROR]
set _help=more %_HELP_FILE%
set _usage=@echo Usage %_SCRIPT% (options) [params]
goto:eof

@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@REM OAD Framework

@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@echo off
setlocal enableextensions
@REM =====================================================================
@REM script variables
set _SCRIPT=%~n0
set _SCRIPTNAME=%0
set _SCRIPTDIR=%~dp0
set _LOGDIR=%_SCRIPTDIR%log
set _LOG_FILE=%_LOGDIR%\%_SCRIPT%.log
set _HELP_FILE=%_SCRIPT%.txt
set _UTILS=%_SCRIPT%utl.cmd
set _MACROS=%_SCRIPT%mac.cmd
set _DEFAULTS=%_SCRIPT%def.cmd
set _FUNCTIONS=%_SCRIPT%fnc.cmd
@REM =====================================================================
@REM calling macros
call %_MACROS%
@REM calling function and utilities on demand (see bottom of script)
@REM
@REM calling defaults
call %_DEFAULTS%
@REM =====================================================================
@REM @echo Params "%*"
@REM =====================================================================
@REM check mandatory parameter
if "[%*]"=="[]" call :_usage & exit /b
@REM Log Dir
if not exist "%_LOGDIR%" call :_make_folder "%_LOGDIR%"
@REM Help File
if not exist "%_HELP_FILE%" call :_make_help
@REM =====================================================================
@REM call arg parser
call :parse_args %*
@REM =====================================================================
@REM --- process results
@REM help
if "%_DISPLAY_HELP%" == "Y" call :_help && goto:eof

@REM all good so far, so...
:continue
@REM

@REM ---------------------------------------------------------------------
%_log_info% Starting %_SCRIPT%
@REM debug call
if "%_DEBUG%" == "TRUE" (
    %_log_debug% Run Variables^[1^]: _DEBUG="%_DEBUG%", _DISPLAY_HELP="%_DISPLAY_HELP%",
    %_log_debug% Run Variables^[2^]: _SET_PROJECT="%_SET_PROJECT%", _SET_PROJECT_NAME="%_SET_PROJECT_NAME%",
    %_log_debug% Run Variables^[3^]: _KEEP_FILES="%_KEEP_FILES%", _CREATE_FOLDER_IF_NOT_EXISTS="%_CREATE_FOLDER_IF_NOT_EXISTS%",
    %_log_debug% Run Variables^[4^]: _MAKE="%_MAKE%", _MAKE_PROJECT="%_MAKE_PROJECT%", _MAKE_PROJECT_NAME="%_MAKE_PROJECT_NAME%",
    %_log_debug% Run Variables^[5^]: _MAKE_FILE="%_MAKE_FILE%", _MAKE_FILE_NAME="%_MAKE_FILE_NAME%",
    %_log_debug% Run Variables^[6^]: _MAKE_FOLDER="%_MAKE_FOLDER%", _MAKE_FOLDER_NAME="%_MAKE_FOLDER_NAME%".
)

%_log_info% ----- Processing
%_log_info% Done %_SCRIPT%
@REM ---------------------------------------------------------------------
@REM
@REM Skip all SUB ROUTINES
goto:eof

@REM ================ SUB ROUTINES ================

@REM Parse Args (kept here, since script specific)
:parse_args
@REM help
if "%1" == "-h"              set "_DISPLAY_HELP=Y" && goto:eof
if "%1" == "-?"              set "_DISPLAY_HELP=Y" && goto:eof
if "%1" == "help"            set "_DISPLAY_HELP=Y" && goto:eof
@REM debug
if "%1" == "-d"              set _DEBUG=TRUE
if "%1" == "debug"           set _DEBUG=TRUE
@REM set options (if mutually exclusive - goto:eof)
if "%1" == "-sp"             set "_SET_PROJECT=Y"  && set "_SET_PROJECT_NAME=%~2"
if "%1" == "set-project"     set "_SET_PROJECT=Y"  && set "_SET_PROJECT_NAME=%~2"

if "%1" == "-k"              set "_KEEP_FILES=Y"   && set "_KEEP_FILES_METHOD=%~2"
if "%1" == "-cf"             set "_CREATE_FOLDER_IF_NOT_EXISTS=Y"
@REM param1 MAKE
if "%1" == "-m"              set "_MAKE=Y"
if "%1" == "make"            set "_MAKE=Y"
@REM param1 MAKE arguments
if "%1" == "-project"        set "_MAKE_PROJECT=Y" && set "_MAKE_PROJECT_NAME=%~2"
if "%1" == "-folder"         set "_MAKE_FOLDER=Y"  && set "_MAKE_FOLDER_NAME=%~2"
if "%1" == "-file"           set "_MAKE_FILE=Y"    && set "_MAKE_FILE_NAME=%~2"
@REM param2 ""
@REM param2 "" arguments

@REM EO Parse Args
shift
if "[%1]"=="[]" goto:eof
goto:parse_args

@REM =====================================================================
@REM Subroutine Calls in %_FUNCTIONS% and %_UTILS% File
@REM
@REM functions
:_usage
    %_FUNCTIONS% %_SCRIPT%
:_debug_call
    %_FUNCTIONS% %1
:_help
    %_FUNCTIONS% %_HELP_FILE%
@REM utilities
:_make_help
    %_UTILS% %_HELP_FILE%
:_make_folder
    %_UTILS% %_LOGDIR%
goto:eof

@REM reset...
:EOF
popd
endlocal
@REM exit /b
%_ex% %ERRORLEVEL%


@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@REM def
@echo off

@REM Script Defaults
@REM ---------------------------------------------------------------------
@REM Variables
set "_DEFAULT_KEEP_FILES=ARCHIVE"
set "_DEFAULT_CREATE_FOLDER_IF_NOT_EXISTS=TRUE"

@REM exit Variables
%_ex%


@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@REM fnc
@echo off
setlocal enableextensions
@REM Not to be directly called
exit /b 9009

@REM ---------------------------------------------------------------------
@REM Functions

:_usage
    @echo.
    @echo.Usage: %~1 (options) [params]. Type %~1 -h for more information.
    goto:eof

:_help
    more %~1
    goto:eof

:_debug_call
    %_log_debug% %~1
    goto:eof

@REM exit Functions
%_ex%


@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@REM mac
@echo off
@REM Macros and Variables
set _ex=exit /b
set _date=
for /f "tokens=1* delims= " %%a in ('@echo %DATE%') do (set _date=%%a)
set _time=
:: %TIME%
for /f "tokens=1 delims=," %%b in ('@echo %TIME%') do (set _time=%%b)
@REM Messages
set _m=@echo %_date% %_time%%~1
set _log_info=%_m%----[INFO]:
set _log_error=%_m%---[ERROR]:
set _log_warn=%_m%-[WARNING]:
set _log_debug=%_m%---[DEBUG]:
@REM Exit Macros
%_ex%


@REM @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@REM utl

@echo off
setlocal enableextensions
@REM Not to be directly called
exit /b 9009

@REM ---------------------------------------------------------------------
@REM Utilities

:_make_help
    @echo.>%_HELP_FILE%
    @echo.         Help for "%_SCRIPT%">>%_HELP_FILE%
    @echo.>>%_HELP_FILE%
    @echo  more help will follow...>>%_HELP_FILE%
    goto:eof

:_make_folder
    if not "%~1" == "" (
        %_log_info% Making Directory %~1
        md %~1>nul
    )

%_ex%

@REM EOF



