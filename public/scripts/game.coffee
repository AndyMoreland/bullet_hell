window.g = {}
window.i = 0

RENDER_TIME = 25
WIDTH = 600
HEIGHT = 800
PLAYER_SPEED = 5
SCROLL_SPEED = 0.5
DEBUG = false
IMAGES = {}
NOTIFICATION_TIMER = null

notify = (message) ->
  clearTimeout(NOTIFICATION_TIMER)
  $("#notifications").empty().append(message).show(300)
  NOTIFICATION_TIMER = window.setTimeout ->
    $("#notifications").hide(300)
  , 3000

class g.Game
  constructor: () ->
    @loadImages()
    @canvas = $("canvas")[0]
    @score = 0
    @renderStack = []
    @updateStack = []
    @renderCount = 0
    @enemyBullets = []
    @playerBullets = []
    @noRender = false

    @setupCanvas()

    @setupClear()
    @createBackground()
    @initalizeBoardBounds()
    @initializeKeybindings()
    @initializePlayer()
    @initializeLevelManager()
    @miscInit()
    @initializePlayerStatusTracker()
    @setupBulletClearer()
    @initializeDebug()


    @gameTimer = window.setInterval @gameLoop, RENDER_TIME

  loadImages: () =>
    IMAGES["25_enemy_1"] = new Image()
    IMAGES["25_enemy_2"] = new Image()
    IMAGES["25_enemy_3"] = new Image()
    IMAGES["25_enemy_4"] = new Image()
    IMAGES["25_enemy_5"] = new Image()
    IMAGES["50_wide_enemy_1"] = new Image()
    IMAGES["50_wide_enemy_2"] = new Image()
    IMAGES["boss"] = new Image()
    IMAGES["player"] = new Image()
    IMAGES["shower"] = new Image()

    IMAGES["25_enemy_1"].src = "/images/sprites/25_enemy_1.png"
    IMAGES["25_enemy_2"].src = "/images/sprites/25_enemy_2.png"
    IMAGES["25_enemy_3"].src = "/images/sprites/25_enemy_3.png"
    IMAGES["25_enemy_4"].src = "/images/sprites/25_enemy_4.png"
    IMAGES["25_enemy_5"].src = "/images/sprites/25_enemy_5.png"
    IMAGES["50_wide_enemy_1"].src = "/images/sprites/50_wide_enemy_1.png"
    IMAGES["50_wide_enemy_2"].src = "/images/sprites/50_wide_enemy_2.png"
    IMAGES["boss"].src = "/images/sprites/boss.png"
    IMAGES["player"].src = "/images/sprites/player.png"
    IMAGES["shower"].src = "/images/sprites/shower.png"



  setupCanvas: () =>
    @context = @canvas.getContext('2d')
    @context.lineWidth = 1
    @context.strokeStyle = "#000"
    @context.globalApha = 1.0
    @canvas.width = WIDTH
    @canvas.height = HEIGHT

  setupClear: () =>
    @renderStack.push(new g.CanvasClearer())

  initalizeBoardBounds: =>
    @board = new g.Board()

  initializePlayer: =>
    @player = new g.Player()
    @updateStack.push(@player)
    @renderStack.push(@player)

  miscInit: =>
    level = new g.TestLevelOne(10, @)
    levelTwo = new g.SecretLevel(10, @)
    @levelManager.levelQueue.push(level)
    @levelManager.levelQueue.push(levelTwo)
    @updateStack.push(@levelManager)
    @renderStack.push(@levelManager)

  createBackground: () =>
    @backgroundLayer = new g.BackgroundLayer()
    @updateStack.push(@backgroundLayer)
    @renderStack.push(@backgroundLayer)

  initializeDebug: () =>
    @debugLayer = new g.DebugLayer()
    @renderStack.push(@debugLayer)

  initializeLevelManager: () =>
    @levelManager = new g.LevelManager()

  setupBulletClearer: () =>
    @updateStack.push(new g.BulletClearer())

  gameLoop: =>
    console.group("Render number ", @renderCount) if DEBUG

    for updateable in @updateStack
      updateable.update() if updateable.update

    for renderable in @renderStack
      renderable.render(@context) if renderable.render && @noRender == false

    console.groupEnd() if DEBUG
    @renderCount++

  initialize_player: () =>
    @player = new g.Player()

  initializePlayerStatusTracker: =>
    @statusTracker = new g.PlayerStatusTracker(@player)
    @updateStack.push(@statusTracker)

  initializeKeybindings: () =>
    @keyboardHandler = new g.KeyboardHandler(@)
    @updateStack.push(@keyboardHandler)

  _displayDeath: =>
    @context.globalAlpha = 0.5
    @context.fillStyle = "#666"
    @context.fillRect(0, 0, WIDTH, HEIGHT)
    @context.globalAlpha = 1.0
    @context.fillStyle = "#A00"
    @context.font = "bold 48px Arial"
    @context.fillText "You have died!", 130, 300
    @context.font = "32px Arial"
    @context.fillText "Respawning in 3 seconds", 130, 450

  die: () =>
    @_displayDeath()
    clearInterval(@gameTimer)
    @noRender = true
    setTimeout =>
      @noRender = false
      @gameTimer = setInterval @gameLoop, RENDER_TIME
    , 3000

  end: () =>
    clearInterval(@gameTimer)
    @noRender = true

    @context.globalAlpha = 0.5
    @context.fillStyle = "#666"
    @context.fillRect(0, 0, WIDTH, HEIGHT)
    @context.globalAlpha = 1.0
    @context.fillStyle = "#A00"
    @context.font = "bold 48px Arial"
    @context.fillText "You have won!", 130, 300
    @context.font = "32px Arial"
    @context.fillText "Score: " + @score + @renderCount * 10, 130, 400

    @highScoreName = prompt("Enter name for high score chart:")

    @secondLevel() if @highScoreName.match(/.*(sneaky).*/i)

  lose: () =>
    clearInterval(@gameTimer)
    @noRender = true

    @context.globalAlpha = 0.5
    @context.fillStyle = "#666"
    @context.fillRect(0, 0, WIDTH, HEIGHT)
    @context.globalAlpha = 1.0
    @context.fillStyle = "#A00"
    @context.font = "bold 48px Arial"
    @context.fillText "You lose!", 130, 300
    @context.font = "32px Arial"
    @context.fillText "Reload the page to play again!", 130, 400


  secondLevel: () =>
    setTimeout =>
      @noRender = false
      @gameTimer = setInterval @gameLoop, RENDER_TIME
      @levelManager.advanceLevel()
      @player.hp = 20
      @player.lives = 5
      @renderCount = 0
    , 3000

    @context.clearRect(0, 0, WIDTH, HEIGHT)
    @context.fillStyle = "#000"
    @context.font = "bold 48px Arial"
    @context.fillText "Secret level unlocked", 100, 300
    @context.font = "32px Arial"
    @context.fillText "Starting in 3 seconds", 130, 400
    @keyboardHandler.right = false
    @keyboardHandler.left = false
    @keyboardHandler.down = false
    @keyboardHandler.up = false

  defeatSecretLevel: () =>
    window.location = "/victory"

