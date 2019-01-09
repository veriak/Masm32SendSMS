;----------------------------------------------------------------------------------------
; ComPort and Send SMS Masm32 Library
;
; Copyright 2006 Veria Kalantary
; veria.kalantary@gmail.com
; https://github.com/veriak
;
;----------------------------------------------------------------------------------------

.386
.model flat, stdcall
option casemap:none 
.NOLIST  

include     \masm32\include\windows.inc
include     \masm32\include\user32.inc
include     \masm32\include\kernel32.inc
include		\masm32\include\masm32.inc
include     \masm32\include\advapi32.inc
include     \masm32\include\oleaut32.inc
include     \masm32\include\ole32.inc

include     \masm32\COM\include\oaidl.inc

includelib  \masm32\lib\user32.lib
includelib  \masm32\lib\kernel32.lib
includelib  \masm32\lib\masm32.lib
includelib  \masm32\lib\advapi32.lib
includelib  \masm32\lib\oleaut32.lib
includelib  \masm32\lib\ole32.lib

.LISTALL 

mycomethod6Proto      typedef proto :DWORD, :DWORD, :DWORD, :BYTE, :BYTE, :BYTE
mycomethod6           typedef ptr mycomethod6Proto

sIID_IIoECommComponent      TEXTEQU   <{0D8914E11H, 00D10H, 0436FH,     \ 
                             	{0BAH, 0CAH, 062H, 092H, 02DH, 07BH, 08FH, 010H}}>
                             	
sLIBID_IoECommComponentApp  TEXTEQU   <{02CB75893H, 08FB5H, 047DBH,     \ 
                             	{0A4H, 0CBH, 0E3H, 09BH, 034H, 08CH, 0D2H, 061H}}>
                            	                             	
sCLSID_IoECommComponent		TEXTEQU   <{0BEE3624AH, 05AF4H, 04982H,     \ 
                             	{097H, 039H, 06CH, 096H, 025H, 04CH, 0D6H, 099H}}>

_vtIIoECommComponent MACRO CastName:REQ
    _vtIUnknown CastName    
    &CastName&_OpenCommPort   comethod2   ?
    &CastName&_SetCommPort	  mycomethod6 ?	
    &CastName&_WriteCommPort  comethod3  ?
    &CastName&_WriteSMS   	  comethod4   ?
    &CastName&_SetReadCommCommand   comethod7   ?
ENDM

IIoECommComponent		 STRUCT
    _vtIIoECommComponent IIoECommComponent
IIoECommComponent       ENDS

DllRegisterServer       PROTO 
DllCanUnloadNow         PROTO
DllGetClassObject       PROTO :DWORD, :DWORD, :DWORD
DllUnregisterServer     PROTO 

QueryInterface_CF       PROTO :DWORD, :DWORD, :DWORD
AddRef_CF               PROTO :DWORD
Release_CF              PROTO :DWORD
QueryInterface_MC       PROTO :DWORD, :DWORD, :DWORD
AddRef_MC               PROTO :DWORD
Release_MC              PROTO :DWORD

CreateInstance PROTO :DWORD, :DWORD, :DWORD, :DWORD
OpenCommPort PROTO :DWORD, :DWORD
SetCommPort PROTO :DWORD, :DWORD, :DWORD, :BYTE, :BYTE, :BYTE
WriteCommPort PROTO :DWORD, :DWORD, :DWORD
WriteSMS PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetReadCommCommand PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

CreateMyComObject       PROTO 
GuardedDeleteKey        PROTO :DWORD, :DWORD

memset PROTO :DWORD, :BYTE, :DWORD
memcpy PROTO :DWORD, :DWORD, :DWORD
HexStr PROTO :DWORD, :DWORD
Swap PROTO :DWORD
str2pdu PROTO :DWORD, :DWORD
 

StrM macro data:vararg
	LOCAL buff
.data
	buff db data, 0
	
.code
 	exitm <addr buff>
 	
endm

StructSetReadComm STRUCT
	hCom			DWORD	?
	dwResponseType	DWORD	?
	hResWnd			DWORD	?
	dwResponse		DWORD	?
	lpBuff			DWORD	?
	BuffSize		DWORD	?
StructSetReadComm ENDS

ClassFactoryObject  STRUCT       
    lpVtbl          DWORD       0    
    nRefCount       DWORD       1  
ClassFactoryObject  ENDS

MyComObject         STRUCT       
    lpVtbl          DWORD       0    
    nRefCount       DWORD       1  
    nValue          DWORD       0  
