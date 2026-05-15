Output add-records.gif

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

# Launch
Type "./godaddy-cname.sh"
Enter

# Wait for domain menu (API call)
Wait /Enter choice/

# Pick bluespicemachine.org
Type "4"
Enter

# Wait for record screen (API call to fetch records)
Wait+Screen /Actions:/

# Add CNAME record
Type "a"
Enter

Sleep 500ms
Type "demo-cname"
Enter

Sleep 500ms
Type "demo.example.com"
Enter

Sleep 500ms
Type "3600"
Enter

# Wait for API response (slow path)
Sleep 5s

# Dismiss pause
Enter

# Toggle to TXT
Wait+Screen /Actions:/
Type "t"
Enter

# Wait for TXT record fetch
Sleep 3s
Wait+Screen /Actions:/

# Add TXT record
Type "a"
Enter

Sleep 500ms
Type "demo-txt"
Enter

Sleep 500ms
Type "sample-txt-value"
Enter

Sleep 500ms
Type "3600"
Enter

Sleep 5s
Enter

# Quit
Wait+Screen /Actions:/
Type "q"
Enter