# also serves as vector
class g.Point
  constructor: (x, y) ->
    [@x, @y] = arguments
    console.warn "Point coordinates invalid." if @x is undefined || @y is undefined

  normalize: =>
    scale = @magnitude()
    @x /= scale
    @y /= scale
    @

  scalarMultiply: (scalar) =>
    @x *= scalar
    @y *= scalar
    @

  magnitude: =>
    Math.sqrt(Math.pow(@x, 2) + Math.pow(@y, 2))

  difference: (vec2) =>
    new g.Point(@x - vec2.x, @y - vec2.y)

  sum: (vec2) =>
    new g.Point(@x + vec2.x, @y + vec2.y)

  dup: =>
    return new g.Point(@x, @y)

UP = new g.Point(0, -1)
DOWN = new g.Point(0, 1)
LEFT = new g.Point(-1, 0)
RIGHT = new g.Point(1, 0)

class g.Rect
  constructor: (x, y, width, height) ->
    @x = x
    @y = y
    @width = width
    @height = height
    console.warn "Rect coordinates invalid." if @x is undefined || @y is undefined || @width is undefined || @height is undefined

  containsPoint: (point) =>
    point.x >= @x && point.x <= @x + @width && point.y >= @y && point.y <= @y + @height ? true : false

class g.Board
  constructor: ->
    @bounds = new g.Rect(0, 0, WIDTH, HEIGHT)

class g.CanvasClearer
  render: (context) =>
    context.clearRect(0, 0, WIDTH, HEIGHT)

class g.BulletClearer
  update: ->
    game.playerBullets = []
    game.enemyBullets = []

class g.BackgroundLayer
  constructor: ->
    @offset = 0
    @ready = false
    @image = new Image()
    @image.onload = =>
      @ready = true
      @offset = -2 * @image.height + (game.canvas.height - @image.height)
    @image.src = "/images/stars.jpeg"

  update: =>
    if @ready
      if @offset <= 0
        @offset += SCROLL_SPEED
      else
        @offset -= @image.height

  render: (context) =>
    if @ready
      context.fillStyle = "#000"
      context.fillRect(0, 0, WIDTH, HEIGHT)
      context.drawImage(@image, 0, @offset)
      context.drawImage(@image, 0, @image.height + @offset)
      context.drawImage(@image, 0, @image.height * 2 + @offset)

