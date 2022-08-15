local _constants = require('lollo_build_with_collision.constants')
local _guiHelpers = require('lollo_build_with_collision.guiHelpers')
local _logger = require('lollo_build_with_collision.logger')
local _stateHelpers = require ('lollo_build_with_collision.stateHelpers')
local _stringUtils = require('lollo_build_with_collision.stringUtils')

-- LOLLO NOTE you can only update the state from the worker thread
-- LOLLO NOTE if this script is inside a subdirectory, fine; otherwise, guiInit() might fire before all has been initialised
_stateHelpers.initState()

local _workerFuncs = {
	clickCancelButton = function()
		-- must be called inside pcall or xpcall
		local mainView = assert(api.gui.util.getById('mainView'), 'Build with collision WARNING: No mainView')
		-- buildControlComp comes with the game, it is the overlay with BUILD and CANCEL buttons and the tilt arrow
		local buildControlComp = mainView:getLayout():getItem(1):getLayout():getItem(0)
		if buildControlComp and buildControlComp:getName() == 'BuildControlComp' then
			for i = 0, buildControlComp:getLayout():getNumItems() -1 do
				local buildCancel = assert(buildControlComp:getLayout():getItem(i), 'Build with collision WARNING: No buildControlComp:getLayout():getItem(1)')
				for ii = 0, buildCancel:getNumItems() -1 do
					local item = buildCancel:getItem(ii)
					if item:getName() == 'BuildControlComp::CancelButton' then
						item:click()
						return
					end
				end
			end
		end
	end,
	isProposalEmpty = function(proposal)
		return
			proposal and proposal.proposal
			and proposal.proposal.addedSegments and #proposal.proposal.addedSegments == 0
			and proposal.proposal.removedSegments and #proposal.proposal.removedSegments == 0
			and proposal.toAdd and #proposal.toAdd == 0
			and proposal.toRemove and #proposal.toRemove == 0
	end,
	logBuildFailed = function(res)
		_logger.warn('Build failed')
		if res and res.resultProposalData and res.resultProposalData.errorState then
			_logger.warn('errorState.critical =') _logger.warningDebugPrint(res.resultProposalData.errorState.critical)
		end
		if res
		and res.resultProposalData
		and res.resultProposalData.collisionInfo
		and res.resultProposalData.collisionInfo.collisionEntities
		and #res.resultProposalData.collisionInfo.collisionEntities > 0
		then
			_logger.warn('collisionEntities =') _logger.warningDebugPrint(res.resultProposalData.collisionInfo.collisionEntities)
		end
	end,
}

local _guiFuncs = {
	sendScriptEvent = function(name, args)
		api.cmd.sendCommand(api.cmd.make.sendScriptEvent(
			string.sub(debug.getinfo(1, 'S').source, 1), _constants.eventId, name, args)
		)
	end,
}

