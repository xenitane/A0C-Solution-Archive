# aoc.zig

## Requirements

- A decent text editor
- [Zig compiler](https://ziglang.org) (13.0.0 or higher)

## Directory Structure

```plaintext
Root
|- .
|- ..
|- inputs
|- |- test
|  |  |- test.txt
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
|- readme.md
|- template.zig
```

> Points to Remember:
> The inputs must be provided by the user via the approprite file.
> The year in the directory structure are from 2015 and forward along with a test file in the inputs directory for testing purposes.
> There is a template file for the solutions which takes care of the file input in the root of the directory.

## Instructions to Run

- To run the solution of a certain year's certain day, use the following command and replace the year and day accordingly and make sure that the solution exists and the input file is also present.

    ```bash
    zig build aoc -Dyear=**<year>** -Dday=**<day>**
    ```

- To run a test input against the same solution, make sure that you have the test input in the `inputs/test/test.txt` file and execute the following command.
    ```bash
    zig build aoc-test -Dyear=**<year>** -Dday=**<day>**
    ```