MyComObject         ENDS


.const 
	rtEventModel	EQU		0
	rtMessageModel	EQU		1

	
.data

vtIClassFactory   IClassFactory     <   QueryInterface_CF,      \
                                        AddRef_CF,              \
                                        Release_CF,             \
                                        CreateInstance,         \
                                        LockServer       >

vtIIoECommComponent  IIoECommComponent  <   QueryInterface_MC, AddRef_MC,              \
                                        Release_MC, OpenCommPort,           \
                                        SetCommPort,            \
                                        WriteCommPort,			\
                                        WriteSMS,				\
                                        SetReadCommCommand      >

MyCFObject        ClassFactoryObject<   OFFSET vtIClassFactory, \
                                        0                >

IID_IIoECommComponent	GUID    sIID_IIoECommComponent
CLSID_IoECommComponent  GUID    sCLSID_IoECommComponent
TYPELIB_IoECommComponentApp    GUID    sLIBID_IoECommComponentApp
IID_IUnknown        GUID    sIID_IUnknown
IID_IClassFactory   GUID    sIID_IClassFactory

g_hDllMain          DWORD   0       

szSampleDesc        BYTE    "IoE Com port communication Component", 0
szInprocServer32    BYTE    "InprocServer32", 0
szSampleProgID      BYTE    "CIoECommComponent", 0
szProgID            BYTE    "CIoECommComponent", 0
szThreadModel       BYTE    "ThreadingModel", 0
szThreadType        BYTE    "Both", 0
szCLSID             BYTE    "CLSID", 0


.data?	
	hDll		DWORD	?
	ThreadID 	DWORD 	? 
	ComEventMask DWORD  ?	
	objSetReadComm StructSetReadComm <?>
	HexPDUBuff	db	512 dup(?)
	PDUBuff		db	256 dup(?)
	SMSBuff		db	512	dup(?)
	tempBuff	db	512 dup(?)
	tempWBuff	db	1024 dup(?)
	len			db	?
	src8buff	db	9	dup(?) 
	dest7buff	db  8	dup(?)
	strATCommand db 512 dup(?)	
	ReadBuff    db  512 dup(?)
	RecvEvent   HANDLE	?	

	
.code

DllMain PROC hModule:HANDLE, dwReason:DWORD, lpReserved:DWORD
    .IF dwReason == DLL_PROCESS_ATTACH
        mov eax, hModule
        mov g_hDllMain, eax
        mov eax, TRUE
    .ELSEIF
        mov eax, FALSE
    .ENDIF
    ret
DllMain Endp

DllCanUnloadNow PROC
    .IF (MyCFObject.nRefCount == 0)
        mov eax, TRUE
    .ELSEIF
        mov eax, FALSE
    .ENDIF
    ret
DllCanUnloadNow Endp

DllGetClassObject PROC pCLSID:DWORD, pIID:DWORD, ppv:DWORD
    LOCAL   hr        :DWORD
    LOCAL   pFactory  :DWORD

    invoke  IsEqualGUID, pCLSID, addr CLSID_IoECommComponent
    .IF (eax == TRUE)
        mov eax, OFFSET MyCFObject        
        invoke QueryInterface_CF, eax, pIID, ppv        
        mov hr, eax        
        invoke Release_CF, OFFSET MyCFObject
    .ELSE
        mov hr, CLASS_E_CLASSNOTAVAILABLE
    .ENDIF  
    mov eax, hr    
    ret
DllGetClassObject Endp

