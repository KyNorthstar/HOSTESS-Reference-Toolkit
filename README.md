# [**H**OSTESS](https://GitHub.com/Project-HOSTESS) **R**eference **T**oolkit

```swift
var task = try await Hostess.task(withId: "BnxaCy06QDuj29A4KV1PGg")
task.body = "Clean the _whole_ kitchen"
try await Hostess.save(task)
```




# On the usage of `try!`

In several places in this codebase, you'll see `try!`. Worry not; these are only where calling a computed value which ends up throwing `Never`. That is to say, no error is actually thrown; in fact, if you try compiling this library, you'll see this warning everywhere:

```
No calls to throwing functions occur within 'try' expression
```

This is because of a bug in the Swift compiler which would cause the compiler to crash if there's no `try!` there.
You can see progress on that bug here: https://github.com/swiftlang/swift/issues/87036
