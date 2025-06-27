# Special handling

The following usages require special handling and are only intended for specific cases.

## Purge memory

There is also the possibility to only remove the data that is in memory of Parley. The difference with the `reset()` method is that this one does not update the backend. In fact, this can be seen as the app going 'inactive' and clearing its memory, while the user keeps being logged in. However, Parley will not be able to recover from this automatically and therefore it is required to call the `configure()` method again to use Parley.

```swift
Parley.purgeLocalMemory()
```

## Lightweight configure

This is a special use case which comes with some trade-offs.

### Setup

To set up Parley without configuring it all, the `setup()` method can be called:

```swift
Parley.setup(secret: <#secret#>, uniqueDeviceIdentifier: <#indentifier?#>, networkSession: <#session?#>, networkConfig: <#config?#>)
```

### Register device

To be able to use Parley methods, the device must be registered for the current user:

```swift
do throws(ConfigurationError) {
    Parley.registerDevice()
} catch {
    <#Handle error#>
}
```