DllRegisterServer PROC
    LOCAL   hKey    :DWORD
    LOCAL   hKey2   :DWORD
    LOCAL   hKey3   :DWORD
    LOCAL   sBuf    [MAX_PATH]:BYTE
    LOCAL   wsBuf   [MAX_PATH]:WORD
    LOCAL   psBuf   :DWORD
    LOCAL   pwsBuf  :DWORD
    LOCAL   pti     :DWORD
        
    lea eax, sBuf
    mov psBuf, eax
    lea eax, wsBuf
    mov pwsBuf, eax    
    invoke RegCreateKey, HKEY_CLASSES_ROOT, ADDR szSampleProgID, ADDR hKey
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    invoke lstrlen, ADDR szSampleDesc    
    invoke RegSetValue,hKey, NULL, REG_SZ, ADDR szSampleDesc, eax
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF      
    invoke RegCreateKey, hKey, ADDR szCLSID, ADDR hKey2
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF       
    invoke StringFromGUID2, ADDR CLSID_IoECommComponent, pwsBuf, MAX_PATH
    invoke WideCharToMultiByte, CP_ACP, 0, pwsBuf, -1, 
                                psBuf, MAX_PATH, NULL, NULL
    invoke lstrlen, psBuf
    invoke RegSetValue, hKey2, NULL, REG_SZ, psBuf, eax
    .IF (eax != ERROR_SUCCESS)
        jmp return
    .ENDIF

    invoke RegCloseKey, hKey
    invoke RegCloseKey, hKey2
    invoke RegCreateKey, HKEY_CLASSES_ROOT, ADDR szCLSID, ADDR hKey    
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    
    invoke RegCreateKey, hKey, psBuf, ADDR hKey2
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    
    invoke lstrlen, ADDR szSampleDesc    
    invoke RegSetValue, hKey2, NULL, REG_SZ, ADDR szSampleDesc, eax
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    
    invoke GetModuleFileName,g_hDllMain, psBuf, MAX_PATH
    .IF (eax == 0) 
        mov eax, 1
        jmp return
    .ENDIF
    
    invoke RegCreateKey, hKey2, ADDR szInprocServer32, ADDR hKey3
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    
    invoke RegSetValue, hKey3, NULL, REG_SZ, psBuf, MAX_PATH
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    
    invoke lstrlen, ADDR szThreadType
    invoke RegSetValueEx, hKey3, ADDR szThreadModel, 0, REG_SZ, ADDR szThreadType, eax
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    invoke RegCloseKey, hKey3
     
    invoke RegCreateKey, hKey2, ADDR szProgID, ADDR hKey3
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    invoke lstrlen, ADDR szSampleProgID
    invoke RegSetValue, hKey3, NULL, REG_SZ, ADDR szSampleProgID, eax
    .IF (eax != ERROR_SUCCESS) 
        jmp return
    .ENDIF
    invoke RegCloseKey, hKey3
    .IF (hKey != 0)
        invoke RegCloseKey, hKey
    .ENDIF    
    .IF (hKey2 != 0)
        invoke RegCloseKey, hKey2
    .ENDIF    
    .IF (hKey3 != 0)
        invoke RegCloseKey, hKey3
    .ENDIF    
    
    Invoke MultiByteToWideChar, CP_ACP, 0, psBuf, -1, pwsBuf, MAX_PATH
    .IF !eax
        mov eax, S_FALSE
        jmp return
    .ENDIF
    lea eax, pti
    Invoke LoadTypeLib, pwsBuf, eax
    .IF (eax != ERROR_SUCCESS)
        mov eax, S_FALSE
        jmp return
    .ENDIF
    
    Invoke RegisterTypeLib, pti, pwsBuf, NULL
    .IF (eax != ERROR_SUCCESS)
        mov eax, S_FALSE
        jmp return
    .ELSE
        mov eax, pti
        mov eax, [eax]
        invoke (IUnknown PTR [eax]).IUnknown_Release, pti
    .ENDIF
    xor eax, eax  
return:
    ret
DllRegisterServer ENDP


DllUnregisterServer PROC
    LOCAL   hSubkey:DWORD
    LOCAL   hSubkey2:DWORD
    LOCAL   sBuf    [MAX_PATH]:BYTE
    LOCAL   psBuf   :DWORD
    LOCAL   wsBuf   [MAX_PATH]:WORD
    LOCAL   pwsBuf  :DWORD

    lea eax, sBuf
    mov psBuf, eax
    lea eax, wsBuf
    mov pwsBuf, eax
    invoke StringFromGUID2, ADDR CLSID_IoECommComponent, pwsBuf, MAX_PATH
    invoke WideCharToMultiByte, CP_ACP, 0, pwsBuf, -1, 
                                psBuf, MAX_PATH, NULL, NULL
    invoke GuardedDeleteKey, HKEY_CLASSES_ROOT, ADDR szSampleProgID
    .IF (eax != ERROR_SUCCESS)        
        jmp return
    .ENDIF
    invoke RegOpenKey, HKEY_CLASSES_ROOT, ADDR szCLSID, ADDR hSubkey
    invoke GuardedDeleteKey, hSubkey, psBuf
    .IF (eax != ERROR_SUCCESS)        
        jmp return
    .ENDIF
    invoke RegCloseKey, hSubkey
    xor eax, eax    
return:    
    ret
DllUnregisterServer ENDP


