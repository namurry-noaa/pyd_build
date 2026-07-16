def add(a, b):
    """Add two numbers."""
    return a + b

def greet(name):
    """Return a greeting."""
    return f"Greetings Hello, {name}: this is an example *.py file to be made into a Cython-compiled PYD."

def compute(n):
    """A trivial loop to show it runs."""
    total = 0
    for i in range(n):
        total += i * i
    return total