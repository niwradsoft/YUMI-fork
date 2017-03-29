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

; ------------- DriveStuff -------------

!macro Write2mbrid String File
 Push "${String}"
 Push "${File}"
 Call Write2mbrid
!macroend  
!define Write2mbrid "!insertmacro Write2mbrid"

Function "MBRID" ; Let's Get the MBRID for OpenSUSE
 Call PhysDrive ; Get the Hard Disk Number from the Drive Letter
 nsexec::exectostack "wmic /NAMESPACE:\\root\CIMV2 path Win32_DiskDrive where name='\\\\.\\PHYSICALDRIVE$0' get Signature /VALUE" ; Use WMIC to get the PhysicalDrive Signature
 pop $0
 pop $1 ; Signature is stored here

 StrCpy $OnlyVal "$1" "" 16 ; = Get the Decimal Value only, remove preceeding Signature=
 IntFmt $OnlyVal "0x%08X" $OnlyVal ; Convert the value from Decimal to Hexadecimal - was 0x%X - fixed using 0x%08X for 10 character
 ${StrFilter} "$OnlyVal" "-" "" "" $OnlyVal ; Convert the Hexadecimal value to lower case
 Rename "$BootDir\multiboot\$SUSEDIR\boot\grub\mbrid" "$BootDir\multiboot\$SUSEDIR\boot\grub\old-mbrid"
 ${Write2mbrid} "$OnlyVal" $R0
FunctionEnd

Function PhysDrive
 StrCpy $1 "$JustDrive"
 Push $1
 Call HDDNumber      
FunctionEnd

; Function PhysDrive2
 ; StrCpy $1 "$JustDrive"
 ; Push $1
 ; Call Dismount_Volume    
; FunctionEnd

; Function PhysDrive3
 ; StrCpy $1 "$JustDrive"
 ; Push $1
 ; Call Unlock_Volume    
; FunctionEnd

; WriteToFile Function originally written by Afrow UK http://nsis.sourceforge.net/Simple_write_text_to_file, modified by Lance http://www.pendrivelinux.com to populate .cfg file with what the user chose!
Function Write2mbrid
 Exch $R0 ;file to write to
 Exch
 Exch $1 ;text to write
 FileOpen $R0 '$BootDir\multiboot\$SUSEDIR\boot\grub\mbrid' a  ;FileOpen $R0 '$BootDir\multiboot\menu\$Config2Use' a 
 FileSeek $R0 0 END
 FileWrite $R0 '$1'
 FileClose $R0
 Pop $1
 Pop $R0
FunctionEnd

; The following code was found here: http://forums.winamp.com/showthread.php?t=317579
; File Access Modes
!define GENERIC_READ         0x80000000
!define GENERIC_WRITE        0x40000000

; File Sharing Modes
!define FILE_SHARE_READ      0x00000001
!define FILE_SHARE_WRITE     0x00000002

; File Creation Flags
!define OPEN_EXISTING        3
!define INVALID_HANDLE_VALUE -1

; Maximum length of volume GUID (including terminating zero)
!define MAXLEN_VOLUME_GUID   51

; I/O control command
!define IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS   0x00560000
!define EXTENTS_BUFFER_SIZE  512

; Dismount_Volume
!define FSCTL_DISMOUNT_VOLUME 0x00090020

; Lock_Volume
!define FSCTL_LOCK_VOLUME 0x00090018

; Unlock_Volume
!define FSCTL_UNLOCK_VOLUME 0x0009001c

; Get hard disk number from drive letter
; provided as a parameter to this function.
; The hard disk number is returned in $0.
Function HDDNumber
  ; Save registers
  Exch $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6
  Push $7
  ; Get volume name associated with drive letter
  System::Call "kernel32::GetVolumeNameForVolumeMountPoint(t r1, t r3r3, i ${MAXLEN_VOLUME_GUID}) i.r2"
  ${If} $2 != 0
     ; Get handle of volume
     StrCpy $3 $3 -1
     System::Call "kernel32::CreateFile(t r3, \\
       i ${GENERIC_READ}|${GENERIC_WRITE}, \\
       i ${FILE_SHARE_READ}|${FILE_SHARE_WRITE}, \\
       i 0, i ${OPEN_EXISTING}, i 0, i 0) i.r2"
     ${If} $2 != ${INVALID_HANDLE_VALUE}
        ; Allocate output buffer
        System::Alloc ${EXTENTS_BUFFER_SIZE}
        Pop $4
        IntOp $5 0 + 0
        ; Send IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS command
        System::Call "kernel32::DeviceIoControl(i r2, \\
            i ${IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS}, \\
            i 0, i 0, \\
            i r4, i ${EXTENTS_BUFFER_SIZE}, \\
            *i r5r5, i 0) i.r3"
        ${If} $3 != 0
           ; Extract HDD number
           System::Call "*$4(i .r5, i, i .r0)"
           ${If} $5 == 0
               StrCpy $0 "Error: Invalid DISK_EXTENT data"
           ${EndIf}
        ${Else}
           StrCpy $0 "Error: DeviceIoControl failed"
        ${EndIf}
        System::Free $4
        System::Call "kernel32::CloseHandle(i r2) i.r3"
     ${Else}
        StrCpy $0 "Error: CreateFile failed for $3"
     ${EndIf}
  ${Else}
    StrCpy $0 "Error: GetVolumeNameForVolumeMountPoint failed for $1"
  ${EndIf}
  ; Restore registers
  Pop $7
  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
FunctionEnd

