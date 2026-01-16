# Pixie

Pixie is a POSIX library to help you create portable awesome POSIX shell scripts, libraries or profile add-ons.

Pixie greatest hits:

- named function arguments
- portable random function
- nested assosiative arrays with batteries
- String functions like replace and whitespace trim
- Ansible like text manipulation like lineinfile
- Check if an element is part of a list, is an int, and many more
- convenient math function
- provide examples and best practices

Some examples:

## Math

```sh
PixieMath add 4 4
=> 8
```

In `Pixie` you can also always use the short package name. And often aliases which means you have to type even less

```sh
Math add 4 4
=> 8
madd 4 4
=> 8
```

Often a function has different names as well, for example we can also do:

```sh
PixieMath + 4 4
=> 8
```

Below is a list of all available functions:

-	`+` | add | sum
-	`-` | sub | substract
-	/ | div | divide
-	`*` | x | mul | multiply
-	% | mod | modulo
-	avg | average
-	max | maximum
-	min | minimum

## String

To replace a value in a string:

```sh
String replace value='u' match='o' in='fuubar'
=> foobar
str_replace 'u' 'o' 'fuubar'
=> foobar
```

Or what about trimming those pesky whitespaces?

```sh
String strim '  hello    world   '
=> hello world
```

ltrim, rtrim and trim available as well.

# named function arguments

As seen above with `String replace` and `str_replace` a function can support both named arguments and numbered arguments at the same time!

```sh
ini_kv() {
	PixieArgs kv-to-var "$@" __mypkg_myfn_
	shift $__mypkg_myfn_0

	: ${__mypkg_myfn_key=$1}
	: ${__mypkg_myfn_value:=$2}
	
	printf '%s=%s\n' "$__mypkg_myfn_key" "$__mypkg_myfn_value"
	
	unset __mypkg_myfn_key __mypkg_myfn_value
}
```

Then call with:

```sh
ini_kv key=a value=b
=> a=b
ini_kv a b
=> a=b
```

You can even add iterables.

```sh
greet() {
	PixieArgs kv-to-var "$@" __mypkg_myfn_
	shift $__mypkg_myfn_0

	: ${__mypkg_myfn_greeting='Hello'}
	
	while test $# -gt 0; do
		printf '%s %s\n' "$__mypkg_myfn_greeting" "$1"
		shift
	done
	
	unset __mypkg_myfn_greeting
}
```

```sh
greet greeting='Greetings to you' -- Steve Bill Larry
=> Greetings to you Steve
=> Greetings to you Bill
=> Greetings to you Larry

greet -- Steve Bill Larry
=> Hello Steve
=> Hello Bill
=> Hello Larry
```

# Coll

To create a collection simple just add something to it:

```sh
coll my_coll add 'name' 'Argus Array'
coll my_coll add 'status reactor' true false
coll my_coll get-value 'status reactor'
=> true
=> false
```

And so much more. You can add, add and remove from top/bottom/index and so on. Values can contain newline, tabs, etc. without any issues.

# And so much more

I will improve the README in time, but for now take a look in `test/lib`, not 100% complete either though.
