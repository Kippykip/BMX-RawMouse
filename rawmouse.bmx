'Include a bunch of Win32 functions
Extern "Win32"
	Function RegisterRawInputDevices:Int(pRawInputDevices:Byte Ptr, uiNumDevices:Int, cbSize:Int)="WINBOOL __stdcall RegisterRawInputDevices(PCRAWINPUTDEVICE, UINT, UINT)!"
	Function GetRawInputData:Int(hRawInput:Byte Ptr, uiCommand:Int, pData:Byte Ptr, pcbSize:Int Ptr, cbSizeHeader:Int)="UINT __stdcall GetRawInputData(HRAWINPUT, UINT, LPVOID, PUINT, UINT)!"
	Function GetRawInputDeviceList:Int(pRawInputDeviceList:Byte Ptr, puiNumDevices:Int Ptr, cbSize:Int) = "UINT __stdcall GetRawInputDeviceList(PRAWINPUTDEVICELIST, PUINT, UINT)!"
	Function GetRawInputDeviceInfoA:Int( hDevice:Int, uiCommand:Int, pData:Byte Ptr, pcbSize:Int Ptr)="UINT __stdcall GetRawInputDeviceInfoA(HANDLE, UINT, LPVOID, PUINT)!"
End Extern

'Honestly I'm still unsure how the majority of this stuff works.
'I've just put a bunch of scraps together and got it to work within BMX-NG
'~Kippykip

'Multiple Keyboards Handling
'https://www.syntaxbomb.com/index.php/topic,1026.0.html

'Some code you may find useful.
'https://mojolabs.nz/posts.php?topic=85660

Type HID_Devices
	Global Rid:HID_RAWINPUTDEVICE
	Global OldWinProc:Int
	Const HID_USAGE_PAGE_GENERIC:Int = $1
	Const HID_USAGE_GENERIC_MOUSE:Int = $2
	Const RIDEV_INPUTSINK:Int = $100
	Const RIM_TYPEMOUSE:Int = 0
	Const RID_INPUT:Int = $10000003
	Const HID_USAGE_GENERIC_KEYBOARD:Int = $6
	Const RIM_TYPEKEYBOARD:Int = 1
	Const RIM_TYPEHID:Int = 2
	Const RIDI_DEVICENAME:Int = $20000007
	Const WM_KEYDOWN:Int = $0100
	Const WM_SYSKEYDOWN:Int = $0104
	Const WM_INPUT:Int = $00FF
	
	Function Init()
		Rid = New HID_RAWINPUTDEVICE
		Local hWnd:Byte Ptr = GetActiveWindow()
		'Hook all devices we need.... or just the mouse in this example.
		HID_RAWMouse.Register(hWnd)
		HID_Devices.OldWinProc = SetWindowLongA(hWnd, -4, Int(Byte Ptr(WinProc))) 'HookWinProc
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

Function WinProc:Int(hWnd:Byte Ptr, Msg:UInt, WParamx:WParam, LParamx:Int) "win32"
	Select Msg
	    Case HID_Devices.WM_INPUT
			Local dwSize:Int = 40
			Local Raw:HID_RAWMouse = New HID_RAWMouse
			GetRawInputData(Byte Ptr(LParamx), HID_Devices.RID_INPUT, Raw, Varptr dwSize, 16) ' Get data in RAWINPUT structure.
			If Raw.dwType = HID_Devices.RIM_TYPEMOUSE
				HID_RAWMouse.RawX:+Raw.lLastX
				HID_RAWMouse.RawY:+Raw.lLastY
			EndIf				
	End Select
	CallWindowProcA(Byte Ptr(HID_Devices.OldWinProc), hWnd, Msg, WParamx, LParamx)
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