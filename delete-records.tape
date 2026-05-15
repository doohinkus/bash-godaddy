Output delete-records.gif

Set Theme "Catppuccin Frappe"
Set FontSize 24
Set Width 1400
Set Height 800
Set TypingSpeed 50ms
Set Padding 20
Set CursorBlink false
Set Margin 30
Set MarginFill "#1e1e2e"
Set WindowBar Rings
Set BorderRadius 10

Require ./godaddy-cname.sh

# Note: run add-records.tape first to create demo records.

# Launch
Type "./godaddy-cname.sh"
Enter

Wait /Enter choice/
Type "4"
Enter

Wait+Screen /Actions:/

# Delete a CNAME record
Type "d"
Enter

Sleep 500ms
Type "1"
Enter

Sleep 500ms
Type "y"
Enter

Sleep 5s
Enter

# Toggle to TXT
Wait+Screen /Actions:/
Type "t"
Enter

Sleep 3s
Wait+Screen /Actions:/

# Delete a TXT record
Type "d"
Enter

Sleep 500ms
Type "1"
Enter

Sleep 500ms
Type "y"
Enter

Sleep 5s
Enter

# Quit
Wait+Screen /Actions:/
Type "q"
Enter
