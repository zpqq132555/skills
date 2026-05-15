@echo off
setlocal

set "SKILLS_DIR=%~dp0"
if "%SKILLS_DIR:~-1%"=="\" set "SKILLS_DIR=%SKILLS_DIR:~0,-1%"

for %%A in ("%SKILLS_DIR%\..") do set "AGENTS_DIR=%%~fA"
for %%A in ("%AGENTS_DIR%\..") do set "ROOT_DIR=%%~fA"

echo skills dir  : %SKILLS_DIR%
echo root dir    : %ROOT_DIR%
echo.

set "SOURCE=%SKILLS_DIR%\AGENTS_BAK.md"
set "LINK_CODEX=%ROOT_DIR%\.codex\AGENTS.md"
set "LINK_CLAUDE=%ROOT_DIR%\.claude\CLAUDE.md"

if not exist "%SOURCE%" (
    echo ERROR: AGENTS_BAK.md not found!
    echo        %SOURCE%
    goto :end
)

echo source: %SOURCE%
echo.

if exist "%LINK_CODEX%" (
    echo SKIP: .codex\AGENTS.md already exists
) else (
    mklink /H "%LINK_CODEX%" "%SOURCE%"
    if errorlevel 1 (
        echo FAIL: create .codex\AGENTS.md hardlink
    ) else (
        echo OK: .codex\AGENTS.md created
    )
)

echo.

if exist "%LINK_CLAUDE%" (
    echo SKIP: .claude\CLAUDE.md already exists
) else (
    mklink /H "%LINK_CLAUDE%" "%SOURCE%"
    if errorlevel 1 (
        echo FAIL: create .claude\CLAUDE.md hardlink
    ) else (
        echo OK: .claude\CLAUDE.md created
    )
)

:end
echo.
pause
endlocal
