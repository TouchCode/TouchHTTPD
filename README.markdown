# TouchHTTPD

## Requirements

TouchHTTPD requires TouchFoundation and TouchXML (*).

(* TouchHTTPD uses TouchXML for presenting of errors. This functionality is optional and can be removed. The WebDAV handler also uses XML and (for obvious reasons this is not optional).

## How to build

You need to check out TouchFoundation and TouchXML into the same parent directory as TouchHTTPD:

	<parent directory>
		TouchFoundation
		TouchHTTPD
		TouchXML

## TODO

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

## TouchWebDAV Caveats

* BASIC Auth Only (Digest auth coming soon)
* No SSL
* Not optimised for caching headers (If-*)
* Cannot use Finder WebDAV and TouchWebDAV server on same machine!
* WebDAV locking is totally fake.
* Set attribute operations unsupported (so chmod, touch will not work)


## Testing

### Compatibility Notes

#### Operations

* Connect to server (e.g. mount server)
* List server contents
* Create directory
* Rename directory
* Duplicate directory
* Delete directory
* Create file
* Rename file
* Edit file contents
* Duplicate file
* Delete file
* TODO...

### Clients

#### Windows XP SP2

* Seems to work for pretty much all operations.
* Some rather large performance problems. Supporting the if-* headers should help

#### Interarchy

* Works for all operations

#### cadaver

* Works for all operations

#### Mounted on Mac OS X 10.5, accessed via Terminal

* Works for all operations
* Unsupported operations are well, unsupported (e.g. chmod)

#### Mounted on Mac OS X 10.5, acccesss via Finder

* Only partially working. File writing is really rough right now.
