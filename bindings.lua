local module             = {}

local window             = require('ext.window')
local smartLaunchOrFocus = require('ext.application').smartLaunchOrFocus
local system             = require('ext.system')

-- simple unpack clone
function unpack(t, i)
  i = i or 1
  if t[i] ~= nil then
    return t[i], unpack(t, i + 1)
  end
end

-- apply function to a window with optional params, saving it's position for restore
local doWin = function(fn, options)
  return function()
    local win = hs.window.frontmostWindow()

    local allowFullscreen = options and options.allowFullscreen

    if win and (allowFullscreen or not win:isFullScreen()) then
      -- persist position only if we are not already undo/redo/saving
      if fn ~= window.persistPosition then
        window.persistPosition(win, 'save')
      end

      -- finally call function on window with arguments
      fn(win, options)
    end
  end
end

module.start = function()
  local combo = { 'ctrl', 'cmd' }
  local ultra = { 'shift', 'ctrl', 'alt', 'cmd' }
  local bind  = function(km, key, action) hs.hotkey.bind(km, key, action) end

  local modal = hs.hotkey.modal.new(combo, 'space')
  function modal:entered() hs.alert.show( "Window manager active", 999999 ) end
  function modal:exited() hs.alert.closeAll() end

  function modal_exit (fn)
    return function ()
      modal:exit()
      return fn()
    end
  end

  hs.hotkey.bind({ 'alt' }, 'tab', window.windowHints)

  hs.grid.HINTS = {
    {'1', '2', '3', '4'},
    {'q', 'w', 'e', 'r'},
    {'u', 'i', 'o', 'p'},
    {'h', 'j', 'k', 'l'},
    {'n', 'm', ',', '/'}}

  hs.grid.setGrid('4x3').setMargins({ x = 0, y = 0 })

  local expose = hs.expose.new(nil)


  hs.fnutils.each({
      { key = 'escape' },
      { key = 'return' },
      { key = 'space', fn = function () expose:toggleShow() end },


  },function (object)
      modal:bind('', object.key, modal_exit(doWin(object.fn, object.args)))
  end)

  hs.fnutils.each({
      { key = 'g', fn = hs.grid.show },

      { key = 'h', fn = hs.window.focusWindowWest },
      { key = 'j', fn = hs.window.focusWindowSouth },
      { key = 'k', fn = hs.window.focusWindowNorth },
      { key = 'l', fn = hs.window.focusWindowEast },
   },function (object)
     bind(combo, object.key, doWin(object.fn, object.args))
  end)

  hs.fnutils.each({
    { key = 'f', fn = window.fullscreen, args = { allowFullscreen = true } },
    { key = 'g', fn = hs.grid.show                                         },
    { key = 'z', fn = hs.grid.maximizeWindow                               },
    { key = 'n', fn = hs.grid.pushWindowNextScreen                         },
    { key = 'p', fn = hs.grid.pushWindowPrevScreen                         },
    { key = 'h', fn = hs.grid.pushWindowLeft                               },
    { key = 'l', fn = hs.grid.pushWindowRight                              },
    { key = 'k', fn = hs.grid.pushWindowUp                                 },
    { key = 'j', fn = hs.grid.pushWindowDown                               },
    { key = '[', fn = hs.grid.resizeWindowThinner                          },
    { key = ']', fn = hs.grid.resizeWindowWider                            },
    { key = '=', fn = hs.grid.resizeWindowTaller                           },
    { key = '-', fn = hs.grid.resizeWindowShorter                          },
    { key = 'u', fn = window.persistPosition, args ='undo'                 },
    { key = 'r', fn = window.persistPosition, args ='redo'                 }
  }, function(object)
    bind(ultra, object.key, doWin(object.fn, object.args))
  end)

  hs.fnutils.each({
    { key = '/',      fn = system.toggleConsole      },
    { key = 'escape', fn = hs.caffeinate.systemSleep },
    { key = 'tab',    fn = window.windowHints        }
  }, function(object)
    bind(ultra, object.key, object.fn)
  end)

  hs.fnutils.each({
    { key = 't', apps = { 'iTerm2', 'Terminal'                     } },
    { key = 'b', apps = { 'Safari', 'Google Chrome'                } },
    { key = 'm', apps = { 'Messages', 'FaceTime', 'Slack', 'Skype' } }
  }, function(object)
    bind(ultra, object.key, function() smartLaunchOrFocus(object.apps) end)
  end)

  hs.fnutils.each({
    { key = '1', geom = { x = 0, y = 0, w = 8, h = 6 } },
    { key = '2', geom = { x = 1, y = 0, w = 6, h = 6 } },
    { key = '3', geom = { x = 2, y = 1, w = 4, h = 4 } },
    { key = '4', geom = { x = 3, y = 1, w = 2, h = 3 } },
    { key = '5', geom = { x = 3, y = 2, w = 2, h = 2 } },

    { key = '6', geom = { x = 0, y = 0, w = 4, h = 6 } },
    { key = '7', geom = { x = 4, y = 0, w = 4, h = 6 } },

    { key = '8', geom = { x = 0, y = 1, w = 4, h = 4 } },
    { key = '9', geom = { x = 4, y = 1, w = 4, h = 4 } }
  }, function(object)
    bind(ultra, object.key, doWin(hs.grid.set, object.geom))
  end)

end

-- TODO: stop all bindings?
module.stop = function()
end

return module