function data()
	return {
		guiHandleEvent = function(id, name, param)
			local _state = _stateHelpers.getState()
        	if not(_state) or not(_state.is_on) then return end
			-- if name ~= 'visibilityChange'
			-- and name ~= 'select'
			-- and name ~= 'hover'
			-- then
			-- 	print('id =', id)
			-- 	print('name =', name)
			-- 	-- if id == 'bulldozer' then
			-- 	-- 	print('param =') debugPrint(param)
			-- 	-- end
			-- end
			if name == 'builder.proposalCreate'
			and (
				id == 'trackBuilder'
				or id == 'streetBuilder'
				or id == 'streetTrackModifier'
				or id =='streetTerminalBuilder' -- signals+bus stops , never collision
				or id == 'constructionBuilder'
				or id == 'bulldozer'
			)
			then
				xpcall(
					function()
						if
							param and param.data and param.data.errorState
							and not param.data.errorState.critical --check collision but not critical
							-- and #param.data.collisionInfo.collisionEntities>0  -- only for collision not other issues
							and #param.data.errorState.messages > 0
							and not _workerFuncs.isProposalEmpty(param.proposal)
						then
							local cmd = api.cmd.make.buildProposal(api.type.SimpleProposal.new(), nil, true) -- SimpleProposal, context, ignoreErrors
							cmd.proposal = param.proposal -- we override the SimpleProposal with the complex one coming from the game.
							if id == 'trackBuilder' or id == 'streetBuilder' then
								_guiHelpers.showBuildAnyway(
									_('BuildAnyway'),
									{ x = 30, y = -65 },
									function()
										api.cmd.sendCommand(
											cmd,
											function(res, success)
												_guiHelpers.hideBuildAnyway()
												if success then
													game.gui.playSoundEffect('construct')
													_workerFuncs.clickCancelButton()
												else
													_workerFuncs.logBuildFailed(res)
												end
											end
										)
									end
								)
							elseif id == 'constructionBuilder' then
								_guiHelpers.showBuildAnyway(
									_('BuildAnyway'),
									{ x = -100, y = 0 },
									function()
										api.cmd.sendCommand(
											cmd,
											function(res, success)
												_guiHelpers.hideBuildAnyway()
												if success then
													game.gui.playSoundEffect('construct')
												else
													_workerFuncs.logBuildFailed(res)
												end
											end
										)
									end
								)
							elseif id == 'streetTrackModifier' then
								_guiHelpers.showBuildAnyway(
									_('UpgradeAnyway'),
									{ x = -50, y = 0 },
									function()
										api.cmd.sendCommand(
											cmd,
											function(res, success)
												_guiHelpers.hideBuildAnyway()
												if success then
													game.gui.playSoundEffect('construct')
												else
													_workerFuncs.logBuildFailed(res)
												end
											end
										)
									end
								)
							elseif id == 'bulldozer' then
								_guiHelpers.showBuildAnyway(
									_('BulldozeAnyway'),
									-- { x = 30, y = -65 },
									{ x = 0, y = -0 },
									function()
										api.cmd.sendCommand(
											cmd,
											function(res, success)
												_guiHelpers.hideBuildAnyway()
												if success then
													game.gui.playSoundEffect('bulldozeMedium')
												else
													_workerFuncs.logBuildFailed(res)
												end
											end
										)
									end
								)
							end
						else
							_guiHelpers.hideBuildAnyway()
						end
					end,
					_logger.xpErrorHandler
				)
			elseif (_stringUtils.stringStartsWith(id, 'menu.')) then
				_guiHelpers.hideBuildAnyway()
			-- elseif (id == 'menu.construction.railmenu' and name == 'visibilityChange' and param==false)
			-- or (id == 'menu.construction.roadmenu' and name == 'visibilityChange' and param==false)
			-- or (id == 'menu.construction.rail.tabs' and name == 'tabWidget.currentChanged')
			-- or (id == 'menu.construction.road.tabs' and name == 'tabWidget.currentChanged')
			-- or (id == 'menu.construction.terrain.tabs' and name == 'tabWidget.currentChanged')
			-- or (id == 'menu.construction' and name == 'tabWidget.currentChanged')
			-- or (id == 'menu.bulldozer' and name == 'toggleButton.toggle')
			-- then
			-- 	_guiHelpers.hideBuildAnyway()
			end
		end,
		guiInit = function()
			local _state = _stateHelpers.getState()
			if not(_state) then
				_logger.err('cannot read state at guiInit')
				return
			end

			_guiHelpers.initNotausToggleButton(
				_state.is_on,
				function(isOn)
					_guiFuncs.sendScriptEvent(_constants.events.toggle_notaus, isOn)
				end
			)
		end,
		-- guiUpdate = guiUpdate,
		handleEvent = function(src, id, name, args)
			if id ~= _constants.eventId then return end

			xpcall(
				function()
					_logger.print('handleEvent firing, src =', src, ', id =', id, ', name =', name, ', args =') _logger.debugPrint(args)

					if name == _constants.events.toggle_notaus then
						_logger.print('state before =') _logger.debugPrint(_stateHelpers.getState())
						local state = _stateHelpers.getState()
						state.is_on = not(not(args))
						_logger.print('state after =') _logger.debugPrint(_stateHelpers.getState())
					end
				end,
				_logger.xpErrorHandler
			)
		end,
		-- init = init,
		load = function(loadedstate)
            -- fires once in the worker thread, at game load, and many times in the UI thread
            _stateHelpers.loadState(loadedstate)
        end,
		save = function()
            -- only fires when the worker thread changes the state
            return _stateHelpers.saveState()
        end,
		-- update = update,
	}
end
