# Explainer: Extending Storage Access API (SAA) to omit unpartitioned cookies

* [Discussion](https://github.com/privacycg/saa-non-cookie-storage/issues)

# Introduction

This extension to “[Explainer: Extending Storage Access API (SAA) to non-cookie storage](https://github.com/privacycg/saa-non-cookie-storage/blob/main/README.md)” proposes adding a mechanism to not force unpartitioned cookie access when all that the developer needs is some other unpartitioned storage access via SAA. This is one of two proposed extensions going out together.

# Motivation

The current [Storage Access API](https://github.com/privacycg/storage-access) requires that unpartitioned cookie access is granted if any unpartitioned storage access is needed. This forces unpartitioned cookies to be included in network requests which may not need them, having impacts on network performance and security. Before the [extension](https://privacycg.github.io/saa-non-cookie-storage/) ships, we have a chance to fix this behavior without a compatibility break.

# Goals

1. Provide a way for developers to ensure continuity of user experience with unpartitioned storage access without forcing unpartitioned cookie access.
2. Improve the privacy and security properties of the Storage Access API (largely lauded by the web community), while providing more flexibility for developers.

# Non-Goals

1. Address all breakage resulting from storage partitioning: 
   1. Use cases intended for pervasive tracking of users is not in scope
   1. Some anti-fraud use cases may need to be handled by a separate API, given the constraints of the SAA implementation
1. Push developers to migrate away from cookies to other storage mechanisms or vice-versa.

# Proposed Solution

We propose an extension of the [Storage Access API non-cookie extension](https://github.com/privacycg/saa-non-cookie-storage/blob/main/README.md) to provide a `cookies` argument which defines whether unpartitioned cookies will or won’t be included in future fetch requests. The API shape isn’t final, but for the sake of explanation and example it is treated as well defined below.

```javascript
// The following code would be run in a cross-site iframe for example.com.

// The following two lines would be functionally identical to support the existing no-argument version of `requestStorageAccess` which attaches unpartitioned cookies to future fetch requests.
await document.requestStorageAccess();
await document.requestStorageAccess({cookies: true});

// The following would attach unpartitioned cookies to future fetch requests.
let handle = await document.requestStorageAccess({all: true});

// The following would not attach unpartitioned cookies to future fetch requests.
let handle = await document.requestStorageAccess({sessionStorage: true});

// The following would attach unpartitioned cookies to future fetch requests.
let handle = await document.requestStorageAccess({sessionStorage: true, cookies: true});

// The following would not attach unpartitioned cookies to future fetch requests.
let handle = await document.requestStorageAccess({sessionStorage: true, cookies: false});

// The following (and any other request where all fields are false or missing) would be rejected due to nothing being requested.
await document.requestStorageAccess({});
await document.requestStorageAccess({all: false});
```

Note that once cookies are attached to future fetch requests this will remain true for the lifetime of the iframe. Calling `requestStorageAccess` again with different arguments would not change that.

Further, we propose defining a new async function `hasUnpartitionedCookieAccess` which returns true if unpartitioned cookies have been attached to future fetch requests and false otherwise. `hasStorageAccess` should be considered for future deprecation as it serves the same purpose but with a less clear name. The purpose of this is to ensure developers know this is a way to check if unpartitioned cookies had been attached, whereas the current naming implies it returns true if `requestStorageAccess` has ever been successfully called for any reason.

## Prompting the User

Browsers currently shipping the Storage Access API apply varying methods of when or how to ask the user for permission to grant 3p cookie access to a site. Given that this proposal involves extending the existing Storage Access API, while maintaining largely the same implications (from a privacy/security perspective) to the user, a consistent prompt for cookie and non-cookie access is preferred.

# Alternatives & Questions

## omitCookies param

We could instead offer an `omitCookies` param which defaults false but could be set to true to prevent future fetch requests from attaching unpartitioned cookies. If possible, passing a boolean to cause something not to happen should be avoided in favor of passing a boolean to cause something to happen. The one wrinkle here is the need to support the legacy case of calling `requestStorageAccess` with no arguments, but treating that as unique from the case where `requestStorageAccess` is called with an argument seems reasonable for legacy support.

# Privacy & Security Considerations

In extending an existing access-granting API, care must be taken not to open additional security issues or abuse vectors relative to comprehensive cross-site cookie blocking and storage partitioning. This extension offers only a way to limit privacy and security abuse, and no new vector for exploitation.
