-- xmonad.hs
-- xmonad example config file.

-- A template showing all available configuration hooks,
-- and how to override the defaults in your own xmonad.hs conf file.

-- Normally, you'd only override those defaults you care about.

-- SPECIAL
-- import XMonad.Layout.DecorationMadness
-- import XMonad.Actions.EasyMotion (selectWindow)

import Control.Applicative
import Control.Monad
import qualified Data.Map as M
import Data.Maybe
import Data.Monoid
import Graphics.X11.ExtraTypes.XF86
import System.Exit
import XMonad
import XMonad.Actions.DwmPromote
import XMonad.Actions.SwapPromote
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.RefocusLast
import XMonad.Hooks.RefocusLast as R
import XMonad.Layout.NoBorders
import XMonad.Layout.Reflect (reflectHoriz)
import XMonad.ManageHook
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig (additionalKeys)
import qualified XMonad.Util.Hacks as Hacks
import XMonad.Util.NamedScratchpad
import XMonad.Util.Stack

-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal = "alacritty"

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth = 3

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask = mod4Mask

rofi_launch = spawn "rofi -no-lazy-grab -show drun -modi run,drun,window -theme $HOME/.config/rofi/launcher/style -drun-icon-theme \'papirus\' "

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
--
myWorkspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor = "#000000"

myFocusedBorderColor = "#00ffff"

------------------------------------------------------------------------

scratchpads =
  [ -- (className =? "htop")/(title =? "htop")
    NS
      "htop"
      "alacritty -t htop -e htop"
      (title =? "htop")
      -- defaultFloating ,
      (customFloating $ W.RationalRect (2 / 7) (1 / 9) (2 / 5) (2 / 4)),
    NS
      "scratch"
      "alacritty -t scratch -e nvim ~/.scratch.md ~/.todo.md ~/.ideas.md"
      (title =? "scratch")
      (customFloating $ W.RationalRect (2 / 6) (1 / 9) (2 / 5) (2 / 4)),
    NS
      "nmtui"
      "alacritty -t nmtui -e nmtui"
      (title =? "nmtui")
      (customFloating $ W.RationalRect (2 / 6) (1 / 9) (2 / 5) (2 / 4)),
    NS
      "tags"
      "alacritty -t tags -e tags"
      (title =? "tags")
      (customFloating $ W.RationalRect (2 / 5) (3 / 9) (2 / 7) (1 / 5)),
    NS "notes" "gvim --role notes ~/notes.txt" (role =? "notes") nonFloating
  ]
  where
    role = stringProperty "WM_WINDOW_ROLE"

myFocusMaster = withWindowSet $ \ws ->
  let wins = drop 1 $ W.index ws -- first is master
   in withRecentsIn (W.currentTag ws) () $ \lw cw ->
        when (cw /= lw) . windows $ tryFocus (lw : wins)

