ETERNO BANNER MAKER
===================

What it does
  Makes the photos used in email.html: colour-graded in the "Western Ghats" look,
  with the Eterno logo, headlines and property names drawn INTO the photo,
  so the email looks the same in Gmail, Outlook and on phones.

What's in this folder
  make-banners.ps1   the tool
  sources\           original photos (put new photos here)
  fonts\             Cormorant Garamond + Montserrat (free fonts)

The finished photos are saved to the main  images\  folder.

How to run it
  1. Open PowerShell in the project folder
     (in File Explorer, open "Eterrno Marketing Starter", click the address bar,
      type  powershell  and press Enter).
  2. Paste this line and press Enter:
       powershell -ExecutionPolicy Bypass -File tools\banner-maker\make-banners.ps1
  3. It prints the list of photos it made. Done.

Changing a photo or text (e.g. after the Vagamon photoshoot)
  The easiest way: ask Claude, e.g.
    "Use the new photo in tools\banner-maker\sources\mont-new.jpg for the Vagamon banner"
  Or yourself: copy the new photo into  sources\ , then open make-banners.ps1 in Notepad,
  scroll to the  BANNERS  section near the bottom and change the file name or words
  in the matching line. Save, then run the tool (above).

After making new photos
  GitHub Desktop -> tick the changed files -> Commit to main -> Push origin.
  Wait a minute, then import email.html with HTMail as usual.

Note: this project is PUBLIC on GitHub. Never put rate sheets or private files here.
