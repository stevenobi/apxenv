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


