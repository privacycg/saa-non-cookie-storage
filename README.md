# Explainer: Extending Storage Access API (SAA) to non-cookie storage

[Discussion](https://github.com/arichiv/saa-non-cookie-storage/issues)

## Introduction

To prevent certain types of cross-site tracking, storage and communication APIs in third party contexts are being partitioned or deprecated (read more about [storage partitioning](https://developer.chrome.com/en/docs/privacy-sandbox/storage-partitioning/) and [cookie deprecation efforts](https://developer.chrome.com/docs/privacy-sandbox/third-party-cookie-phase-out/) in Chrome and [Firefox](https://developer.mozilla.org/en-US/docs/Web/Privacy/State_Partitioning)). This breaks use cases that depend on cookie and non-cookie storage and communication surfaces in cross-site contexts. Several solutions (like Chrome’s [Privacy Sandbox](https://developer.chrome.com/docs/privacy-sandbox/overview/)) have been proposed to address use cases that rely on third-party cookies, including the [Storage Access API](https://github.com/privacycg/storage-access) (shipping with multi-browser support), which facilitates limited access to third-party cookies in specific scenarios to mitigate user-facing breakage. This explainer proposes to extend that same mechanism to non-cookie storage/communication mediums.

## Motivation

There has been increasing [developer](https://github.com/GoogleChromeLabs/privacy-sandbox-dev-support/issues/124) and [implementer](https://github.com/privacycg/storage-access/issues/102) interest in first-party [DOM Storage](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API) and [Quota Managed Storage](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API) being available in third-party contexts the same way that [Cookies already can be](https://github.com/privacycg/storage-access). In the absence of such a solution, we would in effect be pushing developers to migrate to Cookies from other storage mechanisms. There are significant tradeoffs between Cookie and non-Cookie storage (size, flexibility, server exposure, network request size, etc.) that could cause a detriment in user experience from a privacy, security and performance perspective. To prevent sub-optimal use of cookies and to preserve context, this explainer proposes a solution for developers to regain 3p access to unpartitioned storage in select instances to avoid user-facing breakage in browsers shipping storage partitioning.

## Goals

1. Provide a way for developers to ensure continuity of user experience with unpartitioned third-party storage, without enabling pervasive tracking of users.
2. Maintain the privacy and security properties of the Storage Access API (largely lauded by the web community), while providing more flexibility for developers. 
3. Extend the Storage Access API, ideally with cross-browser interest.

## Non-Goals

1. Address all breakage resulting from storage partitioning: 
    1. Use cases intended for pervasive tracking of users is not in scope
    2. Some anti-fraud use cases may need to be handled by a separate API, given the constraints of the SAA implementation
2. Provide a passive mechanism to access first-party storage in third-party contexts.
3. Push developers to migrate to  Cookie from Non-Cookie storage mechanisms, and vice versa, especially when there are privacy/security/performance reasons to support one implementation over another in specific scenarios.

## Use Cases

### [Example 1](https://github.com/GoogleChromeLabs/privacy-sandbox-dev-support/issues/124)

A developer embeds chat.com on two of their sites site-a.com and site-b.com. chat.com uses IndexedDB to maintain a user session.

### [Example 2](https://groups.google.com/a/chromium.org/g/blink-dev/c/24hK6DKJnqY/m/fybXzBdwCAAJ)

This SaaS product has a heavy reliance on Broadcast Channel and this would break customer use cases. Broadcast Channel is used to coordinate Web RTC signaling and websocket management which is critical for the app. For example, the channel is used to support seamless multi-tab use cases and acts as a gatekeeper for managing audio and notifications if there are multiple instances of this app open (i.e., only a single tab can host an audio).

## Proposed Solution

We propose an extension of the [Storage Access API](https://webkit.org/blog/8124/introducing-storage-access-api/) (backwards compatible), and imagine the API mechanics to be roughly like this (JS running in an embedded iframe):

```javascript
// Request a new storage handle via rSA (this should prompt the user)
let handle = await document.requestStorageAccess({all: true});
// Write some cross-site localstorage
handle.localStorage.setItem("userid", "1234");
// Open or create an indexedDB that is shared with the 1P context
let messageDB = handle.defaultBucket.indexedDB.open("messages");
```

The same flow would be used by iframes to get a storage handle when their top-level ancestor successfully called [rSAFor](https://github.com/privacycg/requestStorageAccessFor), just that in this case the storage-access permission was already granted and thus the rSA call would not require a user gesture or show a prompt, allowing for “hidden” iframes accessing storage.

Possible API Shape: If the argument `{all: true}` is provided all available storage/communication mechanisms will be prepared and attached to the handle. Otherwise, a site could request just specific mechanisms like local storage and indexed db for example with `{localStorage: true, indexedDB: true}`. This flexibility is provided to ensure developers can avoid any performance impact from loading unused storage/communication mechanisms.

### Prompting the User

Browsers currently shipping the Storage Access API apply varying methods of when or how to ask the user for permission to grant 3p cookie access to a site. Given that this proposal involves extending the existing Storage Access API, while maintaining largely the same implications (from a privacy/security perspective) to the user, a consistent prompt for cookie and non-cookie access is preferred.

## Alternatives & Questions

### Storage Buckets

This is very similar to [Storage Buckets](https://github.com/WICG/storage-buckets/blob/main/explainer.md), and it was initially suggested that we could simply return a new bucket from an rSA call. However, in discussion with the Storage Buckets team it became clear that there are conflicting requirements (buckets are primarily for managing eviction). Further, buckets don’t cover DOM Storage or communication APIs, both of which we feel should be available to achieve our goals for this effort.

### Default StorageKey

We could change third-party context’s StorageKey to be the first-party one so that reads/writes went to that bucket in existing APIs, but this would cause issues for any in-flight reads/writes and significant retooling of infrastructure to make it possible.

### Service Workers

Service workers have [cache-based history sniffing attacks](https://www.ndss-symposium.org/wp-content/uploads/ndss2021_1C-2_23104_paper.pdf). Extending cross-site unpartitioned storage access to service workers would open up increased vulnerabilities and be somewhat confusing due to the way FetchEvent and other background events are not tied to an endpoint, thus first-party Service Workers will not be exposed in third-party contexts after an rSA call.

### Shared/Dedicated Workers

Shared and Dedicated Workers have access to SameSite=Strict cookies. This API does not otherwise grant access to those cookies in a third-party context, so it should not allow access to first-party worker pools.

## Privacy & Security Considerations

In extending an existing access-granting API, care must be taken not to open additional security issues or abuse vectors relative to comprehensive cross-site cookie blocking and storage partitioning. Except for Workers (which will not be supported in this extension) we believe non-cookie storage and communication APIs don't enable any capability that could not be built with cookie access.

Without this extension, we would in effect be pushing developers to migrate storage to cookies. This would have negative security implications as they are exposed in HTTP Requests and partitioned per-site instead of per-origin. Although the storage capacity is greater via non-cookie storage, not much information would need to be passed to simply achieve linking a first and third-party context.
