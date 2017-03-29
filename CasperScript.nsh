/*
 * This file is part of YUMI
 *
 * YUMI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * any later version.
 *
 * YUMI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with YUMI.  If not, see <http://www.gnu.org/licenses/>.
 */

; ------------ Casper Script --------------
/* Function CasperScript
${If} $Casper != "0"
 Call GetCaspTools
  ${If} $DistroName == "Debian Live"
  nsExec::ExecToLog '"$PLUGINSDIR\dd.exe" if=/dev/zero of=$BootDir\multiboot\$JustISOName\live-rw bs=1M count=$Casper --progress'
  nsExec::ExecToLog '"$PLUGINSDIR\mke2fs.exe" -L live-rw $BootDir\multiboot\$JustISOName\live-rw'	; was using -b 1024
  ${Else}
  nsExec::ExecToLog '"$PLUGINSDIR\dd.exe" if=/dev/zero of=$BootDir\multiboot\$JustISOName\casper-rw bs=1M count=$Casper --progress'
  nsExec::ExecToLog '"$PLUGINSDIR\mke2fs.exe" -L casper-rw $BootDir\multiboot\$JustISOName\casper-rw'	; was using -b 1024
  ${EndIf} 
${EndIf}
FunctionEnd */

/* Function CasperScriptAlt ; We have to create the casper-rw file locally, and then copy to USB to avoid contigous errors
${If} $Casper != "0"
 Call GetCaspTools
  ${If} $DistroName == "Debian Live"
  ExecWait '"$PLUGINSDIR\dd.exe" if=/dev/zero of=$BootDir\multiboot\$JustISOName\live-rw bs=1M count=$Casper --progress'
  nsExec::ExecToLog '"$PLUGINSDIR\mke2fs.exe" -L live-rw $BootDir\multiboot\$JustISOName\live-rw'	; was using -b 1024
  ${Else}
  ExecWait '"$PLUGINSDIR\dd.exe" if=/dev/zero of=$EXEDIR\casper-rw bs=1M count=$Casper --progress' ; was nsExec::ExecToLog
  nsExec::ExecToLog '"$PLUGINSDIR\mke2fs.exe" -L casper-rw $EXEDIR\casper-rw'
  CopyFiles $EXEDIR\casper-rw "$BootDir\multiboot\$JustISOName\casper-rw" ; Copy casper-rw to ISO Path on USB
  Delete $EXEDIR\casper-rw
  ;nsExec::ExecToLog '"$PLUGINSDIR\mke2fs.exe" -L casper-rw $DestDisk\casper-rw'
  ${EndIf} 
${EndIf}
FunctionEnd */

Function CasperScriptAlt1
${If} $Casper != "0"
 Call GetCaspTools
 
  ${If} $DistroName == "Debian Live"
  StrCpy $CasperName "live-rw"
  ${Else}
  StrCpy $CasperName "casper-rw"
  ${EndIf} 
  
 SetShellVarContext all
 InitPluginsDir
 ExpandEnvStrings $COMSPEC "%COMSPEC%"
 ExecShell "" '"$COMSPEC"' '/C if 1==1 "dd.exe" if=/dev/zero of=$PLUGINSDIR\$CasperName bs=1M count=$Casper --progress 2>$PLUGINSDIR\ddlog.txt' SW_HIDE
 Banner::show /set 76 "Creating a Persistent File."
 Banner::getWindow
 Pop $1  
 DetailPrint "Creating a persistent file. Progress will not move until finished..."
 Call ddProgress
 Banner::destroy
 
 nsExec::ExecToLog '"$PLUGINSDIR\mke2fs.exe" -L $CasperName $PLUGINSDIR\$CasperName'
 CopyFiles $PLUGINSDIR\$CasperName "$BootDir\multiboot\$JustISOName\$CasperName" ; Copy casper-rw to USB
 Delete "$PLUGINSDIR\$CasperName"
${EndIf}
FunctionEnd

Function CasperSize
 IntOp $SizeOfCasper $SizeOfCasper + $Casper
FunctionEnd

Function GetCaspTools
SetShellVarContext all
InitPluginsDir
File /oname=$PLUGINSDIR\dd.exe "dd.exe"
File /oname=$PLUGINSDIR\mke2fs.exe "mke2fs.exe"
DetailPrint "Now Creating a Casper RW File" 
DetailPrint "Creating the Persistent File: The progress bar will not move until finished. Please be patient..." 
FunctionEnd