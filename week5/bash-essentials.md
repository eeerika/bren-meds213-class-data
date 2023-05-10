# Ten Bash Essentials

Greg Janée \<gjanee@ucsb.edu>\
May 2023

Some essential concepts to get you started writing your first Bash
script.

## 1. What does Bash (or any shell for that matter) do?

Bash is program on your machine that allows you to interactively run
other programs.  It:

- Writes a prompt, reads a line from the terminal window
- Performs various "expansions" to arrive at a final command or
  command pipeline
- Locates where the program(s) requested to be run are
- Runs the requested program(s) and links their input/output/error
  streams to and from files and into pipelines
- Writes any output to the terminal window
- Repeat

These steps are described in more detail below.

## 2. Fundamentals review

Files in Unix and Unix-like systems are organized into hierarchical
directories identified by "pathnames" as in `/Users/moe/somefile.txt`.
Here the leading `/` represents the root directory on the machine,
`Users` is a directory within that, `moe` a directory within that
directory, and so forth until we get to a final directory or file.

At any given time you are "in" a directory.  Handy commands:

- `pwd`: where am I?
- `cd new_directory`: change directories
- `ls`: what files and subdirectories are in here?
- `ls -F`: same, but nicer formatting

An "absolute" pathname begins with `/` and identifies a directory or
file starting from the root directory as in the example above.  A
"relative" pathname does not begin with `/` and does the same, but
relative to the current directory.

Some pseudo directory names.  Wherever you are:

- `.`: current directory
- `..`: parent directory of current directory
- `~`: home directory

So:

- `/Users/shemp`: absolute pathname of Shemp's home directory
- `../shemp`: same, relative to `/Users/moe`
- `~`: your home directory
- `~shemp`: Shemp's home directory

By convention Unix commands accept "options" followed by "arguments".
Options begin with a single (`-`) or double (`--`) hyphen.  Multiple
options that begin with a single hyphen can be combined for brevity.

- `ls foo`: list files in directory `foo`
- `ls -A foo`: same, option `-A` to include hidden files
- `ls -A -l foo`: add long listing option
- `ls -Al foo`: equivalent to above
- `python --version`: print Python version number

But be aware that these are only conventions, and there are
idiosyncracies in how commands are run.

## 3. Variables

Bash supports variables, and variables are essential in writing Bash
scripts.  To set a variable:

```
name=Moe
```

No space between the variable name and equals sign!  Variables are
referenced as `${name}`, or as just `$name` if not ambiguous.  Lots of
other stuff can go inside the braces, such as string processing and
array indexing.  Refer to the Bash manual or a good cheat sheet for
examples.

Names defined as above are local to the current Bash session or
script.  "Environment variables" are variables that are inherited by
(visible to) programs and any scripts you run.  To set, add `export`:

```
export DEBUG_ENABLED=1
```

The two most important environment variables are `HOME` (your home
directory) and `PATH` (discussed below).  The use of all-caps
environment variable names is just a convention.

## 4. Expansions

Before running any commands Bash performs various kinds of expansions.
The rules about what expansions it performs and when and in what order
are confusing.  If you feel lost, join the club.

1. Variable substitution.

   ```name=Moe```\
   ```echo "Hello $name"```

   is expanded to

   ```echo "Hello Moe"```

   The meaning of the above is that `$name` is literally replaced with
   `Moe` before the `echo` command is run.

2. Command alias substitution.  Aliases are handy abbreviations
   usually defined in the `~/.bashrc` Bash configuration file.

   ```alias ll="ls -l"```\
   ```ll foo```

   is expanded to

   ```ls -l foo```

3. Wildcard expansion ("globbing").

   ```wc -l *.csv```

   is expanded to

   ```wc -l ASDN_Bird_eggs.csv species.csv ...```

   As with variable substitutions, the globbing expansion literally
   replaces the wildcard expression with a list of filenames before
   the `wc` command is run.

4. Running subcommands.

   ```now="$(date)"```

   is expanded to

   ```now="Sat May  6 19:02:07 PDT 2023"```

   The expression placed in the `$(...)` can be an entire command
   pipeline.  When done, the subcommand is replaced with any output
   produced.

5. Arithmetic.

   ```answer=$(( 21 * 2 ))```

   is expanded to

   ```answer=42```

   Bash can do integer arithmetic only.

Takeaway: program(s) that are run see only the finally expanded
command line.

## 5. Quoting

Quoting is another difficult area of Bash.  It's hard to get right.

- Double quotes support variable, subcommand, and arithmetic
  expansions.  We've already seen these examples:

  ```echo "Hello $name"```\
  ```echo "Today is $(date)"```

  get expanded to

  ```echo "Hello Moe"```\
  ```echo "Today is Sat May  6 19:02:07 PDT 2023"```

