-- скрапер TVS для загрузки плейлиста "Хочу.ТВ" http://hochu.tv (11/11/20)
-- Copyright © 2017-2021 Nexter | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- видеоскрипт: hochu.lua
-- ## Переименовать каналы ##
local filter = {
	{'Setanta Sports Plus', 'Setanta Sports+'},
	}
-- ##
	local my_src_name = 'Хочу.ТВ'
	module('hochu_pls', package.seeall)
	local function ProcessFilterTableLocal(t)
	if not type(t) == 'table' then return end
		for i = 1, #t do
			for _, ff in ipairs(filter) do
				if (type(ff) == 'table' and t[i].name == ff[1]) then
					t[i].name = ff[2]
				end
			end
		end
	 return t
	end
	function GetSettings()
		local scrap_settings = {name = my_src_name, sortname = '', scraper = '', m3u = 'out_' .. my_src_name .. '.m3u', logo = '..\\Channel\\logo\\Icons\\hochu.png', TypeSource = 1, TypeCoding = 1, DeleteM3U = 1, RefreshButton = 1, AutoBuild = 0, AutoBuildDay = {0, 0, 0, 0, 0, 0, 0}, LastStart = 0, TVS = {add = 1, FilterCH = 1, FilterGR = 1, GetGroup = 1, LogoTVG = 1}, STV = {add = 0, ExtFilter = 1, FilterCH = 1, FilterGR = 1, GetGroup = 1, HDGroup = 1, AutoSearch = 1, AutoNumber = 1, NumberM3U = 0, GetSettings = 0, NotDeleteCH = 0, TypeSkip = 1, TypeFind = 1, TypeMedia = 0}}
	 return scrap_settings
	end
	function GetVersion() return 2, 'UTF-8' end
	local function LoadFromSite()
		local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML,like Gecko) Chrome/75.0.2785.143 Safari/537.36', prx, false)
			if not session then return end
		m_simpleTV.Http.SetTimeout(session, 8000)
		local url = 'http://hochu.tv'
		local rc, answer = m_simpleTV.Http.Request(session, {url = url})
		m_simpleTV.Http.Close(session)
			if rc ~= 200 then return end
		local i, t = 1, {}
		local adr, title
			for w in answer:gmatch('<a target="_blank".-</a>') do
				adr = w:match('href="(.-)"')
				title = w:match('title="(.-)"')
					if not adr or not title then break end
				t[i] = {}
				t[i].name = title:gsub(' смотреть онлайн', '')
				t[i].address = url .. adr
				i = i + 1
			end
			if i == 1 then return end
	 return t
	end
	function GetList(UpdateID, m3u_file)
			if not UpdateID then return end
			if not m3u_file then return end
			if not TVSources_var.tmp.source[UpdateID] then return end
		local Source = TVSources_var.tmp.source[UpdateID]
		local t_pls = LoadFromSite()
			if not t_pls then
				m_simpleTV.OSD.ShowMessageT({text = Source.name .. ' -> ошибка загрузки плейлиста', color = ARGB(255, 255, 0, 0), showTime = 1000 * 5, id = 'channelName'})
			 return
			end
		t_pls = ProcessFilterTableLocal(t_pls)
		m_simpleTV.OSD.ShowMessageT({text = Source.name .. ' -> ' .. #t_pls, color = ARGB(255, 155, 255, 155), showTime = 1000 * 5, id = 'channelName'})
		local m3ustr = tvs_core.ProcessFilterTable(UpdateID, Source, t_pls)
		local handle = io.open(m3u_file, 'w+')
			if not handle then return nil end
		handle:write(m3ustr)
		handle:close()
	 return 'ok'
	end
-- debug_in_file(#t_pls .. '\n')