local _constants = require('lollo_build_with_collision.constants')
local _logger = require('lollo_build_with_collision.logger')

local _texts = {
    buildAnyway = _('BuildAnyway'),
    buildAnywayWindowTitle = _('BuildAnywayWindowTitle'),
    operationOff = _('OperationOff'),
    operationOn = _('OperationOn'),
}

local privateData = {
    isShowingBuildAnyway = false,
}

local privateFuncs = {
    hideBuildAnyway = function()
        if privateData.isShowingBuildAnyway then -- only for performance
            privateData.isShowingBuildAnyway = false

            local window = api.gui.util.getById(_constants.guiIds.buildAnywayWindowId)
            if window ~= nil then
                window:setVisible(false, false)
            end
        end
    end,
    modifyOnOffButtonLayout2 = function(layout, isOn)
        local img = nil
        if isOn then
            -- img = api.gui.comp.ImageView.new('ui/design/components/checkbox_valid.tga')
            img = api.gui.comp.ImageView.new('ui/lollo_build_with_collision/checkbox_valid.tga')
            img:setTooltip(_texts.operationOn)
            layout:addItem(img, api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
            -- layout:addItem(api.gui.comp.TextView.new(_texts.operationOn), api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        else
            img = api.gui.comp.ImageView.new('ui/lollo_build_with_collision/checkbox_invalid.tga')
            img:setTooltip(_texts.operationOff)
            layout:addItem(img, api.gui.util.Alignment.HORIZONTAL, api.gui.util.Alignment.VERTICAL)
        end
    end,
}

local publicFuncs = {
    showBuildAnyway = function(text, offset, onClickFunc)
        privateData.isShowingBuildAnyway = true

        local content = api.gui.layout.BoxLayout.new('VERTICAL')
        local window = api.gui.util.getById(_constants.guiIds.buildAnywayWindowId)
        if window == nil then
            window = api.gui.comp.Window.new(_texts.buildAnywayWindowTitle, content)
            window:setId(_constants.guiIds.buildAnywayWindowId)
        else
            window:setContent(content)
            window:setVisible(true, false)
        end

        local buttonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        buttonLayout:addItem(api.gui.comp.TextView.new(text or _texts.buildAnyway))
        local button = api.gui.comp.Button.new(buttonLayout, true)
        button:onClick(
            function()
                window:setVisible(false, false)
                privateData.isShowingBuildAnyway = false
                if type(onClickFunc) then onClickFunc() end
            end
        )
        content:addItem(button)

        local position = api.gui.util.getMouseScreenPos()
        window:setPosition(position.x + ((offset and offset.x or 0) or 0), position.y + ((offset and offset.y or 0) or 0))

        -- make title bar invisible without that dumb pseudo css
        window:getLayout():getItem(0):setVisible(false, false)

        window:onClose(
            privateFuncs.hideBuildAnyway
        )
    end,
    hideBuildAnyway = privateFuncs.hideBuildAnyway,
    initNotausToggleButton = function(isFunctionOn, funcOfBool)
        if api.gui.util.getById(_constants.guiIds.operationOnOffButton) then return end

        local toggleButtonLayout = api.gui.layout.BoxLayout.new('HORIZONTAL')
        privateFuncs.modifyOnOffButtonLayout2(toggleButtonLayout, isFunctionOn)
        local toggleButton = api.gui.comp.ToggleButton.new(toggleButtonLayout)
        toggleButton:setSelected(isFunctionOn, false)
        toggleButton:onToggle(function(isOn) -- isOn is boolean
            _logger.print('isFunctionOn toggled; isOn = ', isOn)
            while toggleButtonLayout:getNumItems() > 0 do
                local item0 = toggleButtonLayout:getItem(0)
                toggleButtonLayout:removeItem(item0)
            end
            privateFuncs.modifyOnOffButtonLayout2(toggleButtonLayout, isOn)
            toggleButton:setSelected(isOn, false)
            funcOfBool(isOn)
        end)

        toggleButton:setId(_constants.guiIds.operationOnOffButton)
        api.gui.util.getById('gameInfo'):getLayout():addItem(toggleButton)
    end,
}

return publicFuncs