- Single quotes don't.

   ```echo 'Hello $name'```

   just remains

   ```echo 'Hello $name'```

Generally, arguments to programs must be quoted to prevent Bash from
expanding them into multiple arguments.  This is easier to appreciate
when you're passing in an explicitly quoted string as in the examples
above.  But it's less obvious that quoting is required even if you're
referencing a variable.  Sometimes you want to allow a referenced
variable to be expanded into multiple arguments, and quotes should be
left off:

```
my_fave_ls_options="-l -F"
ls $my_fave_ls_options foo
```

gets expanded to

```
ls -l -F foo
```

Other times you don't:

```
query="SELECT * FROM table"
sqlite3 db "$query"
```

gets expanded to

```
sqlite3 db "SELECT * FROM table"
```

If `$query` is not quoted in the previous example, `SELECT`, `*`,
etc., will be passed as separate arguments, which is not what
`sqlite3` expects.  Making matters worse, `*` will then be interpreted
as a wildcard and expanded into a list of all files in the current
directory!

## 6. PATH determines what programs are run

A few commands (`cd`, `pwd`, `if`, `while`) are Bash built-ins.  All
other commands are simply programs on the system, whether coming
packaged along with Unix (`ls`, `cp`, `mkdir`, `grep`, etc.) or
installed later (`sqlite3`, `python`, etc.).

The `PATH` environment variable is a colon-separated list of
directories in which Bash looks for programs, in order.  You can
inspect it:

```
echo $PATH
```

To see where a command is coming from:

```
which ls
```

