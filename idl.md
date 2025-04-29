```
partial interface Document {
  Promise<StorageAccessHandle> requestStorageAccess(StorageAccessTypes types);
  Promise<boolean> hasUnpartitionedCookieAccess();
};

dictionary StorageAccessTypes {
  boolean all = false;
  boolean cookies = false;
  boolean sessionStorage = false;
  boolean localStorage = false;
  boolean indexedDB = false;
  boolean locks = false;
  boolean caches = false;
  boolean getDirectory = false;
  boolean estimate = false;
  boolean createObjectURL = false;
  boolean revokeObjectURL = false;
  boolean createBroadcastChannel = false;
  boolean createSharedWorker = false;
};

enum SameSiteCookiesType { "all", "none" };

dictionary SharedWorkerOptions : WorkerOptions {
  SameSiteCookiesType sameSiteCookies;
}

interface StorageAccessHandle {
  readonly attribute Storage sessionStorage;
  readonly attribute Storage localStorage;
  readonly attribute IDBFactory indexedDB;
  readonly attribute LockManager locks;
  readonly attribute CacheStorage caches;
  Promise<FileSystemDirectoryHandle> getDirectory();
  Promise<StorageEstimate> estimate();
  DOMString createObjectURL((Blob or MediaSource) obj);
  undefined revokeObjectURL(DOMString url);
  BroadcastChannel createBroadcastChannel(DOMString name);
  SharedWorker createSharedWorker(USVString scriptURL, optional (DOMString or SharedWorkerOptions) options = {});
};

interface SharedWorker : EventTarget {
    constructor(ScriptURLString scriptURL, optional (DOMString or SharedWorkerOptions) options = {});
};
```