; ; Lock and Dismount to allow I/O Access
; Function Dismount_Volume
  ; ; Save registers
  ; Exch $1
  ; Push $2
  ; Push $3
  ; Push $4
  ; Push $5   

  ; ; Get volume name associated with drive letter
  ; System::Call "kernel32::GetVolumeNameForVolumeMountPoint(t r1, t r3r3, i ${MAXLEN_VOLUME_GUID}) i.r2"
  ; ${If} $2 != 0
     ; ; Get handle of volume
     ; StrCpy $3 $3 -1
	 ; StrCpy $VolMountPoint $3
	; ; MessageBox MB_ICONSTOP|MB_OK "Volume $VolMountPoint"
     ; System::Call "kernel32::CreateFile(t r3, \\
       ; i ${GENERIC_READ}|${GENERIC_WRITE}, \\
       ; i ${FILE_SHARE_READ}|${FILE_SHARE_WRITE}, \\
       ; i 0, i ${OPEN_EXISTING}, i 0, i 0) i.r2" 
	   ; ;MessageBox MB_ICONSTOP|MB_OK "$2 = ${INVALID_HANDLE_VALUE} test_dismount"
    ; ${If} $2 != ${INVALID_HANDLE_VALUE}		 
	    ; ; Send FSCTL_LOCK_VOLUME command		   
        ; System::Call "kernel32::DeviceIoControl(i r2, \\
            ; i ${FSCTL_LOCK_VOLUME}, \\
            ; i 0, i 0, \\
            ; i 0, i ${EXTENTS_BUFFER_SIZE}, \\
            ; i 0, i 0) i.r3"	
	    ; DetailPrint "Volume Locked"
    ; ${Else}			
	    ; DetailPrint "Error Opening Volume"
	    ; ; Send FSCTL_UNLOCK_VOLUME command		   
        ; System::Call "kernel32::DeviceIoControl(i r2, \\
            ; i ${FSCTL_UNLOCK_VOLUME}, \\
            ; i 0, i 0, \\
            ; i 0, i ${EXTENTS_BUFFER_SIZE}, \\
            ; i 0, i 0) i.r3"			
		
		; System::Call "kernel32::CloseHandle(i r2) i.r3" 
	; ${EndIf}	
		
	; ; Send FSCTL_DISMOUNT_VOLUME command		   
        ; System::Call "kernel32::DeviceIoControl(i r2, \\
            ; i ${FSCTL_DISMOUNT_VOLUME}, \\
            ; i 0, i 0, \\
            ; i 0, i ${EXTENTS_BUFFER_SIZE}, \\
            ; i 0, i 0) i.r4"
			
    ; ${If} $4 == 0					
	    ; DetailPrint "Error Opening $4"
		; System::Call "kernel32::CloseHandle(i r2) i.r5" 
		; ;Sleep 1000
    ; ${Else}	
		; DetailPrint "Volume Dismounted"
		; System::Call "kernel32::CloseHandle(i r2) i.r5"
	; ${EndIf}
  ; ${EndIf}
  ; ; Restore registers
  ; Pop $5  
  ; Pop $4
  ; Pop $3
  ; Pop $2
  ; Pop $1
; FunctionEnd 

; ; UnLock volume to allow system to detect it
; Function Unlock_Volume
  ; ; Save registers
  ; Exch $1
  ; Push $2
  ; Push $3
  ; Push $4

  ; ; Get volume name associated with drive letter
  ; System::Call "kernel32::GetVolumeNameForVolumeMountPoint(t r1, t r3r3, i ${MAXLEN_VOLUME_GUID}) i.r2"
  ; ${If} $2 != 0
     ; ; Get handle of volume
     ; StrCpy $3 $3 -1
	 ; StrCpy $VolMountPoint $3
	 ; ;MessageBox MB_ICONSTOP|MB_OK "Volume $VolMountPoint"
	 ; ;MessageBox MB_ICONSTOP|MB_OK "$2 test"
     ; System::Call "kernel32::CreateFile(t r3, \\
       ; i ${GENERIC_READ}|${GENERIC_WRITE}, \\
       ; i ${FILE_SHARE_READ}|${FILE_SHARE_WRITE}, \\
       ; i 0, i ${OPEN_EXISTING}, i 0, i 0) i.r2" 
	   
    ; ${If} $2 != ${INVALID_HANDLE_VALUE}		 
	 ; ;MessageBox MB_ICONSTOP|MB_OK "$2 = ${INVALID_HANDLE_VALUE} test_Unlock_Volume"
	    ; DetailPrint "Unlocking Volume to allow access to it"
	    ; ; Send FSCTL_UNLOCK_VOLUME command		   
        ; System::Call "kernel32::DeviceIoControl(i r2, \\
            ; i ${FSCTL_UNLOCK_VOLUME}, \\
            ; i 0, i 0, \\
            ; i 0, i ${EXTENTS_BUFFER_SIZE}, \\
            ; i 0, i 0) i.r3"			
	; ;---	
	  ; ${If} $3 == 0					
	    ; DetailPrint "Volume Unlocked"
      ; ${Else}	
		; DetailPrint "Error Unlocking Volume"
	  ; ${EndIf}
	; ;---	
		; System::Call "kernel32::CloseHandle(i r2) i.r4" 
	; ${Else}
	 ; ;MessageBox MB_ICONSTOP|MB_OK "$2 test2"
	  ; DetailPrint "Error Getting Volume Name associated with drive letter"
	; ${EndIf}	
	
  ; ${EndIf}
  ; ; Restore registers
  ; Pop $4
  ; Pop $3
  ; Pop $2
  ; Pop $1
; FunctionEnd 