class g.Player
  constructor: () ->
    @size = new g.Point(10, 10)
    @pos = new g.Point(WIDTH / 2, HEIGHT - @size.y)
    @speed = PLAYER_SPEED
    @firing = false
    @invulnTime = 0
    @hp = 10
    @lives = 4
    @bullets = new g.CircularBuffer()
    @weapon = new g.CompositeWeapon(weapons:
      [
        new g.ShotWeapon(color: "#00F", speed: 10, playerOwned: true, direction: UP ),
        new g.ShotWeapon(color: "#00F", speed: 10, playerOwned: true, direction: new g.Point(-.28, -.95) ),
        new g.ShotWeapon(color: "#00F", speed: 10, playerOwned: true, direction: new g.Point(.28, -.95) ),
      ])

  detectCollision: =>
    for bullet in game.enemyBullets
      if @pos.difference(bullet.pos.sum(new g.Point(0, 5))).magnitude() < bullet.size / 2 + @size.x / 3
        @hp-- unless @invulnTime > 0
        if @hp <= 0
          @die()
        else
        bullet.die()
        @makeInvulnerable(10)

  die: =>
    game.score -= 5000
    @hp = 6
    @lives--
    @invulntime = 40
    game.die() if @lives > 0
    if @lives == 0 then game.lose()

  makeInvulnerable: (time) =>
    @invulnTime = time unless @invulnTime > 0

  update: () ->
    if @pos.x <= 0 then @pos.x = 0
    if @pos.y <= 0 then @pos.y = 0
    if @pos.x >= WIDTH then @pos.x = WIDTH - 1
    if @pos.y >= HEIGHT then @pos.y = HEIGHT - 1

    @weapon.update(@)
    @invulnTime--

  render: (context) =>
    context.globalAlpha = 0.5 if @invulnTime > 0
    context.drawImage(IMAGES['player'], @pos.x - @size.x / 2, @pos.y - @size.y / 2)
    context.globalAlpha = 1.0

    @weapon.render(context)

class g.PlayerStatusTracker
  constructor: (player) ->
    @player = player

  update: =>
    @player.detectCollision()
    @player.hp += .001 unless @player.hp >= 10

class g.Bullet
  constructor: (options) ->
    @size = options?.size || 5
    @pos = options?.startPos
    @target = options?.target
    @speed = options?.speed
    @direction = options?.direction
    @lifetime = options?.lifetime
    @playerOwned = options?.playerOwned
    @color = options?.color
    @livedTicks = 0
    @pos = @pos.sum(options.offset) if options.offset

  die: =>
    @render = null
    @update = null

  update: =>
    @die() if @pos.x < 0 || @pos.y < 0 || @pos.x > game.canvas.width || @pos.y > game.canvas.height
    if @playerOwned
      game.playerBullets.push(@)
    else
      game.enemyBullets.push(@)

  render: (context) =>
    context.fillStyle = @color
    context.beginPath()
    context.arc(@pos.x, @pos.y + 10, @size, Math.PI * 2, 0, true) unless @playerOwned
    context.arc(@pos.x, @pos.y - 10, @size, Math.PI * 2, 0, true) if @playerOwned
    context.closePath()
    context.fill()

class g.StraightBullet extends g.Bullet
  constructor: (options) ->
    super(options)
    @color ?= "#F00"
    @speed ?= 5
    @velocity = @direction.dup()
    @velocity.scalarMultiply(@speed)

  update: =>
    super()
    @pos.y += @velocity.y
    @pos.x += @velocity.x

class g.HomingBullet extends g.Bullet
  constructor: (options) ->
    super(options)
    @color ?= "#0F0"
    @speed ?= 1

  update: =>
    super()
    vec = new g.Point(@target.pos.x - @pos.x, @target.pos.y - @pos.y)
    vec.normalize()
    vec.scalarMultiply(@speed)
    if @livedTicks >= @lifetime
      @render = null
      @update = null
    else
      @livedTicks++

    @pos.x += vec.x
    @pos.y += vec.y

class g.KeyboardHandler
  constructor: (game) ->
    @game = game
    @up = false
    @down = false
    @left = false
    @right = false

    $(window).on
      "keydown": (ev) =>
        @left = true if ev.keyCode == 37
        @up = true if ev.keyCode == 38
        @right = true if ev.keyCode == 39
        @down = true if ev.keyCode == 40
        @game.player.firing = true if ev.keyCode == 32
      "keyup": (ev) =>
        @left = false if ev.keyCode == 37
        @up = false if ev.keyCode == 38
        @right = false if ev.keyCode == 39
        @down = false if ev.keyCode == 40
        @game.player.firing = false if ev.keyCode == 32

  update: =>
    @game.player.pos.x += @game.player.speed if @right
    @game.player.pos.y += @game.player.speed if @down
    @game.player.pos.x -= @game.player.speed if @left
    @game.player.pos.y -= @game.player.speed if @up



class g.DebugLayer
  constructor: ->

  render: (context) ->
    context.strokeRect(0, 0, WIDTH, HEIGHT)


class g.CircularBuffer
  constructor: (length) ->
    @length = length || 100
    @storage = []
    @cursor = 0

  push: (item) =>
    if @storage.length < @length
      @storage.push(item)
    else
      @cursor = 0 if @cursor == @length
      @storage[@cursor].kill() if @storage[@cursor].kill
      @storage[@cursor] = item
      @cursor++

class g.LevelManager
  constructor: ->
    @currentLevel = null
    @levelQueue = []

  update: =>
    @currentLevel = @levelQueue.shift() unless @currentLevel
    @currentLevel.update() if @currentLevel

  render: (context) =>
    @currentLevel.render(context) if @currentLevel

  advanceLevel: =>
    @currentLevel = @levelQueue.shift()