tryFocus :: [Window] -> WindowSet -> WindowSet
tryFocus wins = W.modify' $ \s ->
  fromMaybe s . msum $ (\w -> findS (== w) s) <$> wins --

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
myKeys conf@(XConfig {XMonad.modMask = modm}) =
  M.fromList $
    [ ((0, xF86XK_AudioMute), spawn "amixer set Master toggle"),
      ((0, xF86XK_AudioLowerVolume), spawn "amixer set Master 3%-"),
      ((0, xF86XK_AudioRaiseVolume), spawn "amixer set Master 3%+"),
      ((0, xF86XK_MonBrightnessUp), spawn "brightnessctl set 3%+"),
      ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl set 3%-"),
      ((modm, xK_w), spawn "brave"),
      ((modm, xK_r), rofi_launch),
      ((modm, xK_BackSpace), kill),
      ((modm, xK_space), sendMessage NextLayout),
      ((modm .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf),
      ((modm, xK_n), refresh),
      ((modm, xK_Tab), windows W.focusDown),
      ((modm, xK_m), myFocusMaster),
      -- ((modm, xK_f), selectWindow def >>= (`whenJust` windows . W.focusWindow)),
      ((modm, xK_o), namedScratchpadAction scratchpads "scratch"),
      ((modm, xK_f), whenX (swapHybrid True) dwmpromote),
      ((modm .|. shiftMask, xK_j), windows W.swapDown),
      ((modm .|. shiftMask, xK_k), windows W.swapUp),
      ((modm .|. shiftMask, xK_q), io (exitWith ExitSuccess)),
      ((modm, xK_q), spawn "xmonad --recompile && xmonad --restart"),
      ((modm, xK_t), withFocused $ windows . W.sink),
      ((modm, xK_comma), sendMessage (IncMasterN 1)),
      ((modm, xK_s), spawn $ XMonad.terminal conf),
      ((modm, xK_period), sendMessage (IncMasterN (-1))),
      ((modm, xK_h), sendMessage Expand),
      ((modm, xK_j), windows W.focusDown),
      ((modm, xK_k), windows W.focusUp),
      ((modm, xK_l), sendMessage Shrink),
      ((modm .|. shiftMask, xK_o), namedScratchpadAction scratchpads "tags"),
      ((modm .|. controlMask, xK_o), namedScratchpadAction scratchpads "nmtui")
    ]
      ++
      --
      -- mod-[1..9], Switch to workspace N
      -- mod-shift-[1..9], Move client to workspace N
      --
      [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
      ]
      -- ++
      --
      -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
      -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
      --
      -- [ ((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
      --   | (key, sc) <- zip [xK_w, xK_e, xK_r] [0 ..],
      --     (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
      -- ]
      ++ [ ((0, xK_Print), spawn "scrotfull"),
           ((shiftMask, xK_Print), spawn "scrotsel"),
           ((controlMask, xK_Print), spawn "scrotactive"),
           ((0, xF86XK_PowerOff), spawn "slock"),
           ((0, xF86XK_PowerOff), spawn "systemctl suspend"),
           ((0, xF86XK_TouchpadToggle), spawn "toggle_touchpad")
         ]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) =
  M.fromList $
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ( (modm, button1),
        ( \w ->
            focus w >> mouseMoveWindow w
              >> windows W.shiftMaster
        )
      ),
      -- mod-button2, Raise the window to the top of the stack
      ((modm, button2), (\w -> focus w >> windows W.shiftMaster)),
      -- mod-button3, Set the window to floating mode and resize by dragging

      ( (modm, button3),
        ( \w ->
            focus w >> mouseResizeWindow w
              >> windows W.shiftMaster
        )
      )
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

------------------------------------------------------------------------
-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--

myLayout = tiled ||| noBorders Full
  where
    -- tiled   = Tall nmaster delta ratio
    tiled = reflectHoriz $ Tall nmaster delta ratio

    -- The default number of windows in the master pane
    nmaster = 1

    -- Default proportion of screen occupied by master pane
    ratio = 1 / 2

    -- Percent of screen to increment by when resizing panes
    delta = 3 / 100

------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook =
  composeAll
    [ className =? "MPlayer" --> doFloat,
      className =? "Gimp" --> doFloat,
      resource =? "desktop_window" --> doIgnore,
      resource =? "kdesktop" --> doIgnore
    ]
    <+> namedScratchpadManageHook scratchpads

------------------------------------------------------------------------
-- Event handling

-- * EwmhDesktops users should change this to ewmhDesktopsEventHook

--
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
myEventHook = refocusLastWhen refocusingIsActive <+> Hacks.windowedFullscreenFixEventHook

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
myLogHook = return ()

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
-- myStartupHook = do
--   spawn "$HOME/dotfiles/.config/polybar/launch.sh"
myStartupHook = return ()

------------------------------------------------------------------------
-- Command to launch the bar.
myBar = "xmobar"

-- Custom PP, configure it as you like. It determines what is being written to the bar.
myPP = xmobarPP {ppCurrent = xmobarColor "#00ffff" "" . wrap "<" ">"}

-- Key binding to toggle the gap for the bar.
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main = xmonad =<< statusBar myBar myPP toggleStrutsKey defaults

-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
defaults =
  def
    { -- simple stuff
      terminal = myTerminal,
      focusFollowsMouse = myFocusFollowsMouse,
      clickJustFocuses = myClickJustFocuses,
      borderWidth = myBorderWidth,
      modMask = myModMask,
      workspaces = myWorkspaces,
      normalBorderColor = myNormalBorderColor,
      focusedBorderColor = myFocusedBorderColor,
      -- key bindings
      keys = refocusLastKeys <+> myKeys,
      mouseBindings = myMouseBindings,
      -- hooks, layouts
      manageHook = myManageHook,
      startupHook = myStartupHook,
      handleEventHook = refocusLastWhen myPred <+> myEventHook,
      logHook = refocusLastLogHook <+> myLogHook,
      layoutHook = refocusLastLayoutHook $ myLayout
    }
  where
    myPred = refocusingIsActive <||> isFloat
    refocusLastKeys cnf =
      M.fromList $
        ((modMask cnf, xK_a), toggleFocus) :
        ((modMask cnf .|. shiftMask, xK_a), swapWithLast) :
        ((modMask cnf, xK_b), toggleRefocusing) :
          [ ( (modMask cnf .|. shiftMask, n),
              windows =<< shiftRLWhen myPred wksp
            )
            | (n, wksp) <- zip [xK_1 .. xK_9] (workspaces cnf)
          ]

------------------------ old stripped down content ----------------------

-- ( (modm, xK_u),
--   submap . M.fromList $
--     [ ((0, xK_w), spawn "brave"),
--       ((0, xK_r), rofi_launch),
--       ((0, xK_BackSpace), kill),
--       ((0, xK_space), sendMessage NextLayout),
--       ((0 .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf),
--       ((0, xK_n), refresh),
--       ((0, xK_Tab), windows W.focusDown),
--       ((0, xK_m), myFocusMaster),
--       ((0, xK_o), namedScratchpadAction scratchpads "scratch"),
--       ((0, xK_f), whenX (swapHybrid True) dwmpromote),
--       ((shiftMask, xK_j), windows W.swapDown),
--       ((shiftMask, xK_k), windows W.swapUp),
--       ((shiftMask, xK_q), io (exitWith ExitSuccess)),
--       ((0, xK_q), spawn "xmonad --recompile && xmonad --restart"),
--       ((0, xK_t), withFocused $ windows . W.sink),
--       ((0, xK_comma), sendMessage (IncMasterN 1)),
--       ((0, xK_s), spawn $ XMonad.terminal conf),
--       ((0, xK_period), sendMessage (IncMasterN (-1)))
--       -- , ((modm              , xK_b     ), sendMessage ToggleStruts)
--       -- , ((modm .|. shiftMask, xK_slash ), spawn ("echo \"" ++ help ++ "\" | xmessage -file -"))
--     ]
-- ),