GuardedDeleteKey PROC hKey:DWORD, lpszSubKey:DWORD
    LOCAL   szSubKeyName    [MAX_PATH+1]:TCHAR
    LOCAL   hSubkey         :DWORD  

    invoke RegOpenKey, hKey, lpszSubKey, ADDR hSubkey
    .IF (eax != ERROR_SUCCESS) 
        mov eax, REGDB_E_INVALIDVALUE
        jmp return
    .ENDIF
KillNextSubkey:    
    
    invoke RegEnumKey, hSubkey, 0, ADDR szSubKeyName, MAX_PATH+1
    .IF (eax != ERROR_NO_MORE_ITEMS)         
        invoke GuardedDeleteKey, hSubkey, ADDR szSubKeyName
        jmp KillNextSubkey
    .ELSE
    .ENDIF
    
    invoke RegCloseKey, hSubkey
    invoke RegDeleteKey, hKey,  lpszSubKey
    .IF (eax == ERROR_SUCCESS) 
        xor eax, eax  
    .ENDIF
return:
    ret
GuardedDeleteKey ENDP

QueryInterface_CF PROC this_:DWORD, pRIID:DWORD,  ppv:DWORD
    LOCAL Match:DWORD

    invoke  IsEqualGUID, pRIID, addr IID_IUnknown
    mov Match, eax
    invoke  IsEqualGUID, pRIID, addr IID_IClassFactory
    or eax, Match    
    .IF (eax == TRUE)  
    
        mov eax, this_          
        mov edx, ppv
        mov [edx], eax       
        invoke AddRef_CF, eax      
        xor eax, eax          
        jmp return
    .ENDIF      
NoInterface:
    mov [ppv], NULL            
                              
    mov eax, E_NOINTERFACE    
return: 
    ret
QueryInterface_CF endp


AddRef_CF proc this_:DWORD
    inc MyCFObject.nRefCount
    mov eax, MyCFObject.nRefCount
    ret       
AddRef_CF endp


Release_CF proc this_:DWORD
    dec MyCFObject.nRefCount  
    mov eax, MyCFObject.nRefCount
    ret    
Release_CF endp


CreateInstance PROC this_:DWORD, pUnknownOuter:DWORD, iid:DWORD, ppv:DWORD
    LOCAL   pMyObject:DWORD
    LOCAL   hr:DWORD
    .IF pUnknownOuter != NULL
        mov eax, CLASS_E_NOAGGREGATION
    .ELSE
        invoke CreateMyComObject
        mov pMyObject, eax
        .IF eax == NULL                
            
            mov eax, E_OUTOFMEMORY
        .ELSE
            inc MyCFObject.nRefCount            
            invoke QueryInterface_MC, pMyObject, iid, ppv
            mov hr, eax
            invoke Release_MC,  pMyObject
        .ENDIF
    .ENDIF
    mov eax, hr
    ret
CreateInstance ENDP


LockServer PROC pif:DWORD, bLockServer:DWORD
    .IF bLockServer == TRUE
        inc MyCFObject.nRefCount
    .ELSE
        dec MyCFObject.nRefCount
    .ENDIF
    mov eax, S_OK
    ret    
LockServer ENDP


CreateMyComObject PROC
    LOCAL   pNewObject:DWORD
    invoke  CoTaskMemAlloc, sizeof MyComObject
    mov pNewObject, eax
    .IF (eax != NULL)
        mov edx, pNewObject
        mov (MyComObject PTR [edx]).lpVtbl, OFFSET vtIIoECommComponent
        mov (MyComObject PTR [edx]).nRefCount, 1
        mov (MyComObject PTR [edx]).nValue, 0
    .ENDIF
    mov eax, pNewObject     
    ret
CreateMyComObject endp

QueryInterface_MC PROC this_:DWORD, pRIID:DWORD,  ppv:DWORD

    LOCAL Match     :DWORD
    LOCAL ppvt      :DWORD

    invoke  IsEqualGUID, pRIID, addr IID_IUnknown
    mov Match, eax
    invoke  IsEqualGUID, pRIID, addr IID_IIoECommComponent
    or eax, Match
    .IF (eax == TRUE)           
        mov eax, this_          
        mov edx, ppv
        mov [edx], eax          
        mov ppvt, eax
        invoke AddRef_MC, ppvt       
        mov eax, S_OK           
        jmp return
    .ENDIF    
    
NoInterface:
    xor eax, eax     
    mov edx, ppv      
    mov [edx], eax   
    mov eax, E_NOINTERFACE   
return: 
    ret
QueryInterface_MC endp


AddRef_MC proc this_:DWORD
    mov eax, this_
    inc (MyComObject ptr [eax]).nRefCount
    mov eax, (MyComObject ptr [eax]).nRefCount
    ret      