class g.Level
  constructor: (startTick) ->
    @activeEvents = []
    @eventQueue = []
    @startTick = startTick
    @ended = false

  update: =>
    if @eventQueue[0] && @eventQueue[0].startTick + @startTick <= game.renderCount
      @activeEvents.push(@eventQueue.shift().start(game.renderCount))

    @end() if @activeEvents[@activeEvents.length - 1]?.ended && @eventQueue.length == 0

    if @activeEvents[0]
      @activeEvents.shift() if (game.renderCount - @activeEvents[0].startTime) >= 6000

    for event in @activeEvents
      event.update() if event.update

  render: (context) =>
    for event in @activeEvents
      event.render(context) if event.render

  end: =>
    @ended = true
    @currentEvent?.end()

class g.Event
  constructor: (startTick, level) ->
    @startTick = startTick
    @level = level
    @enemyQueue = []
    @activeEnemyQueue = []
    @ended = false
    @startTime = -1

  shiftEnemies: =>
    enemy = null
    while(enemy = @enemyQueue[0])
      break unless enemy.startTick + @level.startTick + @startTick <= game.renderCount
      @activeEnemyQueue.push(@enemyQueue.shift())

  start: (time) =>
    @startTime = time
    @

  update: =>
    @shiftEnemies() if @enemyQueue.length > 0
    for enemy in @activeEnemyQueue
      enemy.update()

  render: (context) =>
    for enemy in @activeEnemyQueue
      enemy.render(context)

  end: =>
    @ended = true
    enemy.die() for enemy in @activeEnemyQueue

class g.Enemy
  constructor: (options) ->
    @scoreValue = 500
    @startTick = options?.startTick
    @weapon = options?.weapon
    @behavior = options?.behavior
    @pos = options?.pos
    @event = options?.event
    @firing = true
    @size = new g.Point(25, 25)
    @image = options?.image
    @flashing = 0

  flash: =>
    @flashing = 40

  update: =>
    @behavior.update(@) if @behavior
    @weapon.update(@) if @weapon

  renderSelf: (context) =>
    context.drawImage(@image, @pos.x - @size.x / 2, @pos.y - @size.y / 2)

  render: (context) =>
    @renderSelf(context) if @renderSelf
    @weapon.render(context) if @weapon

  die: =>
    @renderSelf = null
    @behavior = null
    @weapon.cleanup()
    @firing = false
    game.score += @scoreValue

class g.CompositeBehavior
  constructor: (behaviors) ->
    @behaviors = behaviors

  update: (actor) ->
    for behavior in @behaviors
      behavior.update(actor) if behavior.update

class g.Behavior
  constructor: (options) ->
    @speed = options?.speed || 3
    @direction = options?.direction
    @velocity = @direction.dup()
    @velocity.scalarMultiply(@speed)
    @acceleration = options?.acceleration

  update: (actor) =>
    actor.pos.x += @velocity.x
    actor.pos.y += @velocity.y

class g.ParabolicMoveBehavior extends g.Behavior
  update: (actor) =>
    super(actor)
    @velocity.x += @acceleration.x
    @velocity.y += @acceleration.y

class g.DriftingBehavior extends g.Behavior
  constructor: (options) ->
    super(direction: DOWN, speed: SCROLL_SPEED * 2)

class g.StandardCompositeBehavior extends g.CompositeBehavior
  constructor: (options) ->
    super(options)
    newBehaviors = [new g.Attackable(7), new g.DriftingBehavior(), new g.DeathOnBottomEdgeBehavior()]
    @behaviors = @behaviors.concat(newBehaviors)

class g.Attackable
  constructor: (hitPoints) ->
    @hp = hitPoints

  update: (actor) =>
    for bullet in game.playerBullets
      if actor.pos.difference(bullet.pos).magnitude() < bullet.size + actor.size.x / 2
        @hit(actor)
        bullet.die()

  hit: (actor) =>
    @hp--
    if @hp == 0
      actor.die()
    else
      actor.flash() if actor.flash

class g.BossAttackable
  constructor: (totalHitpoints, thresholdBehaviorQueue) ->
    @hp = totalHitpoints
    @thresholdBehaviorQueue = thresholdBehaviorQueue
    window.a = @
    @scoreValue = 100000

  update: (actor) =>
    if @thresholdBehaviorQueue[0]?.threshold >= @hp
      actor.pos = @thresholdBehaviorQueue[0].position if @thresholdBehaviorQueue[0].position
      actor.behavior = new g.CompositeBehavior([@thresholdBehaviorQueue.shift().behavior, @])

    for bullet in game.playerBullets
      if actor.pos.difference(bullet.pos).magnitude() < bullet.size + actor.size.x / 2
        bullet.die()
        @hit(actor)

  hit: (actor) =>
    @hp--
    if @hp == 0
      actor.die()
    else
      actor.flash() if actor.flash

class g.DeathOnBottomEdgeBehavior
  update: (actor) =>

