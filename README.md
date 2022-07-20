# WhatsApp Cleaner Proof-Of-Concept

**:warning: REQUIRES ROOT**

Clean your WhatsApp media folder from files that no longer are in chats.

**This is just a PoC.**

*THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*

### How it works

1. Creates a copy of the WhatsApp DB (to avoid corruption)
2. Reads the DB and extracts the media files paths
3. Get paths of all files in the WhatsApp Media folder
4. Compare the two lists and select the files that are not in the DB