AddRef_MC endp


Release_MC proc this_:DWORD
    mov eax, this_
    dec (MyComObject ptr [eax]).nRefCount
    mov eax, (MyComObject ptr [eax]).nRefCount
    .IF (eax == 0)                
        invoke  CoTaskMemFree, this_
        dec MyCFObject.nRefCount
        xor eax, eax    
    .ENDIF
    ret       
Release_MC endp


OpenCommPort PROC uses esi edi ecx edx ebx this_:DWORD, lpszComm:DWORD
	LOCAL hCom:DWORD
	LOCAL portDCB:DCB
	LOCAL ComTimeOuts:COMMTIMEOUTS
	
	invoke WideCharToMultiByte, CP_ACP, 0, lpszComm, -1, 
                                addr tempBuff, MAX_PATH, NULL, NULL	
	invoke CreateFile, addr tempBuff, GENERIC_READ or GENERIC_WRITE,\
							0, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0	
	.if eax == INVALID_HANDLE_VALUE
		invoke MessageBox, 0, StrM("Can't open com port."), 0, MB_OK
		mov eax, 0
		jmp @Exit
	.else
		mov hCom, eax	 
	.endif
	
	invoke memset, addr ComTimeOuts, 0, sizeof COMMTIMEOUTS
	mov ComTimeOuts.ReadIntervalTimeout, MAXDWORD
	invoke SetCommTimeouts, hCom, addr ComTimeOuts
	
	invoke GetCommState, hCom, addr portDCB
	mov portDCB.BaudRate, CBR_19200
    mov portDCB.Parity, NOPARITY
    mov portDCB.StopBits, ONESTOPBIT
    mov portDCB.ByteSize, 8
    mov portDCB.XonChar, 17
  	mov portDCB.XoffChar, 19
  	mov portDCB.ErrorChar, 0
  	mov portDCB.EofChar, 0
  	mov portDCB.EvtChar, 0
  	mov portDCB.XonLim, 1024
  	mov portDCB.XoffLim, 1024
  	mov portDCB.fbits, 1
	invoke SetCommState, hCom, addr portDCB
	invoke SetupComm, hCom, 4096, 2048
	
	invoke CreateEvent, 0, 0, 0, 0
    mov RecvEvent, eax
    
    invoke SetReadCommCommand, this_, hCom, rtEventModel, 0, RecvEvent, addr ReadBuff, sizeof ReadBuff
    	
	mov eax, hCom	
@Exit:	
	ret
OpenCommPort ENDP

SetCommPort PROC uses esi edi ecx edx ebx this_:DWORD, hCom:DWORD, dwBaudRate:DWORD, chParity:BYTE, bByteSize:BYTE, bStopBits:BYTE
	LOCAL portDCB:DCB	
		
	invoke GetCommState, hCom, addr portDCB
	mov eax, dwBaudRate
	mov portDCB.BaudRate, eax
	xor eax, eax
	mov al, chParity
    mov portDCB.Parity, al
    mov al, bStopBits
    mov portDCB.StopBits, al
    mov al, bByteSize    
    mov portDCB.ByteSize, al 
    mov portDCB.XonChar, 17
  	mov portDCB.XoffChar, 19
  	mov portDCB.ErrorChar, 0
  	mov portDCB.EofChar, 0
  	mov portDCB.EvtChar, 0
  	mov portDCB.XonLim, 1024
  	mov portDCB.XoffLim, 1024
  	mov portDCB.fbits, 1
	invoke SetCommState, hCom, addr portDCB	
		
	ret
SetCommPort ENDP

WriteCommPort PROC uses esi edi ecx edx ebx this_:DWORD, hCom:DWORD, lpBuff:DWORD 
	LOCAL dwWrite:dword
	LOCAL WriteEvent:HANDLE
	LOCAL ComWriteOverlapped:OVERLAPPED
	
	invoke CreateEvent, 0, 0, 0, 0
	mov WriteEvent, eax
	
	invoke memset, addr ComWriteOverlapped, 0, sizeof OVERLAPPED
	push WriteEvent
	pop ComWriteOverlapped.hEvent		
    
   	invoke WideCharToMultiByte, CP_ACP, 0, lpBuff, -1, 
                            addr tempBuff, MAX_PATH, NULL, NULL	
	invoke lstrlen, addr tempBuff
	mov ebx, eax
	invoke WriteFile, hCom, addr tempBuff, ebx, addr dwWrite, addr ComWriteOverlapped
	invoke WaitForSingleObject, WriteEvent, 1000
	.if eax != WAIT_OBJECT_0
		mov dwWrite, 0
	.else
		invoke GetOverlappedResult, hCom, addr ComWriteOverlapped, addr dwWrite, 0
		invoke ResetEvent, WriteEvent	
	.endif
	
	mov eax, dwWrite	
	ret