class g.CompositeWeapon
  constructor: (options) ->
    @weapons = options.weapons

  update: (actor) =>
    weapon.update(actor) for weapon in @weapons

  render: (context) =>
    weapon.render(context) for weapon in @weapons

  cleanup: =>
    weapon.cleanup() for weapon in @weapons

class g.Weapon
  constructor: (options) ->
    @playerOwned = options?.playerOwned || false
    @bullets = new g.CircularBuffer(100)
    @tickDelay = options?.delay || 5
    @numSkippedTicks = 0
    @speed = options?.speed
    @direction = options?.direction
    @target = options?.target
    @color = options?.color
    @offset = options?.offset

  update: (actor) =>
    if @numSkippedTicks == @tickDelay
      @_shoot(actor) if actor.firing
      @numSkippedTicks = 0
    else
      @numSkippedTicks++
    for bullet in @bullets.storage
      bullet.update() if bullet.update

  render: (context) =>
    for bullet in @bullets.storage
      bullet.render(context) if bullet.render

  cleanup: (context) =>
    # @bullets.storage = []

class g.ShotWeapon extends g.Weapon
  _shoot: (actor) =>
    @bullets.push(new g.StraightBullet(playerOwned: @playerOwned, startPos: actor.pos.dup(), direction: @direction, speed: @speed, color: @color, offset: @offset))

class g.TargetedShotWeapon extends g.Weapon
  _shoot: (actor) =>
    @bullets.push(new g.StraightBullet(playerOwned: @playerOwned, startPos: actor.pos.dup(), direction: @target.pos.difference(actor.pos).normalize(), speed: @speed, color: @color, offset: @offset))

class g.HomingShotWeapon extends g.Weapon
  constructor: (options) ->
    super(options)
    @speed ?= 3
  _shoot: (actor) =>
    @bullets.push(new g.HomingBullet(playerOwned: @playerOwned, startPos: actor.pos.dup(), target: game.player, lifetime: 200, delay: 10, speed: @speed, color: @color, offset: @offset))

class g.FastInBehavior
  constructor: (numTicks) ->
    @numTicks = numTicks

  update: (actor) =>
    @update = null if @numTicks == 0
    actor.pos.y -= 10
    @numTicks--

class g.LeftRightOscillate extends g.Behavior
  constructor: (options) ->
    super(options)
    @stage = 0 # 0 = moving, 1 = not moving
    @curDirection = options.initialDirection || 1
    @delayAfterMovement = options.delayAfterMovement || 70
    @movementTicks = options.movementTicks || 30
    @movementSpeed = options.movementSpeed || 10
    @numTicks = @movementTicks

  update: (actor) =>
    super(actor)
    if @numTicks <= 0 && @stage == 0
      @velocity.x -= @curDirection * @movementSpeed
      @curDirection *= -1
      @stage = 1
      @numTicks = @movementTicks
    else if @stage == 0
      @numTicks--

    if @numTicks > 0 && @stage == 1
      @numTicks--
    else if @stage == 1
      @velocity.x -= @curDirection * @movementSpeed
      @numTicks = @delayAfterMovement
      @stage = 0

class g.SquareMovement extends g.Behavior
  constructor: (options) ->
    super(options)
    @numTicks = 50
    @stage = 0 # 0 = top left, 1 = bottom left, 2 = bottom right, 3 = top right

  update: (actor) =>
    super(actor)

    switch @stage
      when 0 then @velocity.x = 0; @velocity.y = 10
      when 1 then @velocity.x = 10; @velocity.y = 0
      when 2 then @velocity.x = 0; @velocity.y = -10
      when 3 then @velocity.x = -10; @velocity.y = 0

    @numTicks--

    if @numTicks <= 0
      @stage += 1
      @stage %= 4
      if @stage % 2 == 0
        @numTicks = 50
      else
        @numTicks = 30

class g.IndexedWeaponChangeBehavior
  constructor: (weaponIndex) ->
    @weaponIndex = weaponIndex

  update: (actor) =>
    actor.weapon = actor.weapons[@weaponIndex]
    actor.firing = true
    @update = null

class g.DutyCycleWeapon
  constructor: (cycleOnTime, cycleOffTime) ->
    @cycleOnTime = cycleOnTime
    @cycleOffTime = cycleOffTime
    @timeInStage = 0
    @stage = 1 # 1 is on
    @weapon = null

  update: (actor) =>
    @timeInStage++

    if @stage == 1 && @timeInStage >= @cycleOnTime
      @timeInStage = 0
      actor.firing = false
      @stage = 0

    if @stage == 0 && @timeInStage >= @cycleOffTime
      @timeInStage = 0
      actor.firing = true
      @stage = 1

class g.NullWeapon
  constructor: () ->

  render: ->

  update: ->

  cleanup: ->

class g.Turret extends g.Enemy
  constructor: (options) ->
    super(options)
    @behavior = new g.StandardCompositeBehavior([])
    @weapon = new g.TargetedShotWeapon(target: options.target, delay: options.delay || 50)
    @image = IMAGES["25_enemy_5"]

  update: (actor) ->
    super(actor)

