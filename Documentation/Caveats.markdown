# TouchWebDAV Caveats

* BASIC Auth Only (Digest auth coming soon)
* No SSL
* Not optimised for caching headers (If-*)
* Cannot use Finder WebDAV and TouchWebDAV server on same machine!
* WebDAV locking is totally fake.
* Set attribute operations unsupported (so chmod, touch will not work)