WriteCommPort ENDP
 

WriteSMS PROC uses esi edi ecx edx ebx this_:DWORD, hCom:DWORD, lpMNBuff:DWORD, lpMessageBuff:DWORD 
	LOCAL dwWrite:dword
	LOCAL WriteEvent:HANDLE
	LOCAL ComWriteOverlapped:OVERLAPPED	
	LOCAL RecvFlag:DWORD	
    
    invoke WideCharToMultiByte, CP_ACP, 0, lpMessageBuff, -1, 
                            addr tempBuff, MAX_PATH, NULL, NULL     
    invoke str2pdu, addr tempBuff, addr PDUBuff    
            	
	invoke lstrlen, addr PDUBuff
	mov ecx, eax
	lea esi, PDUBuff
	
	invoke HexStr, esi, ecx
    push eax
    invoke lstrcpy, addr HexPDUBuff, eax                      
    call GlobalFree    
     
    invoke lstrcpy, addr SMSBuff, StrM("001100")
    
    invoke WideCharToMultiByte, CP_ACP, 0, lpMNBuff, -1, 
                            addr tempBuff, MAX_PATH, NULL, NULL                     
    invoke lstrlen, addr tempBuff
    mov ebx, eax
    lea esi, len
    mov byte ptr [esi], bl    
    invoke HexStr, esi, 1
    push eax
    invoke lstrcpy, addr tempBuff, eax
    call GlobalFree            
    invoke lstrcat, addr SMSBuff, addr tempBuff
    invoke lstrcat, addr SMSBuff, StrM("91")
    invoke WideCharToMultiByte, CP_ACP, 0, lpMNBuff, -1, 
                            addr tempBuff, MAX_PATH, NULL, NULL 
    invoke lstrlen, addr tempBuff
    mov bl, 2
    div bl
    .if ah == 1
    	invoke lstrcat, addr tempBuff, StrM("F")
    .endif     
    invoke Swap, addr tempBuff
    invoke lstrcat, addr SMSBuff, addr tempBuff
    invoke lstrcat, addr SMSBuff, StrM("0000AA")

    invoke WideCharToMultiByte, CP_ACP, 0, lpMessageBuff, -1, 
                            addr tempBuff, MAX_PATH, NULL, NULL                         
	invoke lstrlen, addr tempBuff
    mov ebx, eax
    lea esi, len
    mov byte ptr [esi], bl    
    invoke HexStr, esi, 1
    push eax
    invoke lstrcpy, addr tempBuff, eax
    call GlobalFree         
    invoke lstrcat, addr SMSBuff, addr tempBuff 
    invoke lstrcat, addr SMSBuff, addr HexPDUBuff	
    
    invoke lstrcpy, addr strATCommand, StrM("AT+CMGS=")
    
    invoke lstrlen, addr SMSBuff
    dec eax
    dec eax 
    mov bl, 2  
    div bl 
    xor ebx, ebx
    mov bl, al
    invoke dwtoa, ebx, addr tempBuff    
    invoke lstrcat, addr strATCommand, addr tempBuff
    invoke lstrcat, addr strATCommand, StrM(13)        
            
    Invoke MultiByteToWideChar, CP_ACP, 0, addr strATCommand, -1, addr tempWBuff, MAX_PATH     
    invoke WriteCommPort, this_, hCom, addr tempWBuff
         
    mov RecvFlag, 0		
@@:					
	invoke WaitForSingleObject, RecvEvent, 5000
	.if eax == WAIT_OBJECT_0
		invoke lstrcpy, addr tempBuff, addr ReadBuff				
		lea ebx, tempBuff  
		dec ebx  			
		invoke lstrlen, addr tempBuff
		mov edx, eax
		xor eax, eax    	
	BB1: 				
		cmp eax, edx
		je FF1
		inc eax        
		inc ebx
		cmp WORD ptr [ebx], ' >'
		jne BB1         
		
		invoke lstrcat, addr SMSBuff, StrM(26)
		Invoke MultiByteToWideChar, CP_ACP, 0, addr SMSBuff, -1, addr tempWBuff, MAX_PATH         
		invoke WriteCommPort, this_, hCom, addr tempWBuff	
		mov RecvFlag, 0		
