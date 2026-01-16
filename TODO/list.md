# List

Create a package called List. Kinda like PixieColl, but only a single escaped list.

I thought about implementing it on top of PixieColl, using the key "_" as default:

`coll c add _ 'value'`

Then add some helper function on top and call it a day. But perhaps reimplement with simpler logic, to improve speed.

Usage example:

```
list my_list add 'foo' 'bar'
list my_list rm-at 2
```

The list now only contains `foo`. Use same sub-function names as PixieColl (add, rm, etc.).
