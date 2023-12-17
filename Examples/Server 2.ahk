#Include Socket.ahk
/*
- uses G33KDUDE class @ [https://github.com/poa00/ahk.v1socket]
- listens on TCP socket 1337 for single newline-delimited line
- echoes message to console upon receipt from specified server
*/

; Ask Windows to allocate a console for us to use
; as our output to the user.
DllCall("AllocConsole")

; Set up a queue to contain our received messages,
; and a routine to monitor that queue and carry
; out any work that may be required.
RecvQueue := []
SetTimer, CheckQueue, 100

; Create a socket server to listen for incoming messages.
Server := new SocketTCP()
Server.OnAccept := Func("OnAccept")
Server.Bind(["0.0.0.0", 1337])
Server.Listen()

; Show a dialog to let the user know the server is running
MsgBox, Serving on port 1337`nClose this dialog to exit
ExitApp

; This routine will continually check the RecvQueue
; for newly received messages, and will carry out
; any long-lived or blocking operations that would
; be necessary.
CheckQueue()
{
	global RecvQueue
	
	; Loop through any received messages
	Loop, % RecvQueue.Length()
	{
		; Our newer messages will be at the front
		; of the queue, so remove an item from the
		; first index (AHK arrays are 1-indexed)
		Text := RecvQueue.RemoveAt(1)
		
		; Write the text, with an ending newline,
		; to the console output (Windows exposes
		; the console output as a special file)
		FileAppend, %Text%`n, CONOUT$
	}
}

; We want this routine to run for as little time as possible.
; AutoHotkey is not multithreaded, and while this rotuine
; is running it blocks any other clients from connecting to
; and communiting with the script.
OnAccept(Server)
{
	global RecvQueue
	
	; Accept the socket connection, read one newline-
	; delimited line, then close the socket immediatley.
	; Again, AHK is not multithreaded and can only
	; serve one client at a time, so the less time we
	; spend with the socket open the better.
	Sock := Server.Accept()
	Text := Sock.RecvLine()
	Sock.Disconnect()
	
	; Take the the text we received and put it into
	; the received text queue. Another routine will
	; handle that text and perform any blocking operations,
	; freeing up this routine to be run again for the
	; next client.
	RecvQueue.Push(Text)
}
