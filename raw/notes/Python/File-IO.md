### open()
open() is a function whose purpose is to do just that, to open a file. First argument is the file name and second argument is optionally how we want to open it. 

#### "w"
"w" for write, which tells the open() to open the file in a way that allows us to change the content, and if it does not even exist yet, it will create the file. 
open() returns a file handler, which is a special value that allows us to access that file.
write() allows us to write into the file.
close() closes and saves the file.
``` python
name = input("What's your name? ")

file = open("names.txt", "w")
file.write(name)
file.close()
```

#### "a"
"w" not only will create the file, it will also recreate the file every time we open the file.
If we want to be appending the content to the file, not just clobbering that is overwriting the file each time, instead use "a" . 
"a" for append, which adds to the file, to the file, again and again.
``` python
name = input("What's your name? ")

file = open("names.txt", "a")
file.write(name)
file.close()
```

"a" has the effect of combining the content back to back, if no new line was added. 
Use the f strings to print the name and the new line all at once:
``` python
name = input("What's your name? ")

file = open("names.txt", "a")
file.write(f"{name}\n")
file.close()
```

### with
A more Pythonic to manipulate the file, we do not strictly need to call close() on the file, instead use with.
with allows us to specify that in this context, we want to open and automatically close the file.
``` python
name = input("What's your name? ")

with open("names.txt", "a") as file:
	file.write(f"{name}\n")
# The line of code that is writing the file is in the context of this with statement, which ensures to automatically close the file as soon as the code in the with statement is done executing.
```

#### "r"
"r" to read a file, just means to load it.
readlines() reads all the lines from the file and returns them in a list.
``` python
with open("names.txt", "r") as file:
	lines = file.readlines()
	
for line in lines:
	print("hello,", line.rstrip())
```

Combine the reading all the lines and iterating over all of those lines into one thing. 
We open the file, then use for loop to iterate over every line in the file one at a time, and on each iteration updating the value of this variable "line". 
open() is default with "r".
``` python
with open("names.txt") as file:
	for line in file:
		print("hello,", line.rstrip())
```

We can create a variable at the top like a list, adding or appending information to it, just to collect it in one place and then do something with that collection or list (sorting, uppercasing or else). This is a good practice to make changes to the data.
``` python
names = []

with open("names.txt") as file:
	for line in file:
		names.append(line.rstrip())
		
for name in sorted(names):
	print(f"hello, {name}")
```

Actually the variable file can be sorted:
``` python
with open("names.txt") as file:
	for line in sorted(file):
		print("hello,", line.rstrip())
```

iterable means something that we can iterate over it, that is we can loop over it one thing at a time.

#### csv
csv stands for comma separated values, is a very common convention to store multiple pieces of information that are related in the same file.

> [!NOTE] students.csv
> ```
> Hermione,Gryffindor
> Harry,Gryffindor
> Ron,Gryffindor
> Draco,Slytherin
> ```

The for loop reads the whole line of text at once, but we want to get access to the individual values, like "Hermione" and "Gryffindor" separately.
When iterating over a .csv file, it is a convention to think each line of it as a row, and each of the values therein separated by commas as columns.
> [!NOTE] students.py
> ``` python
> with open("students.csv") in file:
> 	for line in file:
> 		row = line.rstrip().split(",")
> 		print(f"{row[0]} is in {row[1]}")
> ```

We can unpack the list into two variables since we know in advance, there are two values(name & house) will be returned by this split().
> [!NOTE] students.py
> ``` python
> with open("students.csv") in file:
> 	for line in file:
> 		name, house = line.rstrip().split(",")
> 		print(f"{name} is in {house}")
> ```
