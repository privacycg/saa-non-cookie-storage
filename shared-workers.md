# Explainer: Extending Storage Access API (SAA) to Shared Workers

* [Discussion](https://github.com/privacycg/saa-non-cookie-storage/issues)

# Introduction

This extension to “[Explainer: Extending Storage Access API (SAA) to non-cookie storage](https://github.com/privacycg/saa-non-cookie-storage/blob/main/README.md)” proposes adding Shared Workers to the SAA handle. This is one of two proposed extensions going out together.

# Motivation

There has been increasing [developer](https://github.com/GoogleChromeLabs/privacy-sandbox-dev-support/issues/124) and [implementer](https://github.com/privacycg/storage-access/issues/157) interest in first-party workers being available in third-party contexts the same way that [third-party cookies already can be](https://github.com/privacycg/storage-access). In the absence of such a solution, we leave developers without a robust way to manage cross-tab state for frames loading the same origin. This explainer proposes a solution for developers to regain third-party access to Shared Workers in select instances to avoid user-facing breakage in browsers shipping storage partitioning.

# Goals

1. Provide a way for developers to ensure continuity of user experience with unpartitioned third-party Shared Workers, without enabling pervasive tracking of users.
1. Maintain the privacy and security properties of the Storage Access API , while providing more flexibility for developers. 
1. Avoid pushing developers to migrate to different worker and storage mechanisms, especially when there are privacy/security/performance reasons to support one implementation over another in specific scenarios.

# Non-Goals

1. Address all breakage resulting from storage partitioning: 
   1. Use cases intended for pervasive tracking of users is not in scope
   1. Some anti-fraud use cases may need to be handled by a separate API, given the constraints of the SAA implementation
1. Provide a passive mechanism to access first-party workers in third-party contexts.

# Use Cases

## [Maintaining a Session](https://github.com/GoogleChromeLabs/privacy-sandbox-dev-support/issues/124)

A website, chat.example, offers a way to maintain active chat session between any sites the embed it using SharedWorkers.
Before storage partitioning this was possible, but after storage partitioning the when chat.example is embedded on different sites and instanciates a SharedWorker it would no longer be shared.
By prompting the user for permission via `document.requestStorageAccess({SharedWorker: true})` and then instanciating the SharedWorker via the returned handle the worker can be shared across partitioned third-party contexts.

## [Transfering an ArrayBuffer](https://groups.google.com/a/chromium.org/g/blink-dev/c/inRN8tI49O0/m/Q_TE0cw4AAAJ)

A website, worker.example, wants to track and resume work in a first party context using SharedWorkers. `window.postMessage(...)` won't work as it would require inefficient cloning of significant data.
Before storage partitioning this was possible, but after storage partitioning the when worker.example is embedded in a third-party context and instanciates a SharedWorker it would no longer be shared with workers instanciated in a first-party context.
By prompting the user for permission via `document.requestStorageAccess({SharedWorker: true})` and then instanciating the SharedWorker via the returned handle the worker can be shared from a partitioned third-party context to a first-party context if the first-party worker is instanciated with the `sameSiteCookies: 'none'` option.
The worker shared this way won't gain access to `SameSite=Strict` cookies, which is important as `document.requestStorageAccess(...)` doesn't grant this either.

# Proposed Solution

We propose adding a new [option to the SharedWorker constructor](https://html.spec.whatwg.org/dev/workers.html#shared-workers-and-the-sharedworker-interface) that controls whether cookies with SameSite=Lax/Strict are included so that these sensitive cookies aren’t included in contexts where they aren’t required. This option could be called  `sameSiteCookies`, which could accept one of two values: ‘all’ or ‘none’ (the name isn’t finalized, but for the sake of the examples and explanation we will use these for now). The default value, when the option isn’t set, would be the same as setting ‘all’ in a top-level frame and the same as setting ‘none’ in any other frame. The only real customization this permits is the ability to set ‘none’ where the default would be ‘all’; setting ‘all’ where the default is ‘none’ is not permitted as such a context would lack access to SameSite Strict/Lax cookies.

```javascript
// The following code would be run in a top-level frame for example.com.

// This would start a first-party Shared Worker with the same behavior as before.
const sharedWorker1 = new SharedWorker("shared_worker.js");

// This would reference the same worker as `sharedWorker1`.
const sharedWorker2 = new SharedWorker("shared_worker.js", {sameSiteCookies: 'all'});

// This is a new Shared Worker that lacks lax/strict cookie access.
const sharedWorker3 = new SharedWorker("shared_worker.js", {sameSiteCookies: 'none'});
```

We further propose an extension of the [Storage Access API non-cookie extension](https://github.com/privacycg/saa-non-cookie-storage/blob/main/README.md) to provide a way to create Shared Workers that have access to first-party storage.

```javascript
// The following code would be run in a cross-site iframe for example.com.

// This would start a third-party Shared Worker with the same behavior as before.
const sharedWorker4 = new SharedWorker("shared_worker.js");

// This would reference the same worker as `sharedWorker4`.
const sharedWorker5 = new SharedWorker("shared_worker.js", {sameSiteCookies: 'none'});

// This would throw a DOM security exception.
new SharedWorker("shared_worker.js", {sameSiteCookies: 'all'});

// Request a new storage handle via rSA (this should prompt the user)
let handle = await document.requestStorageAccess({all: true});

// This worker has first-party storage acccess but lacks strict and lax cookies. It would reference the same worker as `sharedWorker3`.
const sharedWorker6 = handle.SharedWorker("shared_worker.js");

// This would reference the same worker as `sharedWorker3`.
const sharedWorker7 = handle.SharedWorker("shared_worker.js", {sameSiteCookies: 'none'});

// This would throw a DOM security exception.
handle.SharedWorker("shared_worker.js", {sameSiteCookies: 'all'});
```

If the argument `{all: true}` is provided all available storage/communication mechanisms will be prepared and attached to the handle. Otherwise, a site could request just specific mechanisms like shared workers with `{SharedWorker: true}`. This flexibility is provided to ensure developers can avoid any performance impact from loading unused storage/communication mechanisms.

## Prompting the User

Browsers currently shipping the Storage Access API apply varying methods of when or how to ask the user for permission to grant third-party cookie access to a site. Given that this proposal involves extending the existing Storage Access API, while maintaining largely the same implications (from a privacy/security perspective) to the user, re-using a consistent prompt for worker and non-worker access that any call to requestStorageAccess can trigger is preferred.

# Alternatives & Questions

## Service Workers

Service workers have [cache-based history sniffing attacks](https://www.ndss-symposium.org/wp-content/uploads/ndss2021_1C-2_23104_paper.pdf). Extending cross-site unpartitioned storage access to service workers would open up increased vulnerabilities and be somewhat confusing due to the way FetchEvent and other background events are not tied to an endpoint, thus first-party Service Workers will not be exposed in third-party contexts after an rSA call.

## Dedicated Worker support

We could support the same `hasSameSiteCookiesAccess` option for dedicated workers and make them constructable off of the SAA handle, but without a specific developer request this can be tabled for the time being.

## Worker-access to requestStorageAccess

We could expose `requestStorageAccess` within Dedicated or Shared Workers, and depend on the contexts that create or have access to the worker for knowing if the request should be granted. This on its own would not satisfy the use cases we must consider, as it would not provide a way to access the same shared worker in a first-party and third-party context. We may want to add such a feature in the future in an independent extension of SAA depending on developer demand.

# Privacy & Security Considerations

In extending an existing access-granting API, care must be taken not to open additional security issues or abuse vectors relative to comprehensive cross-site cookie blocking and storage partitioning. Except for Service Workers (which will not be supported in this extension) we believe shared worker access can be provided as long as `SameSite=Strict` and `SameSite=Lax` cookies are not read or written in these contexts. This limitation should provide the same privacy and security guarantees already secured in the existing SAA access to cookies. The existing requestStorageAccess function provides access to unpartitioned cookies except those marked Strict or Lax, and this new extension will mirror that limitation in the new Shared Worker pool.
