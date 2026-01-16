# Coll

Let us consider this simple JSON:

```json
{
  "items": [
    {
      "name": "busybox",
      "image": "busybox:latest",
      "replicas": 1,
    },{
      "name": "nginx",
      "image": "nginx:latest",
      "replicas": 2
    }
    ]
}
```

Quite a common structure. There is no way to translate this 1:1 with coll. The closest would be:

```
items	busybox	image	busybox:latest
items	busybox	replicas	1
items	nginx	image	nginx:latest
items	nginx	replicas	2
```

That looks pretty nice, but not a 1:1.

If we try 1:1 it would look something like this:

```
items	name	busybox
items	image	busybox:latest
items	replicas	1
items	name	nginx
items	image	nginx:latest
items	replicas	2
```

But now we just duplicated each key, with a different set of values. Perfectly legal in Coll, and to convert that back to JSON would look like this:

```json
{
  "items": {
    "name": ["busybox", "nginx"],
    "replicas": [1, 2],
    "image": ["busybox:latest", "nginx:latest"],
  }
}
```

Which is not what we wanted. What we want is:

```
items	1	name	busybox
items	1	image	busybox:latest
items	1	replicas	1
items	2	name	nginx
items	2	image	nginx:latest
items	2	replicas	2
```

This is also legal in coll. But what we lack is any kind of logic related to finding the next available number. For example say we want to insert a new name/image/replicas object as a new list item. Or what if we delete all entries where `items	1`, then we need to reorder the list, that is not done automatically.

We have smaller pieces to the puzzle, for example:

`coll c add-value-at 'items 3 name' 0 'sqlite'`

So what we need is a function to find the next available number. Perhaps something like this:

`coll c add-value-at 'items 0 name' 0 'sqlite'`
`coll c add-value-at 'items 2 name' 0 'sqlite'`

In the first example we insert at the bottom using `0`, which is known to insert at bottom in coll.

In the second we insert as the second item, failing if list is smaller than 2.

Also need a function around `add-value-at` so we do not have to specify column 4 (`0`) each time.

Then we need a function that sort then do a new count.

`coll c normalise 'items ?'`. They also need to take into account multiple and or nesting numbered lists:

`coll c normalise 'items ? probes ?'`.

Where `probes` can have multiple entries.

Today `[0-9?]` are legal keys in and of itself. With this change it would have a special meaning and be off limit as a key name. In most object notations, having a key start with an integer is generally not allowed; neither is `?` anywhere in the keyname.

What we describe above used to be an experiemental setting for coll's predecesor `argus`, by enabling "ARGUS_NILIST". All that code was removed from coll, but we might use it as a referance in the future.
