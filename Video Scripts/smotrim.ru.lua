-- видеоскрипт для сайта https://smotrim.ru (19/3/22)
-- Copyright © 2017-2022 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## Необходим ##
-- видеоскприпт: mediavitrina.lua
-- ## открывает подобные ссылки ##
-- https://smotrim.ru/video/2393207
-- https://smotrim.ru/article/2512070
-- https://smotrim.ru/live/channel/2961
-- https://smotrim.ru/live/vitrina/254
-- https://smotrim.ru/live/channel/248 -- радио
-- https://smotrim.ru/live/61647
-- https://smotrim.ru/podcast/45
-- https://smotrim.ru/live/52035
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://smotrim%.ru')
			and not m_simpleTV.Control.CurrentAddress:match('^smotrim_podcast=')
		then
		 return
		end
	local logo = 'https://cdnmg-st.smotrim.ru/smotrimru/smotrimru/i/logo-main-white.svg'
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = logo, TypeBackColor = 0, UseLogo = 1, Once = 1})
	end
	require 'json'
	if not m_simpleTV.User then
		m_simpleTV.User = {}
	end
	if not m_simpleTV.User.smotrim_ru then
		m_simpleTV.User.smotrim_ru = {}
	end
	local inAdr = m_simpleTV.Control.CurrentAddress
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:95.0) Gecko/20100101 Firefox/95.0', nil, true)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local function showErr(str)
		local t = {text = 'smotrim.ru ошибка: ' .. str, color = ARGB(255, 255, 102, 0), showTime = 1000 * 5, id = 'channelName'}
		m_simpleTV.OSD.ShowMessageT(t)
	end
	local function Thumbs(thumbsInfo)
			if m_simpleTV.Control.MainMode ~= 0 then return end
		m_simpleTV.User.smotrim_ru.ThumbsInfo = nil
		thumbsInfo = thumbsInfo:match('"tooltip":{.-}}')
			if not thumbsInfo then return end
		thumbsInfo = thumbsInfo:match('"high":{.-}') or thumbsInfo:match('"low":{.-}')
			if not thumbsInfo then return end
		local samplingFrequency = tonumber(thumbsInfo:match('"periodSlide":(%d+)') or 0)
		local column = tonumber(thumbsInfo:match('"column":(%d+)') or 0)
		local row = tonumber(thumbsInfo:match('"row":(%d+)') or 0)
		local thumbsPerImage = column * row
		local thumbWidth = tonumber(thumbsInfo:match('"width":(%d+)') or 0)
		local thumbHeight = tonumber(thumbsInfo:match('"height":(%d+)') or 0)
		local urlPattern = thumbsInfo:match('"url":"([^"]+)')
			if samplingFrequency == 0
				or thumbsPerImage == 0
				or thumbWidth == 0
				or thumbHeight == 0
				or not urlPattern
			then
			 return
			end
		m_simpleTV.User.smotrim_ru.ThumbsInfo = {}
		m_simpleTV.User.smotrim_ru.ThumbsInfo.samplingFrequency = samplingFrequency
		m_simpleTV.User.smotrim_ru.ThumbsInfo.thumbsPerImage = thumbsPerImage
		m_simpleTV.User.smotrim_ru.ThumbsInfo.thumbWidth = thumbWidth / column
		m_simpleTV.User.smotrim_ru.ThumbsInfo.thumbHeight = thumbHeight / row
		m_simpleTV.User.smotrim_ru.ThumbsInfo.urlPattern = urlPattern
		if not m_simpleTV.User.smotrim_ru.PositionThumbsHandler then
			local handlerInfo = {}
			handlerInfo.luaFunction = 'PositionThumbs_smotrim_ru'
			handlerInfo.regexString = '//smotrim\.ru/.'
			handlerInfo.sizeFactor = m_simpleTV.User.paramScriptForSkin_thumbsSizeFactor or 0.20
			handlerInfo.backColor = m_simpleTV.User.paramScriptForSkin_thumbsBackColor or ARGB(255, 0, 0, 0)
			handlerInfo.textColor = m_simpleTV.User.paramScriptForSkin_thumbsTextColor or ARGB(240, 127, 255, 0)
			handlerInfo.glowParams = m_simpleTV.User.paramScriptForSkin_thumbsGlowParams or 'glow="7" samples="5" extent="4" color="0xB0000000"'
			handlerInfo.marginBottom = m_simpleTV.User.paramScriptForSkin_thumbsMarginBottom or 0
			handlerInfo.showPreviewWhileSeek = true
			handlerInfo.clearImgCacheOnStop = false
			handlerInfo.minImageWidth = 80
			handlerInfo.minImageHeight = 45
			m_simpleTV.User.smotrim_ru.PositionThumbsHandler = m_simpleTV.PositionThumbs.AddHandler(handlerInfo)
		end
	end
	function PositionThumbs_smotrim_ru(queryType, address, forTime)
		if queryType == 'testAddress' then
		 return false
		end
		if queryType == 'getThumbs' then
				if not m_simpleTV.User.smotrim_ru.ThumbsInfo then
				 return true
				end
			local imgLen = m_simpleTV.User.smotrim_ru.ThumbsInfo.samplingFrequency * m_simpleTV.User.smotrim_ru.ThumbsInfo.thumbsPerImage * 1000
			local index = math.floor(forTime / imgLen)
			local t = {}
			t.playAddress = address
			t.url = m_simpleTV.User.smotrim_ru.ThumbsInfo.urlPattern:gsub('__num__', index)
			t.httpParams = {}
			t.httpParams.extHeader = 'Referer: ' .. address
			t.elementWidth = m_simpleTV.User.smotrim_ru.ThumbsInfo.thumbWidth
			t.elementHeight = m_simpleTV.User.smotrim_ru.ThumbsInfo.thumbHeight
			t.startTime = index * imgLen
			t.length = imgLen
			t.marginLeft = 2
			t.marginRight = 2
			t.marginTop = 0
			t.marginBottom = 0
			m_simpleTV.PositionThumbs.AppendThumb(t)
		 return true
		end
	end
	local function player_vgtrk(data)
		local retAdr = data:match('download_url%s*=%s*[\'"]([^\'"]+)')
		m_simpleTV.Control.CurrentAddress = retAdr
	end
	local function Podcast(data)
		local title = data:match('"og:title" content="([^"]+)') or 'Podcast'
		local pic = data:match('"og:image" content="([^"]+)') or logo
		m_simpleTV.Control.CurrentTitle_UTF8 = title
		local podcastId = inAdr:match('/podcast/(%d+)')
		local url = 'https://api.smotrim.ru/api/v1/audios/?includes=anons:datePub:duration:episodeTitle:rubrics:title&limit=1000&plan=free,free&sort=date&rubrics=' .. podcastId
		local rc, answer = m_simpleTV.Http.Request(session, {url = url})
			if rc ~= 200 then return end
		answer = unescape3(answer)
		answer = answer:gsub('%[%]', '""')
		local tab = json.decode(answer)
			if not tab or not tab.data then return end
		local t, i = {}, 1
			while tab.data[i] do
				local name = tab.data[i].episodeTitle
				t[i] = {}
				t[i].Id = i
				t[i].Name = name
				t[i].Address = 'smotrim_podcast=https://player.vgtrk.com/iframe/audio/id/' .. tab.data[i].id .. '/sid/smotrim/'
				t[i].InfoPanelLogo = pic
				t[i].InfoPanelDesc = tab.data[i].anons
				t[i].InfoPanelName = title
				t[i].InfoPanelTitle = name
				t[i].InfoPanelShowTime = 5000
				i = i + 1
			end
			if i == 1 then return end
		t.ExtParams = {}
		t.ExtParams.AutoNumberFormat = '%1 - %2'
		m_simpleTV.OSD.ShowSelect_UTF8(title, 0, t, 5000)
		local rc, answer = m_simpleTV.Http.Request(session, {url = t[1].Address:gsub('smotrim_podcast=', '')})
			if rc ~= 200 then return end
		player_vgtrk(answer)
	end
	function smotrim_ru_SaveQuality(obj, id)
		m_simpleTV.Config.SetValue('smotrim_ru_qlty', tostring(id))
	end
	local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr:gsub('smotrim_podcast=', '')})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr(1)
		 return
		end
		if inAdr:match('/podcast/') then
			Podcast(answer)
		 return
		end
		if inAdr:match('^smotrim_podcast=') then
			player_vgtrk(answer)
		 return
		end
	local embedUrl = answer:match('http[^\'\"<>]+player%.[^<>\'\"]+') or answer:match('http[^\'\"<>]+icecast%-[^<>\'\"]+')
		if not embedUrl or not inAdr:match('%d+') then
			showErr('Медиа контент не найден')
		 return
		end
		if not embedUrl:match('player%.vgtrk%.com') then
			local title = answer:match('"og:title" content="([^"]+)')
			if title then
				if m_simpleTV.Control.MainMode == 0 then
					title = title:gsub('&quot;', '"')
					m_simpleTV.Control.ChangeChannelName(title, m_simpleTV.Control.ChannelID, false)
					local poster = inAdr:match('/channel/(%d+)')
					if poster then
						poster = 'https://smotrim.ru/i/' .. poster .. '.svg'
					end
					poster = poster or 'https://smotrim.ru/i/smotrim_logo_soc.png'
					m_simpleTV.Control.ChangeChannelLogo(poster, m_simpleTV.Control.ChannelID)
				end
				m_simpleTV.Control.CurrentTitle_UTF8 = title
			end
				if embedUrl:match('mediavitrina') then
					m_simpleTV.Control.ChangeAddress = 'No'
					m_simpleTV.Control.CurrentAddress = embedUrl
					dofile(m_simpleTV.MainScriptDir .. 'user/video/video.lua')
				 return
				end
			m_simpleTV.Control.CurrentAddress = embedUrl
		 return
		end
	embedUrl = embedUrl:gsub('amp;', '')
	rc, answer = m_simpleTV.Http.Request(session, {url = embedUrl, headers = 'Referer: ' .. inAdr})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr(3)
		 return
		end
	answer = answer:gsub('%s+', '')
	local dataUrl = answer:match('dataUrl=\'([^\']+)')
	local dataUrlAudio = answer:match('window%.pl%.audio_url=[\'"]([^\'"]+)')
		if not dataUrl and not dataUrlAudio then
			showErr(4)
		 return
		end
		if dataUrlAudio then
			m_simpleTV.Control.CurrentAddress = dataUrlAudio
		 return
		end
	dataUrl = dataUrl:gsub('^//', 'https://')
	local isVod = answer:match('isVod=0')
	if isVod then
		dataUrl = dataUrl:gsub('datavideo', 'datalive')
	end
	rc, answer = m_simpleTV.Http.Request(session, {url = dataUrl, headers = 'Referer: ' .. embedUrl})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr(5)
		 return
		end
	local retAdr = answer:match('"auto":"([^"]+)')
		if not retAdr then
			local err = answer:match('%[{"errors":"([^"]+)')
			if err and err ~= '' then
				err = unescape3(err)
				err = err:gsub('\\r\\n', '')
			end
			showErr(err or 6)
		 return
		end
	answer = answer:gsub('\\"', '%%22')
	local addTitle = 'Смотрим'
	local title = answer:match('"title":"([^"]+)')
	if not title then
		title = addTitle
	else
		if m_simpleTV.Control.MainMode == 0 then
			title = unescape3(title)
			title = title:gsub('%%22', '"')
			m_simpleTV.Control.ChangeChannelName(title, m_simpleTV.Control.ChannelID, false)
			local poster = answer:match('"picture":"([^"]+)') or 'https://smotrim.ru/i/smotrim_logo_soc.png'
			m_simpleTV.Control.ChangeChannelLogo(poster, m_simpleTV.Control.ChannelID)
		end
		title = addTitle .. ' - ' .. title
	end
	m_simpleTV.Control.CurrentTitle_UTF8 = title
	local extOpt = '$OPT:no-spu'
	local duration = answer:match('"duration":(%d+)')
	Thumbs(answer)
	m_simpleTV.Http.SetRedirectAllow(session, false)
	rc, answer = m_simpleTV.Http.Request(session, {url = retAdr})
	if rc == 301 then
		local raw = m_simpleTV.Http.GetRawHeader(session)
			if not raw then return end
		local adr = raw:match('Location: (.-)\n')
			if not adr then return end
		local host0 = retAdr:match('https?://[^/]+')
		retAdr = host0 .. adr
		rc, answer = m_simpleTV.Http.Request(session, {url = retAdr})
			if rc ~= 200 then return end
	elseif rc ~= 200 then
		showErr(7)
	 return
	end
	m_simpleTV.Http.Close(session)
	local host = retAdr:match('.+%.smil/') or retAdr:match('.+/')
	local host2 = retAdr:match('https?://[^/]+')
	local t, i = {}, 1
		for w in answer:gmatch('EXT%-X%-STREAM%-INF(.-\n.-)\n') do
			local adr = w:match('\n(.+)')
			local name = w:match('BANDWIDTH=(%d+)')
			if adr and name then
				name = tonumber(name)
				t[i] = {}
				t[i].Id = name
				t[i].Name = math.ceil(name / 10000) * 10 .. ' кбит/с'
				if not adr:match('^http') then
					if adr:match('^/hls') then
						adr = host2 .. adr
					else
						adr = host .. adr
					end
				end
				t[i].Address = adr .. extOpt
				i = i + 1
			end
		end
		if #t == 0 then
			m_simpleTV.Control.CurrentAddress = retAdr .. extOpt
		 return
		end
	table.sort(t, function(a, b) return a.Id < b.Id end)
	local lastQuality = tonumber(m_simpleTV.Config.GetValue('smotrim_ru_qlty') or 100000000)
	local index = #t
	if #t > 1 then
		t[#t + 1] = {}
		t[#t].Id = 100000000
		t[#t].Name = '▫ всегда высокое'
		t[#t].Address = t[#t - 1].Address
		t[#t + 1] = {}
		t[#t].Id = 500000000
		t[#t].Name = '▫ адаптивное'
		t[#t].Address = retAdr .. extOpt
		index = #t
			for i = 1, #t do
				if t[i].Id >= lastQuality then
					index = i
				 break
				end
			end
		if index > 1 then
			if t[index].Id > lastQuality then
				index = index - 1
			end
		end
		if m_simpleTV.Control.MainMode == 0 then
			t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
			t.ExtParams = {LuaOnOkFunName = 'smotrim_ru_SaveQuality'}
			m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 32 + 64 + 128)
		end
	end
	retAdr = t[index].Address
	if duration and tonumber(duration) < 300 then
		retAdr = retAdr .. '$OPT:POSITIONTOCONTINUE=0'
	end
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(m_simpleTV.Control.CurrentAddress .. '\n')
