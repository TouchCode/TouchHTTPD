* Check all method types and make sure fully integrated
* Create smart NSData that works as NSData or stream or tempfile. (Writes to NSMutableData… if data exceeds threshold writes it to a tmp file instead.)
* Exposes NSErrors in HTTP error codes might be a security risk!
* Find & clear up all TODOs
* Fix the multiple xmlns="DAV:" stuff in PROPFIND responses.
* Handling clients with "Accept:" headers that don't match up
* HTTP Digest Auth
* Improve file system security
* Make sure all unit tests & samples still work
* Make sure chunking works if data is broken during chunk sizes
* Optimise XML
* SSL on iPhone
* Subclass CHTTPMessage into request & response classes
* Support "If*None*Match" header in GETs
* Unit Test WebDAV
* Would like to log 207 Multistatus responses
