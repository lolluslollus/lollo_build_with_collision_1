local _isExtendedLogActive = false
local _isWarningLogActive = true
local _isErrorLogActive = true
local _isTimersActive = true

return {
    print = function(...)
        if not(_isExtendedLogActive) then return end
        print(...)
    end,
    warn = function(label, ...)
        if not(_isWarningLogActive) then return end
        print('lollo_build_with_collision WARNING: ' .. label, ...)
    end,
    err = function(label, ...)
        if not(_isErrorLogActive) then return end
        print('lollo_build_with_collision ERROR: ' .. label, ...)
    end,
    debugPrint = function(whatever)
        if not(_isExtendedLogActive) then return end
        debugPrint(whatever)
    end,
    warningDebugPrint = function(whatever)
        if not(_isWarningLogActive) then return end
        debugPrint(whatever)
    end,
    errorDebugPrint = function(whatever)
        if not(_isErrorLogActive) then return end
        debugPrint(whatever)
    end,
    profile = function(label, func)
        if _isTimersActive then
            local results
            local _startSec = os.clock()
            print('######## ' .. tostring(label or '') .. ' starting at ' .. math.ceil(_startSec * 1000) .. ' mSec')
            results = {func()} -- func() may return several results, it's LUA
            local _elapsedSec = os.clock() - _startSec
            print('######## ' .. tostring(label or '') .. ' took ' .. math.ceil(_elapsedSec * 1000) .. ' mSec')
            return table.unpack(results) -- unpack the results as they are supposed to be
        else
            return func()
        end
    end,
    xpHandler = function(error)
        if not(_isExtendedLogActive) then return end
        print('lollo_build_with_collision INFO:') debugPrint(error)
    end,
    xpWarningHandler = function(error)
        if not(_isWarningLogActive) then return end
        print('lollo_build_with_collision WARNING:') debugPrint(error)
    end,
    xpErrorHandler = function(error)
        if not(_isErrorLogActive) then return end
        print('lollo_build_with_collision ERROR:') debugPrint(error)
    end,
}
