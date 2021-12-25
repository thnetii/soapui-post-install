[CmdletBinding()]
param (
    [Alias("PSPath")]
    [Alias("LiteralPath")]
    [string]$Path
)

if (-not $Path) {
    $Path = switch ((Join-Path "." "soapui.bat"), (Join-Path "." (Join-Path "bin" "soapui.bat")), (Get-Command -CommandType Application "soapui" -ErrorAction Stop).Source) {
        { Test-Path -PathType Leaf $_ } {
            Resolve-Path $_
            break
        }
    }
}
elseif (Test-Path -PathType Container $Path) {
    $Path = switch ((Join-Path $Path "soapui.bat"), (Join-Path $Path (Join-Path "bin" "soapui.bat"))) {
        { Test-Path -PathType Leaf $_ } {
            Resolve-Path $_
            break
        }
    }
}

[string[]]$SoapUiBatContents = Get-Content $Path -ErrorAction Stop
$SoapUiBatContents = switch ($SoapUiBatContents) {
    "`"%JAVA%`" -cp `"%CLASSPATH%`" com.eviware.soapui.tools.JfxrtLocator > %TEMP%\jfxrtpath" {
        "rem " + $_
        "for /F `"tokens=*`" %%j in ('^`"`"%JAVA%`" -cp `"%CLASSPATH%`" com.eviware.soapui.tools.JfxrtLocator^`"') do set JFXRTPATH=%%j"
        continue
    }
    { $_ -in "set OLDDIR=%CD%", `
        "cd /d %SOAPUI_HOME%", `
        "cd /d %OLDDIR%", `
        "set /P JFXRTPATH= < %TEMP%\jfxrtpath", `
        "del %TEMP%\jfxrtpath" } {
        "rem " + $_
        continue
    }
    "`"%JAVA%`" %JAVA_OPTS% -cp `"%CLASSPATH%`" com.eviware.soapui.SoapUI %*" {
        $_ -replace "`"%JAVA%`" ", "start `"SoapUI-5.6.1`" `"%JAVA%`"w "
        continue
    }
    { $_ -like "*-splash:SoapUI-Spashscreen.png*" } {
        $_ -replace "-splash:SoapUI-Spashscreen.png", "-splash:`"%SOAPUI_HOME%\SoapUI-Spashscreen.png`""
    }
    default { $_ }
}
Set-Content $Path $SoapUiBatContents -Force -ErrorAction Stop