@Back:	
		invoke WaitForSingleObject, RecvEvent, 5000				
	    .if eax == WAIT_OBJECT_0				    	
			invoke lstrcpy, addr tempBuff, addr ReadBuff
			lea ebx, tempBuff  
			dec ebx  			
			invoke lstrlen, addr tempBuff
			mov edx, eax
			xor eax, eax    	
		BB2: 						
			cmp eax, edx
			je FF2
			inc eax        
			inc ebx						
			cmp word ptr [ebx], 'KO'
			jne BB2
										
			mov eax, 1
			ret
			
	FF2:	.if RecvFlag != 512
				inc RecvFlag
				jmp @Back
			.else
				mov eax, 0
				ret
			.endif											 									
		.endif	
FF1:
		.if RecvFlag != 512
			inc RecvFlag
			jmp @B
		.else
			mov eax, 0
			ret
		.endif													
	.endif													
Exit:
    mov eax, 0
	ret
WriteSMS ENDP

SetReadCommCommand PROC uses esi edi ecx edx ebx this_:DWORD, hCom:DWORD, dwResponseType:DWORD, hResWnd:DWORD, dwResponse:DWORD,\
						lpBuff:DWORD, BuffSize:DWORD
	LOCAL hComEventThread:HANDLE
	
	invoke SetCommMask, hCom, EV_RXCHAR
	
	invoke memset, addr objSetReadComm, 0, sizeof StructSetReadComm
	mov eax, lpBuff
	mov objSetReadComm.lpBuff, eax
	mov eax, dwResponse
	mov objSetReadComm.dwResponse, eax
	mov eax, hResWnd
	mov objSetReadComm.hResWnd, eax
	mov eax, dwResponseType
	mov objSetReadComm.dwResponseType, eax
	mov eax, hCom
	mov objSetReadComm.hCom, eax	
	mov eax, BuffSize
	mov objSetReadComm.BuffSize, eax	
	mov  eax,OFFSET CommReadThreadProc 
    invoke CreateThread,NULL,NULL,eax,\ 
                             addr objSetReadComm,0,\ 
                             ADDR ThreadID 
	mov hComEventThread, eax
	invoke SetThreadPriority, hComEventThread, THREAD_PRIORITY_ABOVE_NORMAL                             
    invoke CloseHandle, hComEventThread 
    	
	mov eax, 1
	ret
SetReadCommCommand ENDP

CommReadThreadProc PROC lpBuffStruct:DWORD 
	LOCAL ComOverlapped:OVERLAPPED 
	LOCAL ComReadOverlapped:OVERLAPPED
	LOCAL WaitEventResult:DWORD
	LOCAL Errors:DWORD
	LOCAL CommStat:COMSTAT
	LOCAL dwWrite:dword
	LOCAL CommEvent:HANDLE 	
	LOCAL ReadEvent:HANDLE
	LOCAL loObjectSetReadComm:StructSetReadComm
 	
 	invoke memset, addr loObjectSetReadComm, 0, sizeof StructSetReadComm 	
 	invoke memcpy, lpBuffStruct, addr loObjectSetReadComm, sizeof StructSetReadComm 
			
	invoke CreateEvent, 0, 0, 0, 0
	mov CommEvent, eax	
	
	invoke CreateEvent, 0, 0, 0, 0
	mov ReadEvent, eax
	
	invoke memset, addr ComOverlapped, 0, SizeOf OVERLAPPED
	push CommEvent
	pop ComOverlapped.hEvent
	
	.while TRUE 
		invoke WaitCommEvent, loObjectSetReadComm.hCom, addr ComEventMask, addr ComOverlapped
		mov WaitEventResult, eax
		invoke GetLastError
		.if eax == ERROR_IO_PENDING
			invoke WaitForSingleObject, CommEvent, INFINITE
			.if eax == WAIT_OBJECT_0
				mov WaitEventResult, 1
			.else
				mov WaitEventResult, 0	
			.endif	
		.endif	
		.if WaitEventResult
			invoke ClearCommError, loObjectSetReadComm.hCom, addr Errors, addr CommStat
			.if CommStat.cbInQue > 0
				invoke memset, addr ComReadOverlapped, 0, SizeOf OVERLAPPED
				push ReadEvent
				pop ComReadOverlapped.hEvent
								
				invoke memset, loObjectSetReadComm.lpBuff, 0, loObjectSetReadComm.BuffSize				 
				invoke ReadFile, loObjectSetReadComm.hCom, loObjectSetReadComm.lpBuff,\
								 CommStat.cbInQue, addr dwWrite, addr ComReadOverlapped
				
				invoke WaitForSingleObject, ReadEvent, 1000
				.if eax != WAIT_OBJECT_0
					mov dwWrite, 0
				.else					
					invoke GetOverlappedResult, loObjectSetReadComm.hCom, addr ComReadOverlapped,\
												addr dwWrite, 0
					invoke ResetEvent, ReadEvent						
				.endif  
				
				.if loObjectSetReadComm.dwResponseType == rtEventModel
					invoke SetEvent, loObjectSetReadComm.dwResponse
					
				.elseif loObjectSetReadComm.dwResponseType == rtMessageModel
					invoke SendMessage, loObjectSetReadComm.hResWnd, loObjectSetReadComm.dwResponse,\
										addr loObjectSetReadComm.lpBuff, 0	
				.endif
														
			.endif	
			invoke ResetEvent, ReadEvent
		.endif
	.endw	
	ret
