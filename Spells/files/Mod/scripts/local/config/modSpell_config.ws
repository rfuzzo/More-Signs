///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////


class CSpell_Config extends CEntity
{
	event OnSpawned(spawnData : SEntitySpawnData)
	{
		
		var ent : CSpell_PersistentConfig;
		var entityTemplate : CEntityTemplate;
    	var resourcePath : string;
    	var tagList : array< name >;
    	var entity : CEntity;

    	tagList.PushBack('spell_persistent_config');

    	entity = GetSpellConfig();
    	if ( !entity )
    	{
    		resourcePath = "dlc\rfitem\data\w2ent\spell_persistentconfig.w2ent";
			entityTemplate = (CEntityTemplate)LoadResource(resourcePath,true);
			ent = (CSpell_PersistentConfig)theGame.CreateEntity( entityTemplate, GetWorldPosition(), GetWorldRotation(), , , , PM_Persist, tagList );
			
    	}

	}
}





class CSpell_PersistentConfig extends CPeristentEntity
{
	

	//world Vars
	private 					var world 					: CWorld;
	
	//private	saved			var equippedSpell			: ESpellType;
	private	editable saved		var equippedSpellBySign		: array<ESpellType>;
	private						var currentlyCastSpell		: ESpellType; default currentlyCastSpell = SPT_None;
	
	//editables
	private editable saved		var spells					: array<SWitcherSpell>;

	//DEBUG
	private saved 				var persistanceTest			: string;


	public function SetPersistentString( s : string)
	{
		persistanceTest = s;
	}
	public function GetPersistentString() : string
	{
		return persistanceTest;
	}


	//DEBUG


	///////////////////////////////////////////////////////////////////////
	//////////////////////////// EVENTS ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////

	event OnSpawned(spawnData : SEntitySpawnData)
	{
		
		InitSpellConfig();

		InitListener();


	}
	
	

	///////////////////////////////////////////////////////////////////////
	//////////////////////////// FUNCTIONS ////////////////////////////////
	///////////////////////////////////////////////////////////////////////
	
	private function InitSpellConfig()
	{
		

		//DEBUG
		SetEquippedSpellBySign( ST_Axii, SPT_Superconductor );
		SetEquippedSpellBySign( ST_Igni, SPT_Sparks );
		//DEBUG
	}

	private function InitListener()
	{
		
	
	}






	// 
	///////////////////////////////////////////////////////////////////////


	public function GetSpellAttributeValue( spell : name, attr : name ) : float
	{
			
		return CalculateAttributeValue( GetSpellAttribute(spell, attr) );
	}

				
	public function GetSpellAttribute( spell : name, attr : name ) : SAbilityAttributeValue
	{
		var dm : CDefinitionsManagerAccessor;
		var min, max :SAbilityAttributeValue;
		var skillAttributeValue : SAbilityAttributeValue;

		theGame.GetDefinitionsManager().GetAbilityAttributeValue( spell, attr, min, max);
		
		return GetAttributeRandomizedValue(min, max);
	}








	// GETTERS and SETTERS
	///////////////////////////////////////////////////////////////////////

	/*public function SetEquippedSpell( spellType : ESpellType )
	{
		var signType : ESignType;
		signType = GetSignTypeForSpell( spellType );

		if(!(GetWitcherPlayer().IsSignBlocked(signType)))
		{
			equippedSpell = spellType;
			FactsSet("CurrentlySelectedSpell", equippedSpell);
		}
	}
	public function GetEquippedSpell() : ESpellType
	{
		return equippedSpell;
	}*/
	public function SetEquippedSpellBySign( signType : ESignType, spellType : ESpellType )
	{

		if(!(GetWitcherPlayer().IsSignBlocked(signType)) && (signType == GetSignTypeForSpell( spellType )) )
		{
			equippedSpellBySign[signType] = spellType;
			//FactsSet("CurrentlySelectedSpell", equippedSpell);
		}
	}
	public function GetEquippedSpellBySign( signType : ESignType ) : ESpellType
	{
		return equippedSpellBySign[signType];
	}
	




	public function GetCurrentlyCastSpell() : ESpellType
	{
		return currentlyCastSpell;
	}
	
	public function SetCurrentlyCastSpell( type : ESpellType, entity : CSpell )
	{
		currentlyCastSpell = type;
		
		if( type != SPT_None )
		{
			spells[currentlyCastSpell].entity = entity;
		}
	}
	
	public function GetCurrentSpellEntity() : CSpell
	{
		if(currentlyCastSpell == SPT_None)
			return NULL;
			
		return spells[currentlyCastSpell].entity;
	}
	
	public function GetSpellEntity(type : ESpellType) : CSpell
	{
		if(type == SPT_None)
			return NULL;
			
		return spells[type].entity;
	}
	
	public function GetSpellTemplate(type : ESpellType) : CEntityTemplate
	{
		if(type == SPT_None)
			return NULL;
			
		return spells[type].template;
	}
	
	public function IsCurrentSpellChanneled() : bool
	{
		if( currentlyCastSpell != SPT_None && spells[currentlyCastSpell].entity)
			return spells[currentlyCastSpell].entity.OnCheckChanneling();
		
		return false;
	}
	
	public function IsCastingSpell() : bool
	{
		return currentlyCastSpell != SPT_None;
	}
	
	


	
	

	///////////////////////////////////////////////////////////////////////
	////////////////////////////// DEBUG //////////////////////////////////
	///////////////////////////////////////////////////////////////////////

	private function GetCurrentWorld()
	{	
		world = theGame.GetWorld();
	}

	
	public function GetDebugSpells() : array<CEntityTemplate>
	{
		var i : int;
		var ret : array<CEntityTemplate>;

		for (i = 0; i < spells.Size(); i+=1)
		{ 
			ret.PushBack(spells[i].template);
		}

		return ret;

	}
	public function ClearDebugSpells() 
	{
		spells.Clear();

	}
	

}



