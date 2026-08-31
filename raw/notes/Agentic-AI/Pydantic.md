In Python, all the variable is dynamic variable, that means we do not mention any data type of a variable when defining it. Any other programming languages use the static approach, that means we first mention the data type, then we create the variable and store the value.

### What is Pydantic?
Pydantic is the most widely used data validation and settings management library for Python, utilizing type hints to ensure data structure integrity. It validates, parses, and coerces data at runtime to match specified types. Its core logic is written in Rust for high performance.

### Key Features and Benefits
- **Data Validation & Parsing:** Defines how data should be structured using standard Python types, automatically enforcing these rules.
- **Type Hint Integration:** Uses Python's type annotations to define schemas, reducing the need for verbose validation code.
- **Fast Performance:** The core validation engine is written in Rust, making it extremely fast.
- **Strict & Lax Modes:** Support both strict mode (enforcing strict types) and lax mode (attempting to coerce data, e.g. converting string`"1"` to int `1`)
- **Clear Error Handling:** Provides detailed errors when data validation fails.
- **JSON Schema Generation:** Pydantic model can easily generate JSON schema for documentation or validation in other languages.

### Problem without Pydantic
Whenever we're creating the real application, we will not be working with just a few input data, there would be lots of data. It is not feasible to write so many conditions for validating all the input data like the example code below. 
``` python
def add_patient_data(name: str, age: int):
	if type(name) == str and type(age) == int:
		if age >= 0:
			print(name)
			print(age)
			print("Data added successfully to database!")
		else:
			raise ValueError("Age cannot be negative.")
	else:
		raise TypeError("Invalid data type for name or age. Name should be a string and age should be an integer.")
```
``` python
add_patient_data("Bappy", 25)

add_patient_data("Bappy", "twenty five")

add_patient_data("Bappy", -25)
```

### How to Use Pydantic
1. **Define a Pydantic model** (inheriting from Pydantic class) that represents the **ideal schema** of the data.
   This includes the expected fields, their types, and any validation constraints (e.g., `gt=0` for positive numbers).
2. **Instantiate the model with raw input data** (usually a Dict or JSON-like structure).
   Pydantic will automatically validate the data and coerce the data into the correct Python data types (if possible). If the data does not meet the model's requirements, Pydantic raises a `ValidationError`.
3. **Pass the validated model object** to functions or use it throughout your codebase.
   This ensures that every part of your program works with clean, type-safe, and logically valid data.
``` python
from pydantic import BaseModel

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    age: int

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "age": 25}
# Pass the data into the Pydantic Object to create the Object
patient1_obj = PatientData(**patient_data)
patient_data = {"name": "Alex", "age": "25"}
patient2_obj = PatientData(**patient_data)

# Pass in the Pydantic Object
add_patient_data(patient1_obj)
add_patient_data(patient2_obj)
```

If we require a List as the data type, we should import the `List` from Typing module, because the default Python list will not work, same goes to `Dict`.
``` python
from pydantic import BaseModel
from typing import List, Dict

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    age: int
    weight: float
    married: bool
    allergies: List[str]
    contact_info: Dict[str, str] ## key & value should be string

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "age": 25, "weight": 70.5, "married": False, "allergies": ["pollen", "dust"], "contact_info": {"email": "bappy@example.com", "phone": "123-456-7890"}}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

#### Required & Optional Fields
When we're creating the Pydantic schema or model, whatever data we're writing in the schema, we have to give all of these fields in our raw data. If we skip any of them, it will throw us the `ValidationError`. However we can make the field optional by wrapping the data type with `Optional[]` and defining a default value (compulsory). Defining a default value to any fields also could make the field optional even without wrapping in `Optional[]`.
``` python
from pydantic import BaseModel
from typing import List, Dict, Optional

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    age: int
    weight: float
    married: bool = False
    allergies: Optional[List[str]] = None
    contact_info: Dict[str, str] ## key & value should be string

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.married)
    print(patient.allergies)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "age": 25, "weight": 70.5, "contact_info": {"email": "bappy@example.com", "phone": "123-456-7890"}}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

#### Data Validation
Pydantic allows us to do data validation (validate the correct data format or structure). We can validate the email format using `EmailStr` and web url format using `AnyUrl` from Pydantic. We can also customize data validator using `Field` from Pydantic.
``` python
from pydantic import BaseModel, EmailStr, AnyUrl, Field
from typing import List, Dict, Optional

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str = Field(max_length=50)
    email: EmailStr
    linkedin_url: AnyUrl
    age: int = Field(gt=0, lt=100)
    weight: float
    married: bool = False
    allergies: Optional[List[str]] = Field(default=None, max_length=5)
    contact_info: Dict[str, str] ## key & value should be string

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print(patient.allergies)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "email": "bappy@example.com", "linkedin_url": "https://www.linkedin.com/in/bappy", "age": 25, "weight": 70.5, "married": False, "allergies": ["peanuts"], "contact_info": {"phone": "123-456-7890"}}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

We can write in metadata (e.g., title, description) into the schema using the `Field` from Pydantic and `Annotated` from Typing. If the float type was given and the `strict=True` in Field() was set, this will only receive the float type (70.5) and will throw error if given string type ("70.5").
``` python
from pydantic import BaseModel, EmailStr, AnyUrl, Field
from typing import List, Dict, Optional, Annotated

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: Annotated[str, Field(max_length=50, title="Name of the patient", description="Given the name of the patient in less than 50 chars", examples=['Bappy', 'Alex'])]
    email: EmailStr
    linkedin_url: AnyUrl
    age: int = Field(gt=0, lt=120)
    weight: Annotated[float, Field(gt=0, strict=True, description="Weight of the patient in kg")]
    married: Annotated[bool, Field(default=None, description="Is the patient married or not")]
    allergies: Annotated[Optional[List[str]], Field(default=None, max_length=5)]
    contact_info: Dict[str, str] ## key & value should be string

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print(patient.allergies)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "email": "bappy@example.com", "linkedin_url": "https://www.linkedin.com/in/bappy", "age": 25, "weight": "70.5", "married": False, "allergies": ["peanuts"], "contact_info": {"phone": "123-456-7890"}}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

