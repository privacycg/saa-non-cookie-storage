# Explainer: Extending Storage Access API (SAA) to non-cookie storage

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

A developer embeds chat.com on two of their sites site-a.com and site-b.com. chat.com uses Shared Workers to maintain a user session.

### [Example 2](https://groups.google.com/a/chromium.org/g/blink-dev/c/24hK6DKJnqY/m/fybXzBdwCAAJ)

This SaaS product has a heavy reliance on shared workers and this would break customer use cases.  Shared workers are used to coordinate Web RTC signaling and websocket management which is critical for the app. For example, the shared worker is used to support seamless multi-tab use cases and acts as a gatekeeper for managing audio and notifications if there are multiple instances of this app open (i.e., only a single tab can host an audio).
