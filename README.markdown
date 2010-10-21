= TouchHTTPD =

== Requirements ==

TouchHTTPD requires TouchFoundation and TouchXML (*).

(* TouchHTTPD uses TouchXML for presenting of errors. This functionality is optional and can be removed. The WebDAV handler also uses XML and (for obvious reasons this is not optional).

== How to build ==

You need to check out TouchFoundation and TouchXML into the same parent directory as TouchHTTPD:

	<parent directory>
		TouchFoundation
		TouchHTTPD
		TouchXML
