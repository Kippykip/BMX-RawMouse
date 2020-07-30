'Raw Mouse Input for BMX-NG V1.1
'~Kippykip

'Include a bunch of Win32 functions
Extern "Win32"
	Function RegisterRawInputDevices:Int(pRawInputDevices:Byte Ptr, uiNumDevices:Int, cbSize:Int)="WINBOOL __stdcall RegisterRawInputDevices(PCRAWINPUTDEVICE, UINT, UINT)!"
	Function GetRawInputData:Int(hRawInput:Byte Ptr, uiCommand:Int, pData:Byte Ptr, pcbSize:Int Ptr, cbSizeHeader:Int)="UINT __stdcall GetRawInputData(HRAWINPUT, UINT, LPVOID, PUINT, UINT)!"
	Function GetRawInputDeviceList:Int(pRawInputDeviceList:Byte Ptr, puiNumDevices:Int Ptr, cbSize:Int) = "UINT __stdcall GetRawInputDeviceList(PRAWINPUTDEVICELIST, PUINT, UINT)!"
	Function GetRawInputDeviceInfoA:Int(hDevice:Int, uiCommand:Int, pData:Byte Ptr, pcbSize:Int Ptr) = "UINT __stdcall GetRawInputDeviceInfoA(HANDLE, UINT, LPVOID, PUINT)!"
End Extern

'Honestly I'm still unsure how the majority of this stuff works.
'I've just put a bunch of scraps together and got it to work within BMX-NG

'Multiple Keyboards Handling
'https://www.syntaxbomb.com/index.php/topic,1026.0.html

'Some code you may find useful.
'https://mojolabs.nz/posts.php?topic=85660

'WINPROC FIX!
'Thank you Scaremonger, VERY EPIC!
'https://www.syntaxbomb.com/index.php/topic,6038.msg347044457.html#msg347044457

Type HID_Devices
	Global Rid:HID_RAWINPUTDEVICE
	Global OldWinProc:Byte Ptr
	Const HID_USAGE_PAGE_GENERIC:Int = $1
	Const HID_USAGE_GENERIC_MOUSE:Int = $2
	Const RIDEV_INPUTSINK:Int = $100
	Const RIM_TYPEMOUSE:Int = 0
	Const RID_INPUT:Int = $10000003
	Const WM_INPUT:Int = $00FF
	
	Function SetWindowFunc:Byte Ptr(hwnd:Byte Ptr, NewProc:Byte Ptr(hWnd:Byte Ptr, Msg:UInt, WParamx:WParam, LParamx:LParam))
		Local OldProc:Int = GetWindowLongA(hwnd, GWL_WNDPROC) 'Backup the original WinProc
		SetWindowLongA(hwnd, GWL_WNDPROC, Int(Byte Ptr NewProc)) 'Change the proc
		Return OldProc 'Return the old proc
	EndFunction
	
	'Initialise the raw input procedure 
	Function Init()
		Rid = New HID_RAWINPUTDEVICE
		Local hWnd:Byte Ptr = GetActiveWindow()
		HID_RAWMouse.Register(hWnd)
		OldWinProc = SetWindowFunc(hWnd, HID_WinProc)
	End Function
End Type

Type HID_RAWINPUTDEVICE
   Field usUsagePage:Short
   Field usUsage:Short
   Field dwFlags:Int
   Field hwndTarget:Byte Ptr
End Type

Type HID_RAWMouse
	Global RawX:Float, RawY:Float
	Field dwType:Int
	Field dwSize:Int
	Field hDevice:Int
	Field WParam:Int Ptr
	
	Field usFlags:Short
	Field ulButtons:Int
	Field ulRawButtons:Int
	Field lLastX:Int
	Field lLastY:Int
	Field ulExtraInformation:Int

	'Register the HID device
	Function Register(hWnd:Byte Ptr)
		HID_Devices.Rid.usUsagePage = HID_Devices.HID_USAGE_PAGE_GENERIC
		HID_Devices.Rid.usUsage = HID_Devices.HID_USAGE_GENERIC_MOUSE
		HID_Devices.Rid.dwFlags = HID_Devices.RIDEV_INPUTSINK
		HID_Devices.Rid.hwndTarget = hWnd
		RegisterRawInputDevices(HID_Devices.Rid, 1, SizeOf(HID_Devices.Rid))
	End Function
End Type

'Kind of... perhaps inject a new WinProc
Function HID_WinProc:Byte Ptr(hWnd:Byte Ptr, Msg:UInt, WParamx:WParam, LParamx:LParam) "win32"
	Select MSG
	    Case HID_Devices.WM_INPUT
			Local dwSize:Int = 40
			Local Raw:HID_RAWMouse = New HID_RAWMouse
			GetRawInputData(Byte Ptr(LParamx), HID_Devices.RID_INPUT, Raw, Varptr dwSize, 16) ' Get data in RAWINPUT structure.
			If Raw.dwType = HID_Devices.RIM_TYPEMOUSE
				HID_RAWMouse.RawX:+Raw.lLastX
				HID_RAWMouse.RawY:+Raw.lLastY
			EndIf
	End Select
	
	'Go back to the Original WinProc
	Return CallWindowProcA(HID_Devices.OldWinProc, hWnd, Msg, WParamx, LParamx)
End Function


Rem - Example below!

Graphics(640, 480)
HID_Devices.Init()
While Not KeyHit(key_escape)
	Cls
		DrawText("X:" + HID_RAWMouse.RawX + ", Y:" + HID_RAWMouse.RawY, 0, 0)
		HID_RAWMouse.RawX = 0
		HID_RAWMouse.RawY = 0
	Flip	
Wend
End

endrem