;!/usr/bin/makensis

; This NSIS script creates an installer for OpenOCD on Windows.
; Based on similar script used for GNU MCU Eclipse QEMU.

; Copyright (C) 2006-2012 Stefan Weil
; Copyright (C) 2015 Liviu Ionescu
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 2 of the License, or
; (at your option) version 3 or any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; NSIS_WIN32_MAKENSIS

!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!include "MUI2.nsh"

!define PUBLISHER                 "GNU MCU Eclipse"
!define PRODUCT                   "RISC-V Embedded GCC"
!define PRODUCTLOWERCASE          "riscv-none-gcc"
!define URL                       "http://gnu-mcu-eclipse.github.io"

; Single instance, each new install will overwrite the values
!define INSTALL_KEY_FOLDER "SOFTWARE\${PUBLISHER}\${PRODUCT}"

; Unique for each 32/64-bits.
!define PERSISTENT_KEY_FOLDER "SOFTWARE\${PUBLISHER}\Persistent\${PRODUCT} ${BITS}"

; https://msdn.microsoft.com/en-us/library/aa372105(v=vs.85).aspx
; Instead of GUID, use a long key, unique for each version
!define UNINSTALL_KEY_FOLDER "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PUBLISHER} ${PRODUCT} ${BITS} ${VERSION}"

!define UNINSTALL_KEY_NAME "UninstallString"
!define UNINSTALL_EXE "$INSTDIR\uninstall.exe"

!define INSTALL_LOCATION_KEY_NAME "InstallLocation"

!define DISPLAY_KEY_NAME "DisplayName"
!define DISPLAY_VALUE "${PUBLISHER} ${PRODUCT}"

!define VERSION_KEY_NAME "Version"
!define VERSION_VALUE "${VERSION}"

!define CONTACT_KEY_NAME "Contact"
!define CONTACT_VALUE "Liviu Ionescu <ilg@livius.net>"

!define URL_KEY_NAME "URLInfoAbout"
!define URL_VALUE "${URL}"


; Sub-folder in $SMPROGRAMS where to store links.
; Dont't know if still in use by current Windows.
!define LINK_FOLDER "${PUBLISHER}\${PRODUCT}"


; Use maximum compression.
SetCompressor /SOLID lzma

; The name of the installer.
Name "${PUBLISHER} ${PRODUCT}"

; The file to write
OutFile "${OUTFILE}"

; The default installation directory.
!ifdef W64
InstallDir "$PROGRAMFILES64\${PUBLISHER}\${PRODUCT}"
!else
InstallDir "$PROGRAMFILES\${PUBLISHER}\${PRODUCT}"
!endif

; Request administrator privileges for Windows Vista.
RequestExecutionLevel admin

;--------------------------------
; Preserve the parent of the install folder. Set in .onInit.
Var Parent.INSTDIR

;--------------------------------
; Interface Settings.

!define MUI_ICON "${NSIS_FOLDER}\nsis.ico"
!define MUI_UNICON "${NSIS_FOLDER}\nsis.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSIS_FOLDER}\nsis.bmp"

;--------------------------------
; Pages.

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${INSTALL_FOLDER}\licenses\LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_LINK "Visit the ${PUBLISHER} site!"
!define MUI_FINISHPAGE_LINK_LOCATION "${URL}"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages.

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"

;--------------------------------

; The stuff to install.
Section "${PRODUCT} (required)"

SectionIn RO

; Preserve the parent of the install folder, without version.
${GetParent} "$INSTDIR" $Parent.INSTDIR

; Set output path to the installation directory.
SetOutPath "$INSTDIR\"
; Copy everything in one command.
File /r "${INSTALL_FOLDER}\*"

; Write the uninstaller file.
WriteUninstaller "${UNINSTALL_EXE}"

!ifdef W64
  SetRegView 64
!endif

; Write the installation path into the registry.
; 32/64 will overwrite each other, the last one will survive.
WriteRegStr HKLM "${INSTALL_KEY_FOLDER}" "${INSTALL_LOCATION_KEY_NAME}" "$INSTDIR"
WriteRegStr HKLM "${INSTALL_KEY_FOLDER}" "${DISPLAY_KEY_NAME}" "${DISPLAY_VALUE}"
WriteRegStr HKLM "${INSTALL_KEY_FOLDER}" "${VERSION_KEY_NAME}" "${VERSION_VALUE}"
WriteRegStr HKLM "${INSTALL_KEY_FOLDER}" "${CONTACT_KEY_NAME}" "${CONTACT_VALUE}"
WriteRegStr HKLM "${INSTALL_KEY_FOLDER}" "${URL_KEY_NAME}" "${URL_VALUE}"

; Write the parent installation path into the registry persistent storage.
; 32/64 are different, will not overwrite each other.
WriteRegStr HKLM "${PERSISTENT_KEY_FOLDER}" "${INSTALL_LOCATION_KEY_NAME}" "$Parent.INSTDIR"