To see all places where you have Python installed
(cf. https://xkcd.com/1987/):

```
which -a python
```

You can modify `PATH` to, for example, add a directory to it (recall
`export` is used for environment variables):

```
export PATH=$PATH:/another/directory/I/want/Bash/to/look/in
```

It's typical to set `PATH` in one of the Bash configuration files
`~/.bash_profile` or `~/.profile`, so that it is automatically set
upon each login.

## 7. I/O redirection

Every program running in a Unix or Unix-like environment has three I/O
streams: one for input (stdin), one for output (stdout), and one for
error messages and other out-of-band output (stderr).

By convention, Unix programs read from file(s) specified on the
command line, but if none are given, from stdin.  And also by
convention, Unix programs write to stdout.  In this way it is easy to
construct pipelines.  Ex:

```
wc -l *.csv | sort -n
```

Here the `wc -l` command, which counts the number of lines in files,
is given filenames on the command line, so it counts the lines in
those files.  It writes its output to stdout.  `sort -n` sorts lines
in files.  It was given no files to sort, so it sorts whatever lines
come in via stdin.  By piping these together (i.e., by hooking `wc`'s
stdout to `sort`'s stdin using the pipe operator), the output from `wc
-l` is thereby sorted.

There are various operators for redirecting where stdin comes from and
where stdout and stderr go:

- `< file`: read stdin from file
- `> file`: write stdout to file
- `2> file`: write stderr to file
- `>& file`: write both stdout and stderr to file
- `>> file`: append stdout to file

Caution: except for `>>`, all forms of `>` are destructive: Bash
overwrites any existing file with an empty file before the program is
run.

Want to get rid of output you don't want to see?  Use the Unix black
hole: `>& /dev/null`.  (This is a cultural meme, you'll see it on
T-shirts and license plates.)

The above are the main redirections, but there are others.

## 8. Control statements

The syntax of Bash's control statements is a little funky.  A
conditional statement looks like this:

```
if [ sometest ]; then
    ...
fi
```

It can also be formatted like so:

```
if [ sometest ]
then
    ...
fi
```

What can go in inside `[ ... ]`?  A lot of things.  Believe it or not,
`[` is a program!  Do a `man [` to read about it (see section 10 for
other ways to get help).

A `for` loop iterates over a list of items:

```
for file in *.csv; do
    echo "$file has $(wc -l < $file) lines"
done
```

Recall expansions from section 4.  The `*.csv` is expanded before the
loop is run, ergo the above is equivalent to listing the files
explicitly:

```
for file in ASDN_Bird_eggs.csv species.csv ...; do
    echo "$file has $(wc -l < $file) lines"
done
```

Want to do something 99 times?  You can use a `while` loop and a
variable as a counter (recall arithmetic from section 4), or you can
use `seq` (try `seq` by itself to see what it outputs):

```
for i in $(seq 99); do
    echo "Putting $i bottles of beer on the wall"
done
```

There are other control statements.

## 9. Scripts

A Bash script is a text file containing the same Bash commands you
might type interactively.  It's analogous to an R or Python script but
written in Bash instead of one of those other languages.

Bash knows it is reading from a file instead of the terminal window,
and it operates slightly differently:

- It doesn't print a prompt.
- It doesn't read Bash configuration files (`~/.bashrc`,
  `~/.bash_profile`, `~/.profile`, etc.).  As a consequence, aliases
  and variables defined in those files are not visible to scripts.
  (Any environment variables set in configuration files *are* visible,
  but that's because environment variables are inherited.)

Bash makes arguments passed to your script available as variables
`$1`, `$2`, etc.  Variable `$#` is the number of arguments.  Ex:

```
if [ $# -ne 3 ]; then
    echo "This script requires 3 arguments"
    exit 1  # terminate with error status (exit 0 = success)
fi
```

A Bash script can be run as so:

```
bash myscript.sh
```

To run a script just by saying

```
myscript.sh
```

i.e., to make it look more like a command, requires that two things be
done:

1. The first line of the script file must be:

   ```#!/bin/bash```

   There can't be any spaces before the `#!`.  (You can similarly make
   a Python or R script directly runnable by including such a first
   line, but with the pathname of the R or Python interpreter to run.)

2. Set the "execute" flag on the script file:

   ```chmod +x myscript.sh```

   You can see that the file has the execute flag set by doing a long
   listing and looking for the `x` characters in the permissions mask.

   ```ls -l myscript.sh```

You might find that you still can't run your script just
by saying

```
myscript.sh
```

This is likely due to the current directory not being included in
`PATH`.  (`echo $PATH` to see.)  You can either qualify the script
name with a directory name:

```
./myscript.sh
```

or you can modify `PATH` per section 6.

A complete example of a script:

```
#!/bin/bash
# Add two numbers.
if [ $# -ne 2 ]; then
    echo "Supply two numbers, no more, no less"
    exit 1
fi
first=$1
second=$2
echo "The sum of $first and $second is $(( $first + $second ))"
```

## 10. Getting help and a couple tips

To get help on a command, for example `ls`, try one of the following:

```
man ls
ls --help
```

Most but not all systems support `man`; MacOS does *not* support the
`--help` option.  Failing either of those, do an internet search for
"ls man page".

When writing a script, it can be invaluable to run it through
https://shellcheck.net.  The advice is good and the creator of that
tool knows way more about Bash than you or I.  Other good resources:

- Official Bash user manual: https://www.gnu.org/software/bash/manual/
- Bash pitfalls, or, how to do things the right way:
  http://mywiki.wooledge.org/BashPitfalls
- Cheat sheet that is better than most:
  https://www.pcwdld.com/bash-cheat-sheet

And two tips.

- If you're about to embark on a potentially destructive operation,
  first try just echoing the commands to confirm they'll do what you
  want:

  ```# rename files from .JPG to .jpg```\
  ```for file in *.JPG; do```\
  ```    echo mv $file ${file/.JPG/.jpg}```\
  ```done```

  Once you're satisfied, remove `echo` and run your script for real.

- `rm`, particulary when paired with a wildcard, is a notoriously
  dangerous command: it deletes files instantly and permanently.
  Consider creating an alias

  ```alias rm="rm -i"```

  to confirm deletion.

## Test your understanding

Be sure to `cd` to the MEDS 213 git repo directory, week5
subdirectory, before answering these.

1. Compare the output of these three commands:

   ```ls```\
   ```ls .```\
   ```ls "$(pwd)/../week5"```

   Explain why you see what you see.

2. Try the following two commands:

   ```wc -l *.csv```\
   ```cat *.csv | wc -l```

   The first prints filenames and line counts.  The second prints a
   bare number.  Why does it print that number, and why does it not
   print any filenames?

3. You want to count the total number of lines in all CSV files and
   try this command:

   ```cat *.csv | wc -l species.csv```

   What happens and why?

4. You're given

   ```name=Moe```

   and you'd like to print "Moe_Howard".  You try this:

   ```echo "$name_Howard"```

   but that doesn't quite work.  What fix can you apply to make this
   command give the desired effect?

5. You create a script and run it like so:

   ```bash myscript.sh *.csv```

   What are the values of variables `$1` and `$#`?  Explain why the
   script does not see just one argument passed to it.

6. You create a script and run it like so:

   ```bash myscript.sh "$(date)" $(date)```

   In your script, what is the value of variable `$3`?

7. Create a file you don't care about (because you're about to destroy
   it):

   ```echo "yo ho a line of text" > junk_file.txt```\
   ```echo "another line" >> junk_file.txt```

   You want to sort the lines in this file, so you try:

   ```sort junk_file.txt```

   Well that prints the lines in sorted order, but it doesn't actually
   change the file.  You recall section 7 and try:

   ```sort junk_file.txt > junk_file.txt```

   What happens and why?  How *can* you sort the lines in your file?
   (Hint: it involves creating a second file and using `mv`.)

8. You want to delete all files ending in `.csv`, so you type (don't
   actually try this):

   ```rm * .csv```

   but as can be seen, your thumb accidentally hit the space bar and
   you got an extra space in there.  What will `rm` do?
