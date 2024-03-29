///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////

exec function debugini()
{
	//DEBUG
	GetSpellConfig().SetEquippedSpellBySign( ST_Igni, SPT_Superconductor );
	GetSpellConfig().SetEquippedSpellBySign( ST_Axii, SPT_Sparks );
	//DEBUG
}

exec function equ( s : ESignType )
{
	theGame.GetGuiManager().ShowNotification( "spell: " + GetSpellConfig().GetEquippedSpellBySign( s ));
}
exec function setequ(s : ESignType, sp : ESpellType)
{
	GetSpellConfig().SetEquippedSpellBySign( s, sp );
	theGame.GetGuiManager().ShowNotification( "spell: " + GetSpellConfig().GetEquippedSpellBySign( s ));
}

/*exec function rfget()
{
	theGame.GetGuiManager().ShowNotification( "var: " + GetWitcherPlayer().Getrf());
}
exec function rfset(s : string)
{
	GetWitcherPlayer().Setrf(s);
	theGame.GetGuiManager().ShowNotification( "var: " + GetWitcherPlayer().Getrf());
}*/

exec function mscExists()
{
	var strg : bool;

	if ( GetSpellConfig() )
		strg = true;
	else
		strg = false;
	
	theGame.GetGuiManager().ShowNotification( GetSpellConfig() + " " + strg );

}
exec function mscDestroy()
{
	GetSpellConfig().Destroy();
	theGame.GetGuiManager().ShowNotification( "Destroyed" );

}

exec function mscSpawn()
{

	var ent : CSpell_PersistentConfig;
	var entityTemplate : CEntityTemplate;
	var resourcePath : string;
	var tagList : array< name >;
	var entity : CEntity;

	//tagList.PushBack('spell_persistent_config');

	entity = theGame.GetEntityByTag('spell_persistent_config');
	if ( !entity )
	{
		resourcePath = "dlc\rfitem\data\w2ent\spell_persistentconfig.w2ent";
		entityTemplate = (CEntityTemplate)LoadResource(resourcePath,true);
		ent = (CSpell_PersistentConfig)theGame.CreateEntity( entityTemplate, thePlayer.GetWorldPosition(), thePlayer.GetWorldRotation(), , , , PM_Persist, tagList );
		theGame.GetGuiManager().ShowNotification( entity + " Spawned new" );
	}
	else
	{
		theGame.GetGuiManager().ShowNotification( entity + " exists." );
	}

	
}

exec function mscSet(s : string)
{
	
	if ( GetSpellConfig() )
	{
		GetSpellConfig().SetPersistentString( s );
	}
		
	theGame.GetGuiManager().ShowNotification( GetSpellConfig() + "<br> Set: " + s );

}

exec function mscGet()
{
	var ret : string;
	if ( GetSpellConfig() )
	{
		ret = GetSpellConfig().GetPersistentString();
	}
		
	theGame.GetGuiManager().ShowNotification( GetSpellConfig() + "<br> Get: " + ret );

}


exec function msc()
{
	var it : array<CEntityTemplate>; 
	var i : int;
	var strg : string;

	strg = "IsAlive: " + GetSpellConfig();
	if ( GetSpellConfig() )
	{
		it = GetSpellConfig().GetDebugSpells();
		strg += "Size: (" + it.Size() + ") <br>";

		for (i = 0; i < it.Size(); i+=1)
		{
			strg += i + ": (" + it[i] + ") <br>";
		}

	}
		
	theGame.GetGuiManager().ShowNotification( strg );

}

exec function behSign()
{

	thePlayer.SetBehaviorVariable( 'IsCastingSign', 1 );
	theGame.GetGuiManager().ShowNotification( "IsCastingSign" );
}



function rf_log1(msgText : string, optional logToUI : bool)
{
	if (logToUI)
		((CR4ScriptedHud)theGame.GetHud()).HudConsoleMsg(msgText);
	LogChannel('MODSPELLS', msgText );
}


function rf_log2(msgText : string, optional logToUI : bool)
{
	if (logToUI)
		theGame.GetGuiManager().ShowNotification( msgText );
	LogChannel('MODSPELLS', msgText );
}



class CSpell_Superconductor_Loader extends CItemEntity
{
	private var entity : CEntity;
    private var entityTemplate : CEntityTemplate;
    private var resourcePath : string;
    private var instantiated : bool;
    private var loaderData : string;

    default loaderData = "notset";

    event OnSpawned(spawnData : SEntitySpawnData)
	{
		GetSpellConfig().SetPersistentString( "Item Spawned" );
	}

	
	public function GetLoaderData() : string
	{
		return loaderData;
	}
	public function SetLoaderData(s : string)
	{
		loaderData = s;
	}
}


function GetLoader() : CSpell_Superconductor_Loader
{

	var entity : CEntity;
	var spell : CSpell_Superconductor_Loader;
	
	entity = theGame.GetEntityByTag('spell_superconductor_loader');
	spell = (CSpell_Superconductor_Loader)entity;
	
	return spell;

}


exec function rfget1()
{
	var ent : CItemEntity;
	var itemID : SItemUniqueId; 		

	itemID = GetWitcherPlayer().GetInventory().GetItemId( 'modspells_config_loader2' );
	ent = (CSpell_Superconductor_Loader)GetWitcherPlayer().GetInventory().GetItemEntityUnsafe(itemID);

	theGame.GetGuiManager().ShowNotification( ent + "<br>var: " + ((CSpell_Superconductor_Loader)ent).GetLoaderData());
}
exec function rfset1(s : string)
{
	GetLoader().SetLoaderData(s);
	theGame.GetGuiManager().ShowNotification( GetLoader() + "<br>var: " + GetLoader().GetLoaderData());
}






