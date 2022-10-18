#include "behavior.sp"

static ConVar npc_health_cvar;

static void npc_datamap_init(CustomDatamap datamap)
{
	
}

void fortified_distruptor_init()
{
	npc_health_cvar = CreateConVar("sk_fortified_distruptor_health", "1000");

	create_npc_factories("npc_fortified_distruptor", "FortifiedDistruptor", npc_datamap_init);

	CustomPopulationSpawnerEntry spawner = register_popspawner("FortifiedDistruptor");
	spawner.Parse = base_npc_pop_parse;
	spawner.Spawn = npc_pop_spawn;
	spawner.GetClass = npc_pop_class;
	spawner.HasAttribute = base_npc_pop_attrs;
	spawner.GetHealth = npc_pop_health;
	spawner.GetClassIcon = npc_pop_classicon;
}

static bool npc_pop_classicon(CustomPopulationSpawner spawner, int num, char[] str, int len)
{
	strcopy(str, len, "fortified_distruptor");
	return true;
}

static TFClassType npc_pop_class(CustomPopulationSpawner spawner, int num)
{
	return TFClass_Soldier;
}

static int npc_pop_health(CustomPopulationSpawner spawner, int num)
{
	return base_npc_pop_health(spawner, num, npc_health_cvar.IntValue);
}

static bool npc_pop_spawn(CustomPopulationSpawner spawner, float pos[3], ArrayList result)
{
	return npc_pop_spawn_single("npc_fortified_distruptor", spawner, pos, result);
}

void fortified_distruptor_precache(int entity)
{
	PrecacheModel("models/fortified/mob/distruptor/distruptor.mdl");

	//AddModelToDownloadsTable("models/fortified/mob/distruptor/distruptor.mdl");

	SetEntityModel(entity, "models/fortified/mob/distruptor/distruptor.mdl");
}

void fortified_distruptor_created(int entity)
{
	SDKHook(entity, SDKHook_SpawnPost, npc_spawn);
}

static Action npc_think(int entity)
{
	INextBot bot = INextBot(entity);
	ILocomotion locomotion = bot.LocomotionInterface;
	IBody body = bot.BodyInterface;

	npc_hull_debug(bot, body, locomotion, entity);

	npc_resolve_collisions(bot, entity);

	handle_playbackrate(entity, locomotion, body);

	return Plugin_Continue;
}

static Activity npc_translate_act(IBodyCustom body, Activity act)
{
	switch(act) {
		case ACT_JUMP: {
			return ACT_INVALID;
		}

		case ACT_IDLE_AGITATED: {
			return ACT_IDLE;
		}
		case ACT_IDLE_STIMULATED: {
			return ACT_IDLE;
		}
		case ACT_IDLE_RELAXED: {
			return ACT_IDLE;
		}

		case ACT_RUN_AGITATED: {
			return ACT_WALK;
		}
		case ACT_RUN_STIMULATED: {
			return ACT_WALK;
		}
		case ACT_RUN_RELAXED: {
			return ACT_WALK;
		}

		case ACT_WALK_AGITATED: {
			return ACT_WALK;
		}
		case ACT_WALK_STIMULATED: {
			return ACT_WALK;
		}
		case ACT_WALK_RELAXED: {
			return ACT_WALK;
		}
	}

	return act;
}

static Action npc_takedmg(int entity, CTakeDamageInfo info, int &result)
{
	float dir[3];
	TE_SetupBloodSprite2(info.m_vecDamagePosition, dir, BLOOD_COLOR_MECH, 5);
	TE_SendToAll();

	return Plugin_Continue;
}

static void npc_spawn(int entity)
{
	SetEntityModel(entity, "models/fortified/mob/distruptor/distruptor.mdl");
	SetEntityModelScale(entity, 1.0);
	SetEntProp(entity, Prop_Data, "m_bloodColor", DONT_BLEED);
	SetEntPropString(entity, Prop_Data, "m_iName", "Distruptor");

	float speed = 50.0;

	INextBot bot = INextBot(entity);
	ground_npc_spawn(bot, entity, npc_health_cvar.IntValue, speed, speed);
	HookEntityThink(entity, npc_think);

	bot.AllocateCustomIntention(fortified_distruptor_behavior, "FortifiedDistruptorBehavior");

	IBodyCustom body_custom = view_as<IBodyCustom>(bot.BodyInterface);
	body_custom.set_function("TranslateActivity", npc_translate_act);

	HookEntityOnTakeDamageAlive(entity, npc_takedmg, true);
}