; Write the uninstall keys for Windows.
WriteRegStr HKLM "${UNINSTALL_KEY_FOLDER}" "${UNINSTALL_KEY_NAME}" "${UNINSTALL_EXE}"
WriteRegStr HKLM "${UNINSTALL_KEY_FOLDER}" "${INSTALL_LOCATION_KEY_NAME}" "$INSTDIR"
WriteRegStr HKLM "${UNINSTALL_KEY_FOLDER}" "${DISPLAY_KEY_NAME}" "${DISPLAY_VALUE}"
WriteRegStr HKLM "${UNINSTALL_KEY_FOLDER}" "${VERSION_KEY_NAME}" "${VERSION_VALUE}"
WriteRegStr HKLM "${UNINSTALL_KEY_FOLDER}" "${CONTACT_KEY_NAME}" "${CONTACT_VALUE}"
WriteRegStr HKLM "${UNINSTALL_KEY_FOLDER}" "${URL_KEY_NAME}" "${URL_VALUE}"
WriteRegDWORD HKLM "${UNINSTALL_KEY_FOLDER}" "NoModify" 1
WriteRegDWORD HKLM "${UNINSTALL_KEY_FOLDER}" "NoRepair" 1

SectionEnd

; Optional section (can be disabled by the user).
Section "Start Menu Shortcuts" SectionMenu
CreateDirectory "$SMPROGRAMS\${LINK_FOLDER}"
CreateShortCut "$SMPROGRAMS\${LINK_FOLDER}\Uninstall.lnk" "${UNINSTALL_EXE}" "" "${UNINSTALL_EXE}" 0
SectionEnd

;--------------------------------

Var ux.path
Var ix.path

;--------------------------------

; Uninstaller

Section "Uninstall"

!ifdef W64
  SetRegView 64
!endif

ReadRegStr $ux.path HKLM "${UNINSTALL_KEY_FOLDER}" "${INSTALL_LOCATION_KEY_NAME}"
${if} "$ux.path" == "" 
  ReadRegStr $ux.path HKLM "${UNINSTALL_KEY_FOLDER}" "${UNINSTALL_KEY_NAME}"
  ${GetParent} "$ux.path" $ux.path
${endif}

ReadRegStr $ix.path HKLM "${INSTALL_KEY_FOLDER}" "${INSTALL_LOCATION_KEY_NAME}"

; If this refers to the last install, remove the install keys.
${if} "$ux.path" == "$ix.path"

  ; MessageBox MB_OK|MB_ICONSTOP "remove all install keys"

  ; Remove the entire group of install keys.
  DeleteRegKey HKLM "${INSTALL_KEY_FOLDER}"

  ; Remove shortcuts, if any.
  Delete "$SMPROGRAMS\${LINK_FOLDER}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${LINK_FOLDER}"

${endif}

; MessageBox MB_OK|MB_ICONSTOP "${UNINSTALL_KEY_FOLDER}"

; Remove the entire group of uninstall keys.
DeleteRegKey HKLM "${UNINSTALL_KEY_FOLDER}"

; As the name implies, the PERSISTENT_KEY_FOLDER must NOT be removed.

; Remove uninstaller executable.
Delete "${UNINSTALL_EXE}"

; Remove files and directories used. Do not append version here, since is
; already present in the variable, it was remembered from te setup.
SetOutPath "$Parent.INSTDIR"
RMDir /r "$INSTDIR"

SectionEnd

;--------------------------------

; Descriptions (mouse-over).
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN

; !insertmacro MUI_DESCRIPTION_TEXT ${SectionScripts}	"TCL scripts."
; !insertmacro MUI_DESCRIPTION_TEXT ${SectionDll}		"Runtime Libraries (DLL)."
; !insertmacro MUI_DESCRIPTION_TEXT ${SectionDoc}		"Documentation."
; !insertmacro MUI_DESCRIPTION_TEXT ${SectionContrib}	"Contributed."
!insertmacro MUI_DESCRIPTION_TEXT ${SectionMenu}	"Menu entries."

!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Functions.

Function .onInit

  !ifdef W64
    ${IfNot} ${RunningX64}
      MessageBox MB_OK|MB_ICONEXCLAMATION "This setup can only be run on 64-bit Windows" 
   	  Abort   
    ${EndIf}
  !endif

  !insertmacro MUI_LANGDLL_DISPLAY

  ; Check registry key for previous folder. The key is distinct for 32/64-bits.
  ReadRegStr $INSTDIR HKLM "${PERSISTENT_KEY_FOLDER}" "${INSTALL_LOCATION_KEY_NAME}"

  ${if} $INSTDIR == ""
    ; The default installation folder, if the key was not found.
    !ifdef W64
      StrCpy $INSTDIR "$PROGRAMFILES64\${PUBLISHER}\${PRODUCT}"
    !else
      StrCpy $INSTDIR "$PROGRAMFILES\${PUBLISHER}\${PRODUCT}"
    !endif
  ${endif}

  ; Append the version, to be seen in the wizard. 
  StrCpy $INSTDIR "$INSTDIR\${VERSION}"

FunctionEnd

Function un.onInit
  ;
FunctionEnd