class g.DownwardShooter extends g.Enemy
  constructor: (options) ->
    super(options)
    @behavior = new g.StandardCompositeBehavior([new g.Behavior(direction: options.direction, speed: 5)])
    @weapon = new g.ShotWeapon(delay: 25, direction: DOWN, speed: 5)
    @image = IMAGES["25_enemy_5"]

class g.OscillatingBomber extends g.Enemy
  constructor: (options) ->
    super(options)
    @size = new g.Point(50, 25)
    @behavior = new g.CompositeBehavior([new g.DriftingBehavior(), new g.LeftRightOscillate(direction: new g.Point(0, 0), speed: 5), new g.Attackable(20), new g.DeathOnBottomEdgeBehavior()])
    @weapon = new g.ShotWeapon(delay: 3, direction: DOWN, speed: 5)
    @image = IMAGES["50_wide_enemy_1"]

class g.Boss extends g.Enemy
  constructor: (options) ->
    super(options)
    @size = new g.Point(100, 100)
    @behavior = new g.BossAttackable(450, [
      { threshold: 999, behavior: new g.CompositeBehavior(
        [
          new g.LeftRightOscillate(initialDirection: 1, direction: new g.Point(0, 0), speed: 5, delayAfterMovement: 210),
          new g.DutyCycleWeapon(150, 90)
        ])
      },
      { position: new g.Point(450, 150), threshold: 300, behavior: new g.CompositeBehavior(
        [
          new g.LeftRightOscillate(initialiDirection: -1, direction: new g.Point(0, 0), speed: 5)
          new g.IndexedWeaponChangeBehavior(1)
        ])
      },
      { position: new g.Point(150, 150), threshold: 150, behavior: new g.CompositeBehavior(
        [
          new g.SquareMovement(direction: new g.Point(0, 0), speed: 0),
          new g.IndexedWeaponChangeBehavior(2)
        ])
      },
      ])
    @weapons = []
    @weapons[0] = new g.CompositeWeapon(
      weapons: [
        new g.ShotWeapon(delay: 4, direction: DOWN, speed: 5, offset: new g.Point(10, 40)),
        new g.ShotWeapon(delay: 4, direction: DOWN, speed: 5, offset: new g.Point(-10, 40)),
        new g.ShotWeapon(delay: 4, direction: new g.Point(.1, .8), speed: 5, offset: new g.Point(25, 40)),
        new g.ShotWeapon(delay: 4, direction: new g.Point(-.1, .8), speed: 5, offset: new g.Point(-25, 40)),
        new g.ShotWeapon(delay: 4, direction: new g.Point(-.2, .7), speed: 5, offset: new g.Point(-35, 20)),
        new g.ShotWeapon(delay: 4, direction: new g.Point(.2, .7), speed: 5, offset: new g.Point(35, 20))

      ])

    @weapons[1] = new g.CompositeWeapon(
      weapons: [
        new g.ShotWeapon(delay: 4, direction: DOWN, speed: 5, offset: new g.Point(30, 40)),
        new g.ShotWeapon(delay: 4, direction: DOWN, speed: 5, offset: new g.Point(-30, 40)),
        new g.TargetedShotWeapon(target: options.target, delay: 25, speed: 10, color: "yellow"),
        new g.HomingShotWeapon(target: options.target, delay: 50, speed: 4, color: "green", lifetime: 100, offset: new g.Point(40, 0))
        new g.HomingShotWeapon(target: options.target, delay: 50, speed: 4, color: "green", lifetime: 100, offset: new g.Point(-40, 0))
      ])

    @weapons[2] = new g.CompositeWeapon(
      weapons: [
        new g.TargetedShotWeapon(target: options.target, delay: 15, speed: 4, color: "yellow", offset: new g.Point(50, 0)),
        new g.TargetedShotWeapon(target: options.target, delay: 15, speed: 4, color: "yellow", offset: new g.Point(-50, 0)),
        new g.TargetedShotWeapon(target: options.target, delay: 15, speed: 4, color: "yellow", offset: new g.Point(0, 50)),
        new g.TargetedShotWeapon(target: options.target, delay: 15, speed: 4, color: "yellow", offset: new g.Point(0, -50))
        new g.TargetedShotWeapon(target: options.target, delay: 15, speed: 4, color: "yellow", offset: new g.Point(0, 0)),
        new g.HomingShotWeapon(target: options.target, delay: 17, speed: 4, color: "green", lifetime: 100, offset: new g.Point(0, 0))
      ]
    )

    @weapon = @weapons[0]


    @image = IMAGES["boss"]

  die: =>
    game.end()

class g.ParabolicBullet extends g.Bullet
  constructor: (options) ->
    super(options)
    @speed ?= 1
    @velocity = @direction.dup()
    @velocity.scalarMultiply(@speed)
    @acceleration = options.acceleration || new g.Point(0, 0.05)

  update: =>
    super()
    @velocity.x += @acceleration.x
    @velocity.y += @acceleration.y

    if @livedTicks >= @lifetime
      @render = null
      @update = null
    else
      @livedTicks++

    @pos.x += @velocity.x
    @pos.y += @velocity.y

