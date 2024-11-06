# AoC Solution Archive in Zig

## Requirements

- A decent text editor
- [Zig compiler](https://ziglang.org) (13.0.0 or higher)

## Directory Structure

```plaintext
Root
|- .
|- ..
|- inputs
|  |- year
|  |  |- 01.txt
|  |  |- ...
|  |  |- 25.txt
|  |- ...
|- solutions
|  |- year
|  |  |- 01.zig
|  |  |- ...
|  |  |- 25.zig
|  |- ...
|- build.zig
|- build.zig.zon
```

> Points to Remember:
> The inputs must be provided by the user in the required format.
> The year in the directory structure are the years 2015 to now.

## Instructions to Run

To run the solution of a certain year's certain day, use the following command and replace the year and day accordingly and make sure that the solution exists and the input file is also present.

```bash
zig build -Dyear=<year> -Dday=<day>
```
