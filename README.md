# android-geta

A simple log recorder, written in lua

# Download

[Click here to get the latest release](https://github.com/PerformanC/android-geta/releases/latest)

# Commands

## How to use
```
./geta [COMMAND] [OPTIONS]
```

## List

| Name (Usage)                     | Explaination                                               |
|----------------------------------|------------------------------------------------------------|
| dmesg                            | get dmesg log (live)                                       |
| logcat                           | get logcat log (live)                                      |
| ramoops                          | get ramoops log (last dmesg log before crash)              |
| clear [dmesg / ramoops / logcat] | clear specific log folder (folder name like mode)          |
| clearall                         | clear every folder that exist                              |
| help                             | print all command that avaliable (you can include nothing) |