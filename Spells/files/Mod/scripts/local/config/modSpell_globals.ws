///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////

/*
enum ESignType
{
	ST_Aard,
	ST_Yrden,
	ST_Igni,
	ST_Quen,
	ST_Axii,
	ST_None
}

enum EPersistanceMode
{
	PM_DontPersist,
	PM_SaveStateOnly,
	PM_Persist
}

*/

struct SWitcherSpell
{
	editable	var template	: CEntityTemplate;
				var entity		: CSpell;
};

enum ESpellSkill
{
	S_SUndefined,

	S_modspell_y_01,		//Superconductor
	S_modspell_y_02			//Sparks
}


enum ESpellType
{
	SPT_Superconductor,
	SPT_Sparks,
	SPT_None
	
}


function SpellSkillEnumToName(s : ESpellSkill) : name
{
	switch(s)
	{
		case S_modspell_y_01 :			return 'modspell_y_01';
		case S_modspell_y_02 :			return 'modspell_y_02';
		
		
		default:						return '';
	}
}



function GetSignTypeForSpell( spellType : ESpellType ) : ESignType
{
	switch(spellType)
	{
		case SPT_Superconductor :		return ST_Axii; //ST_Yrden //FIXME
		case SPT_Sparks :				return ST_Igni;	//ST_Yrden //FIXME

		
		
		default:						return ST_None;
	}

}


///////////////////////////////////////////////////////////////////////////
//////////////////////////// GLOBAL FUNCTIONS /////////////////////////////
///////////////////////////////////////////////////////////////////////////

function GetSpellConfig() : CSpell_PersistentConfig
{

	var entity : CEntity;
	var cfg : CSpell_PersistentConfig;
	
	entity = theGame.GetEntityByTag('spell_persistent_config');
	cfg = (CSpell_PersistentConfig)entity;
	
	return cfg;

}


function GetSpell() : CSpell
{

	var entity : CEntity;
	var spell : CSpell;
	
	entity = theGame.GetEntityByTag('modspell');
	spell = (CSpell)entity;
	
	return spell;

}






function GetSpell_Sparks() : CSpell_Sparks
{

	var entity : CEntity;
	var spell : CSpell_Sparks;
	
	entity = theGame.GetEntityByTag('spell_sparks');
	spell = (CSpell_Sparks)entity;
	
	return spell;

}






function GetSpell_Superconductor() : CSpell_Superconductor
{

	var entity : CEntity;
	var spell : CSpell_Superconductor;
	
	entity = theGame.GetEntityByTag('spell_superconductor');
	spell = (CSpell_Superconductor)entity;
	
	return spell;

}