class g.ParabolicShooter extends g.Weapon
  constructor: (options) ->
    super(options)

  _shoot: (actor) =>
    @bullets.push(new g.ParabolicBullet(playerOwned: @playerOwned, startPos: actor.pos.dup(), target: game.player, lifetime: 200, delay: 10, speed: @speed, color: @color, offset: @offset, direction: @direction))

class g.ShowerMonster extends g.Enemy
  constructor: (options) ->
    super(options)
    @size = new g.Point(100, 50)
    @image = IMAGES["shower"]
    @behavior = new g.CompositeBehavior([new g.Attackable(100), new g.LeftRightOscillate(direction: new g.Point(0, 0), speed: 5, delayAfterMovement: 1, movementSpeed: 0.1, movementTicks: 600)])
    @weapon = new g.CompositeWeapon(weapons: [
      new g.ParabolicShooter(direction: DOWN, color: "#92c4f4"),
      new g.ParabolicShooter(delay: 15, direction: new g.Point(.17, .75), color: "#92c4f4", offset: new g.Point(8, 7)),
      new g.ParabolicShooter(delay: 9, direction: new g.Point(.25, .65), color: "#92c4f4", offset: new g.Point(15, 6)),
      new g.ParabolicShooter(delay: 15, direction: new g.Point(.32, .6), color: "#92c4f4", offset: new g.Point(18, 10)),
      new g.ParabolicShooter(delay: 9, direction: new g.Point(.5, .5), color: "#92c4f4", offset: new g.Point(27, 13)),
      new g.ParabolicShooter(delay: 15, direction: new g.Point(.6, .5), color: "#92c4f4", offset: new g.Point(27, 13)),
      new g.ParabolicShooter(delay: 7, direction: new g.Point(.7, .5), color: "#92c4f4", offset: new g.Point(27, 13)),
      new g.ParabolicShooter(delay: 7, direction: new g.Point(.8, .5), color: "#92c4f4", offset: new g.Point(30, 13)),

      new g.ParabolicShooter(delay: 9, direction: new g.Point(-.17, .75), color: "#92c4f4", offset: new g.Point(-8, 7)),
      new g.ParabolicShooter(delay: 15, direction: new g.Point(-.25, .65), color: "#92c4f4", offset: new g.Point(-15, 6)),
      new g.ParabolicShooter(delay: 17, direction: new g.Point(-.32, .6), color: "#92c4f4", offset: new g.Point(-18, 10)),
      new g.ParabolicShooter(delay: 7, direction: new g.Point(-.5, .5), color: "#92c4f4", offset: new g.Point(-27, 13)),
      new g.ParabolicShooter(delay: 15, direction: new g.Point(-.6, .5), color: "#92c4f4", offset: new g.Point(-27, 13)),
      new g.ParabolicShooter(delay: 9, direction: new g.Point(-.7, .5), color: "#92c4f4", offset: new g.Point(-27, 13)),
      new g.ParabolicShooter(delay: 9, direction: new g.Point(-.8, .5), color: "#92c4f4", offset: new g.Point(-30, 13)),
    ])

  die: () =>
    notify("Shower Head: The shower is inescapable!")
    @behavior = new g.Attackable(80)
    @die = =>
      notify("Shower Head: You have yet to even scratch me!")
      @behavior = new g.Attackable(80)
      @die = =>
        notify("Shower Head: I feel like I'm getting a little leaky..!")
        @behavior = new g.Attackable(80)
        @die = =>
          notify("Shower Head: What!? You weren't supposed to be able to defeat me!")
          game.defeatSecretLevel()


