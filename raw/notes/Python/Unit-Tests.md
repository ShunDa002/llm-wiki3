A good practice is writing testing code to test the program code. We should test some representative inputs.
> [!NOTE] calculator.py
> ``` python
> def main():
> 	x = int(input("What's x? "))
> 	print("x squard is", square(x))
> 
>def square(n):
>	return n * n
> 	
> if __name__ == "__main__":
> 	main()
> ```