CommReadThreadProc ENDP

memset PROC pMem:DWORD, dwVal:byte, dwSize:DWORD
    mov edi, pMem
    mov al, dwVal
    mov ecx, dwSize
    cld
    rep stosb 
    ret

memset ENDP

memcpy PROC ptrSrc:DWORD, ptrDest:DWORD, dwSize:DWORD     
	 mov  ecx, dwSize 
     mov  esi, ptrSrc       
     mov  edi, ptrDest
     cld
     rep  movsb
     ret
memcpy ENDP

HexStr proc uses esi edi pstr:DWORD, pstrlen:DWORD

    mov eax, pstrlen
    mov ecx, 2
    mul ecx
    inc eax
    invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax
    mov edi, eax
    mov esi, pstr
    
    push edi
    
WriteHex:
    xor eax, eax
    lodsb
    invoke wsprintf, edi, StrM('%02X'), eax
    add edi, 2
    dec pstrlen
    jnz WriteHex
    pop eax
    ret
    
HexStr endp

Swap PROC lpBuff:DWORD
	
	invoke lstrlen, lpBuff
	mov ecx, eax
	mov edx, eax
	xor edx, edx
	mov esi, lpBuff 
@@:
	mov bl, byte ptr [esi]	
	inc esi 
	mov bh, byte ptr [esi]
	dec esi	
	mov byte ptr [esi], bh
	inc esi
	mov byte ptr [esi], bl
	add edx, 2
	.if edx < ecx 
		inc esi
		jmp @B
	.endif
	
	ret
Swap ENDP

str2pdu PROC lpSrcBuff:DWORD, lpDestBuff:DWORD 
	LOCAL pSrcBuff:DWORD	
	LOCAL pDestBuff:DWORD
	LOCAL bufflen:DWORD
	LOCAL srclen:DWORD
	LOCAL i:DWORD
	
	mov eax, lpSrcBuff	
	mov pSrcBuff, eax	
	mov eax, lpDestBuff
	mov pDestBuff, eax
	invoke lstrlen, pSrcBuff
	mov bufflen, eax	
	invoke memset, pDestBuff, 0, 256

@@:	
	invoke memset, addr src8buff, 0, 9
	invoke memset, addr dest7buff, 0, 8		
	.if bufflen < 8
		invoke memcpy, pSrcBuff, addr src8buff, bufflen
		mov eax, bufflen
		mov srclen, eax		
	.else
		invoke memcpy, pSrcBuff, addr src8buff, 8			
		mov srclen, 8
	.endif
	
	mov al, src8buff[0]
	mov dest7buff[0], al 	
	mov i, 1  	
	mov ecx, srclen
	.while i <= ecx							
		xor eax, eax
		mov ebx, i
		mov ah, src8buff[ebx]		
		mov ebx, i
		.while ebx > 0
			shr eax, 1
			dec ebx
		.endw	
		dec i		
		mov ebx, i
		or dest7buff[ebx], al  		
		inc i
		mov ebx, i
		mov dest7buff[ebx], ah
		inc i
		mov ecx, srclen
	.endw		
	add pSrcBuff, 8	
	mov eax, bufflen
	.if eax > 8	
		sub bufflen, 8		
		invoke lstrcat, pDestBuff, addr dest7buff				
		add pDestBuff, 7						
		jmp @B
	.else
		invoke lstrcat, pDestBuff, addr dest7buff
		jmp @exit
	.endif
@exit:	 
	ret
str2pdu ENDP


End DllMain
