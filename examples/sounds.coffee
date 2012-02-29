# Making the SoundManager2 API future friendly

# Note: I use Haskell-ish "type signatures" so that I know what each function does.
# TODO: replace with more useful comments.

# This was actually taken from a real project I was working on.
# I needed futures because ordering sounds requires lots of callbacks.

# makeSound :: String -> Future[SoundId]
makeSound = (num) ->
  f = new Future()
  soundManager.createSound({
    "id": "s#{num}"
    "url": "/audio/DTMF-#{num}.mp3"
    autoPlay: false
    autoLoad: true
    onload: () -> f.value(@sID) # when we're done set the future's value.
    volume: 50
  })
  f.onSuccess (sid) ->
    console.log "future loaded with sid:", sid # add a logger
  f # return the future

# playSound :: String -> Future[()]
#
# playSound is a future adaption to SM2's play()
# optionally allows to play the sound for a given amount of time t
# super useful b/c of monads!
playSound = (sid, t) ->
  f = new Future()
  if t == undefined
    soundManager.play sid, {"onfinish": f.callback}
    return f
  # else, the time is given, need to do some magic
  soundManager.play sid, {
    "onfinish": f.callback # same old same old
    "onstop": f.callback # we might stop the music after a while
    "onplay": () -> 
      # set the stopper thing
      setTimeout () ->
        soundManager.stop(sid)
      , t
  }
  f # return this awesome monadic thing

# make a button click play 3 tones in order
# queryString -> SoundId -> SoundId -> SoundId -> ()
threeToneSeq = (q, a, b, c) ->
  $(q).click () ->
    playSound(a, 500).flatMap () ->
      playSound(b, 500)
    .flatMap () ->
      playSound(c, 500)
  # total ^ awesomeness, eh?
  # since playSound() returns a future we can flatMap to make a sequential chain

# sounds is used to manage loading all the sound and to know when we can use them
window.sounds = new Future() # kinda pointless to init since it's overwritten later

initSound = () ->
  futures = []
  # main purpose of futures is to assure everything is loaded.
  for i in [0..9]
    futures.push makeSound(i)
  
  # We have a list of futures to wait on
  # Instead need a future with a list
  # use Future.collect!
  sounds = Future.collect(futures)
  sounds.onSuccess () -> # no param because makeSound returns an empty future
    # now we know all the sounds loaded
    # use the future-friendly playSound method to setup sequences
    threeToneSeq('#start', 's1', 's4', 's9')
    threeToneSeq('#lock', 's1', 's2', 's1')
    threeToneSeq('#unlock', 's2', 's1', 's2')
    threeToneSeq('#acup', 's1', 's3', 's1')
    threeToneSeq('#acdown', 's3', 's1', 's3')
    threeToneSeq('#winup', 's2', 's3', 's2')
    threeToneSeq('#windown', 's3', 's2', 's3')
    

# and finally basic sound manager stuff
soundManager.url = '/swf/' # apparently swf necessary for SM2 (?)
soundManager.flashVersion = 9

soundManager.onready(initSound)

