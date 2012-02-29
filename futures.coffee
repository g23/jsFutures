# Futures make dealing with this async simple.
# using monads => more correct and understandable code.

class Future
  constructor: (@val) ->
    @err = undefined # kinda bad...
    
    # states, TODO: make internal. though not necessary, just for coolness :P
    @compS = "not" # computation state: not | done | err | completed
    @readyS = "not" # ready state: not | done
    @errS = "not" # error state: not | done
    
    # the prospective handlers
    @dones = []
    @errors = []
  
  # map :: future[a]. (a -> b) -> future[b]
  map: (f) ->
    newFuture = new Future() # <- LOL, that's punny
    
    @onSuccess (v) ->
      newv = f(v)
      newFuture.value(newv)
    newFuture
  
  # flatten :: future[future[a]]. -> future[a]
  flatten: () ->
    nf = new Future()
    @onSuccess (f) ->
      f.onSuccess (v) ->
        nf.value(v)
    nf
  
  flatMap: (f) -> @map(f).flatten()
  
  # nowWhat uses state to figure out what to do.
  nowWhat: () ->
    if @compS == "not"
      return # we're not done, fast finish return
      
    if @compS == "done"
      
      if @readyS == "done"
        for done in @dones
          done(@val) # done and finish
        @compS = "completed" # otherwise it'll happen multiple times :O
      return # or just finish and when a handler is set, we'll handle it.
    
    if @compS == "err"
      if @errS == "done"
        @error(@err)
      return # maybe not needed but don't want coffeescript returning nonsense.
  
  onSuccess: (cb) ->
    @dones.push(cb)
    @readyS = "done" # the user is ready to accept it
    @nowWhat()
  
  onError: (cb) ->
    @errors.push(cb)
    @errS = "done" # the user is ready to handler errors
    @nowWhat()
  
  clearHandlers: () ->
    @dones = []
    errors = []
  
  # used in making Future using APIs
  # ex. xhr("my/path/to/shit", f.callback)
  # gotta use fat arrow b/c many things reset the `this'
  callback: (v) =>
    @val = v
    @compS = "done" # set the computational state to done
    @nowWhat()
  
  errCallback: (e) =>
    @err = e
    @compS = "err" # computation was an error
    @nowWhat()
  
    
  # aliases
  # value for pure things, callback for async. mearly stylistic choice.
  value: (v) -> @callback(v)

# collect takes a sequence of futures and makes a future of a sequence :D
# keeping order! :D
Future.collect = (fs) ->
  nf = new Future()
  numfs = fs.length
  count = 0
  res = []
  _.each fs, (f, i) ->
    f.onSuccess (v) ->
      res[i] = v
      count++
      if count == numfs
        nf.value(res)
  nf

# export it!

window.Future = Future

# pseudo-tests TODO: replace w/ QUnit
console.log "Futures work asynchronously"

window.f = new Future()
f.onSuccess (v) ->
  console.log "onSuccess set before a value existed"
  console.log "value is", v
console.log "Set the success handler, now setting the value."  
f.value(23)

window.f2 = f.map ((a) -> 4*a)

console.log "testing future.map"
f2.onSuccess (v) ->
  console.log "23 times 4 is...", v

window.f3 = new Future()
window.f4 = new Future()
f3.value(23)
f4.value(f3)

console.log "futures can contain futures"
f4.onSuccess (v) ->
  console.log "f4's value:", v

window.f5 = new Future()
window.f6 = new Future()
f5.value(23)
f6.value(f5)

console.log "Futures can be flattened"
f6.flatten().onSuccess (v) ->
  console.log "f6's flattened value", v

console.log "futures are monadic, flatMap <=> monadic bind"
window.f7 = new Future()
f7.value(23)

f8 = f7.flatMap (v) ->
  t = new Future()
  t.value(v*5)
  t

f8.onSuccess (v) ->
  console.log "23 times 5 is", v

console.log "Now going to demo the collect feature"
window.fs = [new Future(), new Future(), new Future()]
window.f9 = Future.collect(fs)
f9.onSuccess (vs) ->
  console.log "The collected futures had values:", vs

# it's important to set these values out of order to assure the well orderedness
fs[0].value(1)
fs[2].value(3)
fs[1].value(2)

# time for a more ellaborate test... will be moved to the top later
# delayed takes a number and a callback then sends the number to the callback after 1 sec.
window.delayed = (num, callback) ->
  setTimeout(callback(num), 1000)

