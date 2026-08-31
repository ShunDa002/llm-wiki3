# Object Oriented Programming (OOP)
OOP is a compelling solution when our programs get longer and longer and the codes become more complicated.

The code below is correct:
``` python
name = input("Name: ")
house = input("House: ")
print(f"{name} from {house}")
```

Not necessarily to solve the problem more correctly, but we extends the building blocks to solve more complicated programs.
For example below, we wrote get_name() function and get_house() function which are super simple functions but they are abstractions. We do not have to care about the implementation details, we just know that the functions exist.
``` python
def main():
    name = get_name()
    house = get_house()
    print(f"{name} from {house}")

def get_name():
    return input("Name: ")

def get_house():
    return input("House: ")

if __name__ == "__main__":
    main()
```

But at the end of the day, we want to get a student from the user, we want their name and their house together, not just one or the other. It would be cleaner to define a function called get_student() and let get_student() do all of this work.
## Tuple
Tuple is a type of data in Python that is a collection of values x, y, z, etc. 
It is similar to List, but it is immutable. We can change the values inside List, we can go into \[0] for the first location, \[1] for the second location and so on, then change the value.
If we do not want to change the values of variables, and we want to return multiple values, we can return it as a Tuple.
When we want to program defensively or when we know that the values in this variable should not change, we should use Tuple.
List is indicated by \[ ] , while Tuple is indicated by ( ) .
``` python
def main():
    name, house = get_student()
    print(f"{name} from {house}")

def get_student():
    name = input("Name: ")
    house = input("House: ")
    return name, house # Actually just one value was returned here, which is a tuple (name, house).
    # OR
    # return (name, house)  # This is the same as the previous line.

if __name__ == "__main__":
    main()
```
> [!NOTE] return name, house
> Actually just one value was returned here, which is a tuple (name, house) .

We can also assign the values of tuple to just one variable. Maybe this is a better design, because we abstract away what a student is.
``` python
def main():
    student = get_student()
    print(f"{student[0]} from {student[1]}")

def get_student():
    name = input("Name: ")
    house = input("House: ")
    return name, house

if __name__ == "__main__":
    main()
```

Dict is more powerful that we can semantically associate keys with the values. Dict allows us better semantic, no one be able to remember forever that 0 is name, 1 is house and if there is more values, instead "name" is name and "house" is house, so this is clearer and more expressive.
Dict is also mutable like List, we can change the values inside it.
``` python
def main():
    student = get_student()
    print(f'{student["name"]} from {student["house"]}')

def get_student():
    student = {}
    student["name"] = input("Name: ")
    student["house"] = input("House: ")
    return student

if __name__ == "__main__":
    main()
```

We do not introduce variables unnecessarily unless they make the code more readable, so alternatively we can consolidate the *student\["name"] = input("Name: ")* and *student\["house"] = input("House: ")* into one statement.
``` python
def main():
    student = get_student()
    print(f'{student["name"]} from {student["house"]}')

def get_student():
    name = input("Name: ")
    house = input("House: ")
    return {"name": name, "house": house}

if __name__ == "__main__":
    main()
```

## Class
Class allows us to create our own data types and give them names.
A class is like a blueprint or mold for pieces of data or an object, where we use this blueprint or mold and we get types of data that are designed as we want.
``` python
class Student:
	...

def main():
    student = get_student()  # Instantiate an object from Student class
    print(f'{student.name} from {student.house}')

def get_student():
    student = Student()
    student.name = input("Name: ")
    student.house = input("House: ") # name & house are attributes or instance variables inside of an object whose type is Student
    return student

if __name__ == "__main__":
    main()
```
> [!INFO] student = get_student()
> Instantiate an object from Student class

> [!NOTE] student.name & student.house
> name & house are attributes or instance variables inside of an object whose type is Student

Unlike Dict, we can standardize the attributes and their values inside a class.
By defining a class, we get a function whose name is identical to the class name.
For example, Student() function from the Student class. We pass name and house to the Student class with this particular function, we can have more control over the correctness of our data.
### Method
Class also comes with certain methods or functions inside of them that we can define. These functions allow us to determine behavior in a special way by nature of how Python works, they are special methods.
#### Instance Method
double underscore init method or dunder init method is known as as Instance Method. We define \__init\__() method when we want to initialize the contents of an object from a class.
It is not all that different from adding keys to dictionaries, but here we are adding variables to objects (a.k.a. instance variables to objects).   
``` python
class Student:
	def __init__(self, name, house):
		self.name = name
		self.house = house

def main():
    student = get_student()  # Instantiate an object from Student class
    print(f'{student.name} from {student.house}')

def get_student():
    name = input("Name: ")
    house = input("House: ")
    student = Student(name, house)  
    # Constructor call that construct/initialize a student object, by using the Student class as a template/mold, so that every student is structured the same. Every student will have name and house. But we can pass in arguments to this Student() function, we are able to customize the contents of that object (different name and different house).
    return student

if __name__ == "__main__":
    main()
```
> [!NOTE] student = Student(name, house)
> Constructor call that construct/initialize a student object, by using the Student class as a template/mold, so that every student is structured the same. Every student will have name and house. But we can pass in arguments to this **Student()** function, we are able to customize the contents of that object (different name and different house).

> [!NOTE] Student(name, house)
> The **Student()** function that will always be called when instantiating the student object is the def **\__init\__(self)** function inside the Student class. The self inside the **init\_(self)** function gives us access to the current object that was just created. For example, **self.name = name** means we store value name into the object.

With class, we can ensure the correctness of data, error checks things, and generally design more complicated software effectively.
OOP encourages us to encapsulate all functionalities related to the class inside of that class. Keeping all of the related code together is better for organization.
For example, if we want to validate that a name exists or if we want to validate that a house is correct, that belongs in the class called Student itself.
## raise
raise allows us to raise or create the exceptions when we caught errors, in order to signal the error and alert the programmer.
The flipside of the feature of exceptions is that we can raise the exceptions and pass to them an explanatory message as an argument.
``` python
class Student:
	def __init__(self, name, house):
		if not name:
			raise ValueError("Missing name")
		if house not in ["Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"]
			raise ValueError("Invalid house")
		self.name = name
		self.house = house

def main():
    student = get_student()
    print(f'{student.name} from {student.house}')

def get_student():
    name = input("Name: ")
    house = input("House: ")
    try:
	    return Student(name, house)
	except Value:
		...

if __name__ == "__main__":
    main()
```
If we add an attribute to a Dict, no matter what, even if the value is empty, it is going into that Dict. But with the class and by way of the \_init\_() method, we can control what will be inserted inside of the object.

