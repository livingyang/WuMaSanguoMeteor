
# _id, flag, range
skillCollection = new Meteor.Collection null

# _id, skillId, name, param1, param2
effectCollection = new Meteor.Collection null

setSkillConfig = (config) ->
	skillCollection.remove {}
	effectCollection.remove {}

	for targetEffects in (config.split "(") when targetEffects.length > 0
		[selector, effectArray] = targetEffects.split ")"

		flagAndRange = convertSelectorToFlagAndRange selector
		skillId = skillCollection.insert {flag: flagAndRange.flag, range: flagAndRange.range}
		
		for effect in effectArray.split ";" when effect.length > 0
			effectParam = effect.split ","
			effectCollection.insert
				skillId: skillId
				name: effectParam[0]
				param1: effectParam[1]
				param2: effectParam[2]


getSkillConfig = ->
	(for skill in skillCollection.find().fetch()		
		selector = "(#{skill.flag}#{skill.range})"

		effectParam = (for effect in effectCollection.find().fetch() when effect.skillId is skill._id
			[effect.name, effect.param1, effect.param2].join ","
		).join ";"

		"#{selector}#{effectParam}"
	).join ""

Meteor.startup ->
	setSkillConfig "(a)p,200,300;fa,2,50(Wi)fu,2,100"
	console.log getSkillConfig()

###
###

Template.skillConfig.skillArray = ->
	skillCollection.find()

Template.skillConfig.config = ->
	getSkillConfig()

Template.skillConfig.details = ->
	convertSkillConfigToDetail getSkillConfig()

Template.skill.flagName = ->
	ConfigField.getSkillFlag @flag

Template.skill.rangeName = ->
	ConfigField.getSkillRange @range

Template.skill.effectArray = ->
	effectCollection.find skillId: @_id

Template.skill.events "click .btnFlag": ->
	skillCollection.update {_id: @_id}, {$set: flag: if @flag is "E" then "W" else "E"}

Template.effect.nameDetail = ->
	ConfigField.getEffectName @name

Template.effect.detail = ->
	ConfigField.getEffectDetail @name

Template.effect.events "change .param1": (sender) ->
	effectCollection.update {_id: @_id}, {$set: param1: sender.target.value}

Template.effect.events "change .param2": (sender) ->
	effectCollection.update {_id: @_id}, {$set: param2: sender.target.value}

Template.hello.greeting = ->
	"Welcome to app."

Template.hello.events "click .test": ->
	config = "(Ea)p,200,300;fa,2,50(Wi)fu,2,100;(Wrwi)fu,4,100"
	try
		# alert convertSelectorToDetail "Wminh"
		alert (convertSkillConfigToDetail config).join "   |\n"
	catch e
		alert e

###
ConfigField
###

# ex: p,200,300
convertEffectToDetail = (effect) ->
	effectParams = effect.split ","
	
	try
		effectHandle = ConfigField.effect[effectParams[0]][3]
	catch e
		throw "parse error #{effect}"

	if effectHandle?
		effectHandle effectParams[1..]
	else
		effectParams.join " "

convertSelectorToFlagAndRange = (selector) ->
	if selector[0] is "E" or selector[0] is "W"
		flag: selector[0]
		range: selector.substr 1
	else
		flag: "E"
		range: selector

convertSelectorToDetail = (selector) ->
	flagAndRange = convertSelectorToFlagAndRange selector

	if not ConfigField.range[flagAndRange.range]?
		throw "无法确定选择对象: #{flagAndRange}"
	
	"对#{ConfigField.getSkillFlag flagAndRange.flag}#{ConfigField.getSkillRange flagAndRange.range}"
	

# ex: targetEffects = a)p,200,300;fa,2,50
convertTargetEffectsToDetail = (targetEffects) ->
	[selector, effectArray] = targetEffects.split ")"
	effectArray = (effect for effect in effectArray.split ";" when effect.length > 0)
	"#{convertSelectorToDetail selector} #{(convertEffectToDetail effect for effect in effectArray).join " "}"

# ex: config = "(a)p,200,300;fa,2,50(Wi)fu,2,100"
convertSkillConfigToDetail = (config) ->
	# throw "convert skill fail!!"
	for targetEffects in (config.split "(") when targetEffects.length > 0
		convertTargetEffectsToDetail targetEffects

# (Es)p,90,110 = (s)p,90,110 = 对敌方单体,造成90%~110%的物理伤害
# (a)p,200,300;fa,2,50(Wi)fu,2,100 = 对敌方全体,造成90%~110%的物理伤害,50%的几率眩晕2回合。对自己，100%的几率增加2点怒气。

ConfigField = 
	flag :
		W: ["We", "我方"]
		E: ["Enemy", "敌方"] # 默认为敌方

	range :
		s: ["single", "单体"]
		a: ["all", "全体"]
		f: ["front", "前排"]
		b: ["back", "后排"]
		v: ["vertical", "竖排"]
		i: ["I am", "自己"]
		rwi: ["random without i am", "除自己外的随机1人"]
		r1: ["random1", "随机1人"]
		r2: ["random2", "随机2人"]
		r3: ["random3", "随机3人"]
		r4: ["random4", "随机4人"]
		r5: ["random5", "随机5人"]
		r6: ["random6", "随机6人"]
		r7: ["random7", "随机7人"]
		minh: ["min hp", "血量最少的人"]
		maxh: ["max hp", "血量最多的人"]
		minf: ["max fury", "怒气最少的人"]
		maxf: ["max fury", "怒气最多的人"]

	effect :
		p: ["physical", "物理伤害", "参数1，最小伤害百分比，默认100%。参数2，最大伤害百分比，默认100%", (params) ->
			"造成#{params[0] or 100}% ~ #{params[1] or 100}%物理伤害"
		]
		m: ["magic", "法术伤害", "参数1，最小伤害百分比，默认100%。参数2，最大伤害百分比，默认100%"]
		r: ["recover", "回复", "参数1，最小回复百分比，默认100%。参数2，最大回复百分比，默认100%"]
		fu: ["fury up", "增加怒气", "参数1，增加怒气值，默认1。参数2，命中概率，默认100%。", (params) ->
			"#{params[1] or 100}%的概率增加#{params[0] or 1}怒气"
		]
		fd: ["fury down", "减少怒气", "参数1，减少怒气值，默认1。参数2，命中概率，默认100%"]
		fa: ["faint", "眩晕", "参数1，回合数，默认1。参数2，命中概率，默认100%", (params) ->
			"#{params[1] or 100}%的概率眩晕#{params[0] or 1}回合"
		]
		bu: ["burn", "燃烧", "参数1，回合数，默认1。参数2，命中概率，默认100%"]
		po: ["poizon", "中毒", "参数1，回合数，默认1。参数2，命中概率，默认100%"]
		fo: ["fobid", "封技", "参数1，回合数，默认1。参数2，命中概率，默认100%"]
		nd: ["no damage", "无伤", "参数1，回合数，默认1。参数2，命中概率，默认100%"]

	getSkillFlag: (flag) ->
		ConfigField.flag[flag][1]

	getSkillRange: (range) ->
		ConfigField.range[range][1]

	getEffectName: (effect) ->
		@effect[effect][1]

	getEffectDetail: (effect) ->
		@effect[effect][2]