#### Field Validator
We can create our own function and write our custom rules to validate a field, using `field_validator` from Pydantic. When defining the custom validation function, two decorators `@field_validator(field-name)` and `@classmethod` must be used.
``` python
from pydantic import BaseModel, EmailStr, field_validator
from typing import List, Dict, Optional, Annotated

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    email: EmailStr
    age: int
    weight: float

    @field_validator('email')
    @classmethod
    def email_validator(cls, value):
        valid_domains = ["hdfc.com", "icici.com"]
        domain_name = value.split("@")[-1]
        if domain_name not in valid_domains:
            raise ValueError("Not a valid domain.")
        return value

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "email": "bappy@example.com", "age": 25, "weight": 70.5}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```
We also can preprocess the field data using `field_validator`. For example, capitalizing the name.
``` python
from pydantic import BaseModel, EmailStr, field_validator
from typing import List, Dict, Optional, Annotated

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    email: EmailStr
    age: int
    weight: float

    @field_validator('name')
    @classmethod
    def transform_name(cls, value):
        return value.upper()

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "email": "bappy@hdfc.com", "age": 25, "weight": 70.5}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

#### Model Validator
Field Validator allows us to do single field validation, for doing multiple field validation, we use Model Validator instead. For example, if a patient age is greater than 60, the contact details should be a emergency number, this condition would take two fields (age & contact_details).
``` python
from pydantic import BaseModel, EmailStr, model_validator
from typing import List, Dict

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    email: EmailStr
    age: int
    weight: float
    contact_details: Dict[str, str]

    @model_validator(mode="after")
    def validate_emergency_contact(cls, model):
        if model.age > 60 and "emergency" not in model.contact_details:
            raise ValueError("Patients older than 60 years old must have an emergency contact.")
        return model

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "email": "bappy@hdfc.com", "age": 70, "weight": 70.5, "contact_details": {"phone": "1234567890"}}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

#### Computed Fields
Computed Field does a computation on user inputs and generates a completely new data based on the same user inputs. For example, the patient has given the weight and height, but we want to calculate the BMI based on the weight and height. Two decorators `@computed_field` and `@property` must be used.
``` python
from pydantic import BaseModel, EmailStr, computed_field
from typing import List, Dict

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    email: EmailStr
    age: int
    weight: float
    height: float

    @computed_field
    @property
    def cal_bmi(self) -> float:
        bmi = round(self.weight/(self.height**2),2)
        return bmi

def add_patient_data(patient: PatientData):
    print(patient.name)
    print(patient.age)
    print(patient.weight)
    print("BMI:", patient.cal_bmi)
    print("Data added successfully to the database!")

# Prepare the raw input in Dict or JSON
patient_data = {"name": "Bappy", "email": "bappy@hdfc.com", "age": 70, "weight": 70.5, "height": 1.75}
# Pass the data into the Pydantic Object to create the Object
patient_obj = PatientData(**patient_data)
# Pass in the Pydantic Object
add_patient_data(patient_obj)
```

#### Nested Model
Pydantic model or class can be nested, which means a Pydantic model can be inside of another Pydantic model.
``` python
from pydantic import BaseModel

class Address(BaseModel):
    city: str
    state: str
    pin: str

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    age: int
    address: Address

address_dict = {"city": "gurgaon", "state": "haryana", "pin": "122001"}
address1 = Address(**address_dict)

patient_dict = {"name": "Bappy", "age": 70, "address": address1}
patient1 = PatientData(**patient_dict)

print(patient1)
print(patient1.name)
print(patient1.address)
print(patient1.address.city)
```

#### Serialization
The Pydantic Object can be exported as a Dict or a JSON. This serialization is required when we created a Pydantic object and we have done the data validation, we want to save the result as a file to be used or loaded later on.
``` python
from pydantic import BaseModel

class Address(BaseModel):
    city: str
    state: str
    pin: str

class PatientData(BaseModel):
    # Schema defines the data and the type of the data.
    name: str
    age: int
    address: Address

address_dict = {"city": "gurgaon", "state": "haryana", "pin": "122001"}
address1 = Address(**address_dict)

patient_dict = {"name": "Bappy", "age": 70, "address": address1}
patient1 = PatientData(**patient_dict)

temp = patient1.model_dump() ## returns a Dict
# temp = patient1.model_dump_json() ## returns a JSON

print(temp)
print(type(temp))
```

