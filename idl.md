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
  boolean BroadcastChannel = false;
  boolean SharedWorker = false;
};

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
  BroadcastChannel BroadcastChannel(DOMString name);
  SharedWorker SharedWorker(USVString scriptURL, optional (DOMString or WorkerOptions) options = {});
};
