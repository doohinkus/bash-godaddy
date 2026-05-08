Output godaddy-demo.gif
Require bash
Require curl
Require jq

Set Shell "bash"
Set FontSize 15
Set Width 1000
Set Height 600
Set TypingSpeed 80ms

Sleep 1s
Type "./godaddy-cname.sh"
Sleep 300ms
Enter

Wait+Screen /Enter choice/
Sleep 1s

Type "3"
Sleep 200ms
Enter

Wait+Screen /Actions:/
Sleep 1s

Type "a"
Enter
Wait+Screen /Subdomain/
Type "test"
Enter
Wait+Screen /Target/
Type "github.io"
Enter
Wait+Screen /TTL/
Enter
Wait+Screen /Record added successfully/
Sleep 1s
Enter
Wait+Screen /Actions:/
Sleep 1s

Type "d"
Enter
Wait+Screen /Record number to delete/
Type "8"
Enter
Wait+Screen /Delete this record/
Type "y"
Enter
Wait+Screen /Record deleted successfully/
Sleep 1s
Enter
Wait+Screen /Actions:/
Sleep 1s

Wait+Screen /Choice:/
Type "q"
Sleep 1s
Enter
Sleep 2s
