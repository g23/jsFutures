# jsFutures

Futures are a monad that makes handling asynchronous programming super simple. No more callback hell. This is an implementation of Futures using CoffeeScript.

Using futures effectively does require a bit of careful coding. Currently using <code>flatMap</code> with some function requires the function to return a future. This is how futures should be used (monads!) but right now if one doesn't return a future there will probably be a big error. Currently more helper functions and prettier errors are being worked on.

## Examples

simple case:

    f = new Future();
    f.onSuccess(function(res) { console.log(res)});
    f.value(23);
    // now 23 is logged

Full examples can be found in the examples folder. Currently the examples are:

* sounds.coffee - Making the SoundManager2 API future friendly.
* more soon...

## Current Status

Currently these futures work and will clean up a lot of code. They do need error handling though as the current <code>onError</code> method was half-assed and remains untested. Though the futures will soon be able to handle asynchronous exceptions, something that most callback spaghetti does not take care of.

## Note

Monads tend to have an all or nothing approach. Because of that (and futures are monads), the real utility of Futures won't be realized until there are more futures based libraries. I plan to port of a number of useful Node.js libraries to use futures so that the usefulness of futures (and monads) will be much more evident.