class g.TestLevelOne extends g.Level
  constructor: (startTick, game) ->
    super(startTick)
    firstEvent = new g.Event(0, @) # ~~ 0 seconds

    for i in [0..9]
      firstEvent.enemyQueue.push(new g.Turret(target: game.player, startTick: i * 50, pos: new g.Point(i * 50 + 50, -10), event: event))

    for i in [0..10]
      firstEvent.enemyQueue.push(new g.Turret(target: game.player, startTick: 200 + i * 100, pos: new g.Point(100, -10), event: event))
      firstEvent.enemyQueue.push(new g.Turret(target: game.player, startTick: 200 + i * 100, pos: new g.Point(500, -10), event: event))

    secondEvent = new g.Event(1000, @) # ~~ 25 seconds in

    leftParabolicEnemy = new g.Enemy(
      startTick: 0,
      pos: new g.Point(WIDTH / 2, 0),
      behavior: new g.StandardCompositeBehavior([new g.ParabolicMoveBehavior(speed: 3, direction: LEFT, acceleration: new g.Point(0, 0.08))]),
      weapon: new g.ShotWeapon(delay: 8, direction: DOWN),
      image: IMAGES["25_enemy_4"]
      event: event)
    rightParabolicEnemy = new g.Enemy(
      startTick: 0,
      pos: new g.Point(WIDTH / 2, 0),
      behavior: new g.StandardCompositeBehavior([new g.ParabolicMoveBehavior(speed: 3, direction: RIGHT, acceleration: new g.Point(0, 0.08))]),
      weapon: new g.ShotWeapon(delay: 8, direction: DOWN),
      image: IMAGES["25_enemy_4"],
      event: event)
    secondEvent.enemyQueue.push(leftParabolicEnemy)
    secondEvent.enemyQueue.push(rightParabolicEnemy)


    leftParabolicEnemy = new g.Enemy(
      startTick: 75,
      pos: new g.Point(WIDTH / 2, 0),
      behavior: new g.StandardCompositeBehavior([new g.ParabolicMoveBehavior(speed: 3, direction: LEFT, acceleration: new g.Point(0, 0.08))]),
      weapon: new g.ShotWeapon(delay: 8, direction: DOWN),
      image: IMAGES["25_enemy_4"]
      event: event)
    rightParabolicEnemy = new g.Enemy(
      startTick: 150,
      pos: new g.Point(WIDTH / 2, 0),
      behavior: new g.StandardCompositeBehavior([new g.ParabolicMoveBehavior(speed: 3, direction: RIGHT, acceleration: new g.Point(0, 0.08))]),
      weapon: new g.ShotWeapon(delay: 8, direction: DOWN),
      image: IMAGES["25_enemy_4"],
      event: event)

    secondEvent.enemyQueue.push(leftParabolicEnemy)
    secondEvent.enemyQueue.push(rightParabolicEnemy)


    leftParabolicEnemy = new g.Enemy(
      startTick: 225,
      pos: new g.Point(WIDTH / 2, 0),
      behavior: new g.StandardCompositeBehavior([new g.ParabolicMoveBehavior(speed: 3, direction: LEFT, acceleration: new g.Point(0, 0.08))]),
      weapon: new g.ShotWeapon(delay: 8, direction: DOWN),
      image: IMAGES["25_enemy_4"]
      event: event)
    rightParabolicEnemy = new g.Enemy(
      startTick: 300,
      pos: new g.Point(WIDTH / 2, 0),
      behavior: new g.StandardCompositeBehavior([new g.ParabolicMoveBehavior(speed: 3, direction: RIGHT, acceleration: new g.Point(0, 0.08))]),
      weapon: new g.ShotWeapon(delay: 8, direction: DOWN),
      image: IMAGES["25_enemy_4"],
      event: event)

    secondEvent.enemyQueue.push(leftParabolicEnemy)
    secondEvent.enemyQueue.push(rightParabolicEnemy)


    thirdEvent = new g.Event(1500, @)

    for i in [0..10]
      thirdEvent.enemyQueue.push(new g.Turret(target: game.player, startTick: 0, pos: new g.Point(100 + i * 50, -10), event: event, delay: 20))
      thirdEvent.enemyQueue.push(new g.Turret(target: game.player, startTick: 0, pos: new g.Point(150 + i * 50, -60), event: event, delay: 20))

    for i in [0..5]
      thirdEvent.enemyQueue.push(new g.OscillatingBomber(startTick: 500, pos: new g.Point(i * 100 + 200, 10), event: event))


#    for i in [0..10]
 #     event.enemyQueue.push(new g.Turret(target: game.player, startTick: i * 50, pos: new g.Point(i * 50 + 50, -10), event: event))

    # for i in [0..5]
    #   event.enemyQueue.push(new g.OscillatingBomber(startTick: 0, pos: new g.Point(i * 100 + 50, 10), event: event))


    bossEvent = new g.Event(3000, @) # ~~ 100 seconds in
    bossEvent.enemyQueue.push(new g.Boss(startTick: 0, pos: new  g.Point(450, 150), event: event, target: game.player))

    # diagonalHoming = new g.Enemy(200, new g.Point(0, 0), new g.StandardCompositeBehavior([new g.Behavior(speed: 4, direction: new g.Point(1, 1))]), new g.HomingShotWeapon(), event)
    # event.enemyQueue.push(diagonalHoming)
    # @eventQueue.push(event)

    # event = new g.Event(650, @)
    #for i in [0..10]
    #  event.enemyQueue.push(new g.Enemy(i * 50, new g.Point(WIDTH - i * 50, -10), new g.StandardCompositeBehavior([]), new g.ShotWeapon(delay: 25, direction: DOWN), event))
    #enemy2 = new g.Enemy(200, new g.Point(0, 0), new g.StandardCompositeBehavior([new g.Behavior(speed: 4, direction: new g.Point(1, 1))]), new g.HomingShotWeapon(), event)
    #event.enemyQueue.push(enemy2)

    @eventQueue.push(firstEvent)
    @eventQueue.push(secondEvent)
    @eventQueue.push(thirdEvent)
    @eventQueue.push(bossEvent)


class g.SecretLevel extends g.Level
  constructor: (startTick, game) ->
    super(startTick)
    bossEvent = new g.Event(0, @)
    boss = new g.ShowerMonster(startTick: 0, pos: new g.Point(300, 100))
    bossEvent.enemyQueue.push(boss)
    @eventQueue.push(bossEvent)
