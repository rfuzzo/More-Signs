///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////






statemachine class CSpell extends CGameplayEntity
//statemachine class CSpell extends W3SignEntity
{
	protected 		var owner 				: W3SignOwner;

	

    public 			var charge_start_anim 	: name;
    public 			var charge_loop_anim 	: name;
    public 			var charge_end_anim 	: name;

    public 			var channel_start_anim 	: name;
    public 			var channel_loop_anim 	: name;
    public 			var channel_end_anim 	: name;

    public 			var cast_start_anim 	: name;

    protected 		var attachedTo 			: CEntity;
	protected 		var boneIndex 			: int;
	editable  		var friendlyCastEffect	: name;
	private 		var isAttached 			: bool;

	//public 		var sign 				: ESpellSign;
	public 			var signType 			: ESignType;
	public 			var signEnt 			: W3SignEntity;

	protected		var cachedCost			: float;
	protected 		var skillEnum 			: ESpellSkill;
	protected 		var skillEnumSign		: ESkill;	//used for getting Sign Level od Spell Sign Class
	
	public    		var actionBuffs   		: array<SEffectInfo>;	

	protected 		var usedFocus			: bool;





	default signType = ST_None;
	default isAttached = false;



	

    ///////////////////////////////////////////////////////////////////////////
	//////////////////////////////// EVENTS ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////////


	//AUTO EVENTS
	///////////////////////////////////////////////////////////////////////////

	event OnSpawned(spawnData : SEntitySpawnData)
	{
		var signOwner : W3SignOwnerPlayer;

		//DEBUG
		rf_log1("parent OnSpawned");
		//DEBUG

		//initialise this class, this is only needed here, if it is not initialised externally (in WitcherPLayer)
		/*signOwner = new W3SignOwnerPlayer in this;
		signOwner.Init( GetWitcherPlayer() );
		Init( signOwner ); */
				

	}
		

	//CUSTOM EVENTS
	///////////////////////////////////////////////////////////////////////////


	event OnAnimEvent_Spell( animEventName : name, animEventType : EAnimationEventType, animInfo : SAnimationEventAnimInfo )
	{
		/*if( animEventType == AET_Tick )
		{
			ProcessSignEvent( animEventName );
		}*/

		//theGame.GetGuiManager().ShowNotification( "Spell: " + animEventName );
	}



	event OnProcessSpellEvent( eventName : name )
	{
		
		if( eventName == 'cast_begin' )
		{
			OnStarted();
		}
		else if( eventName == 'cast_throw' )
		{
			OnThrowing();
		}
		else if( eventName == 'cast_end' )
		{
			OnEnded();
		}
		else if( eventName == 'cast_friendly_begin' )
		{
			//Attach( true );
		}		
		else if( eventName == 'cast_friendly_throw' )
		{
			OnCastFriendly();
		}
		else
		{
			return false;
		}
		
		return true;
	}

	event OnStarted()
	{
		//DEBUG
		rf_log1("parent OnStarted");
		//DEBUG

		Attach();
	}

	event OnEnded(optional isEnd : bool)
	{
		var witcher : W3PlayerWitcher;
		var camHeading : float;
		
		//DEBUG
		rf_log1("parent OnEnded");



		witcher = (W3PlayerWitcher)owner.GetActor();
		if(witcher && witcher.IsCurrentSignChanneled() && witcher.bRAxisReleased )
		{
			if ( !witcher.lastAxisInputIsMovement )
			{
				camHeading = VecHeading( theCamera.GetCameraDirection() );
				if ( AngleDistance( GetHeading(), camHeading ) < 0 )
					witcher.SetCustomRotation( 'ChanneledSignCastEnd', camHeading + witcher.GetOTCameraOffset(), 0.0, 0.2, false );
				else
					witcher.SetCustomRotation( 'ChanneledSignCastEnd', camHeading - witcher.GetOTCameraOffset(), 0.0, 0.2, false );
			}
			witcher.ResetLastAxisInputIsMovement();
		}

		//CleanUp();

		
	}

	event OnCastFriendly()
	{
		//FIXME editor?
		PlayEffect( friendlyCastEffect );
		AddTimer('DestroyCastFriendlyTimer', 0.1, true, , , true);
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( thePlayer, 'CastSignAction', -1, 8.0f, -1.f, -1, true ); 
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( this, 'CastSignActionFar', -1, 30.0f, -1.f, -1, true ); 
		//thePlayer.GetVisualDebug().AddSphere( 'dsljkfadsa', 0.5f, this.GetWorldPosition(), true, Color( 0, 255, 255 ), 10.f );
	}






	event OnThrowing()
	{
		


	}

	event OnCheckChanneling()
	{
		return false;
	}


	///////////////////////////////////////////////////////////////////////////
	//////////////////////////////// FUNCTIONS ////////////////////////////////
	///////////////////////////////////////////////////////////////////////////
	


	public function Init( inOwner : W3SignOwner, prevInstance : CSpell, optional skipCastingAnimation : bool, optional notPlayerCast : bool ) : bool
	{
		var player : CR4Player;
		var focus : SAbilityAttributeValue;
		var witcher: W3PlayerWitcher;

		//DEBUG
		rf_log1("=== INIT ===", false);
		//DEBUG

		owner = inOwner;

		//check for enough stamina, and sign events in player
		if ( InitCastSpell( this ) )
		{
			//Buff Caching, unused
			if(!notPlayerCast)
			{
				owner.SetCurrentlyCastSign( GetSignType(), NULL ); //set SpellClassSign		
				GetSpellConfig().SetCurrentlyCastSpell( GetSpellType() , this );
				CacheActionBuffsFromSkill();
			}

			//Hook Up Focus Casting
			player = (CR4Player)owner.GetPlayer();
			if(player && !notPlayerCast && player.CanUseSkill(S_Perk_11))
			{
				if(!(player.CanUseSkill(S_Perk_09) && player.GetStat(BCS_Focus) >= 1))
				{
					focus = player.GetAttributeValue('focus_gain');
					
					if ( player.CanUseSkill(S_Sword_s20) )
					{
						focus += player.GetSkillAttributeValue(S_Sword_s20, 'focus_gain', false, true) * player.GetSkillLevel(S_Sword_s20);
					}
					player.GainStat(BCS_Focus, 0.1f * (1 + CalculateAttributeValue(focus)) );	
				}
			}

			return true;
		}
		else
		{
			owner.GetActor().SoundEvent( "gui_ingame_low_stamina_warning" );
			CleanUp();
			Destroy();
			return false;
		}



		/*if ( ownerPlayer )
		{
			ownerPlayer.AddAnimEventCallback( 'ActionBlend', 			'OnAnimEvent_ActionBlend' );
			ownerPlayer.AddAnimEventCallback('cast_begin',				'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('cast_throw',				'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('cast_end',				'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('cast_friendly_begin',		'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('cast_friendly_throw',		'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('axii_ready',				'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('axii_alternate_ready',	'OnAnimEvent_Spell');
			ownerPlayer.AddAnimEventCallback('yrden_draw_ready',		'OnAnimEvent_Spell');
		}*/
		

		


		
	}

	private function InitCastSpell( spellEntity : CSpell ) : bool
	{
		var	player	: W3PlayerWitcher;

		player = owner.GetPlayer();

		//FIXME make skill custom!
		if ( player && player.HasStaminaToUseSkill( S_Magic_3 ) && player.OnRaiseSignEvent() )
		{
			player.OnProcessCastingOrientation( false );
		
			player.SetBehaviorVariable( 'alternateSignCast', 0 );
			player.SetBehaviorVariable( 'IsCastingSign', 1 );
						
			
			player.BreakPheromoneEffect();
			
			return true;			
		}	
		return false;
	}

	private function Attach( optional toSlot : bool, optional toWeaponSlot : bool )
	{	

		var pos		: Vector;
		var boneMatrix 	: Matrix;
		var boneIndex : int;
		
		if (signType == ST_None)
		{
			return;
		}
		if (isAttached)
		{
			return;
		}

		boneIndex = thePlayer.GetBoneIndex( 'l_weapon' );
		if ( boneIndex != -1 )
		{
			boneMatrix = thePlayer.GetBoneWorldMatrixByIndex( boneIndex );
			pos = MatrixGetTranslation( boneMatrix );
			
		}
		else
		{
			pos	= thePlayer.GetWorldPosition();	
		}


		signEnt = (W3SignEntity)theGame.CreateEntity(GetWitcherPlayer().GetSignTemplate( ST_Yrden ), pos, thePlayer.GetWorldRotation() );


		signEnt.CreateAttachment( thePlayer, 'l_weapon', /*thePlayer.GetHeadingVector()*/ );	
		//signEnt.CreateAttachment( thePlayer, 'l_weapon', 2*theCamera.GetCameraDirection() );	

		//signEnt.PlayEffect('rune');
		signEnt.PlayEffect('yrden_shock_rune');

		isAttached = true;

	}

	/*private function Detach()
	{
		BreakAttachment();
		attachedTo = NULL;
		boneIndex = -1;
	}*/

	

	protected function CleanUp()
	{
		//DEBUG
		rf_log1("parent Destroy");
		//DEBUG
		DestroyAfter( 1.f );
		
	}




	//STAMINA MANAGERS
	public function ManagePlayerStamina()
	{
		var l_player			: W3PlayerWitcher;
		var l_cost, l_stamina	: float;

		l_player = owner.GetPlayer();
		if( l_player.CanUseSkill( S_Perk_09 ) && l_player.GetStat(BCS_Focus) >= 1 )
		{
			l_player.DrainFocus( 1 ); 
		}
		else
		{
			l_player.DrainStamina( ESAT_Ability, 0, 0, SpellSkillEnumToName( skillEnum ) );
		}
	}


	/////////////////////////////////////////////////////////////////////////
	//DAMAGE MANAGERS
	public function InitSignDataForDamageAction( act : W3DamageAction)
	{
		act.SetSignSkill( GetSignSkill() ); //this skill is the base damage skill 
		FillActionDamageFromSkill( act );
		FillActionBuffsFromSkill( act );
	}	
	
	private function FillActionDamageFromSkill( act : W3DamageAction )
	{
		var attrs : array< name >;
		var i, size : int;
		var val : float;
		var dm : CDefinitionsManagerAccessor;
		var min, max :SAbilityAttributeValue;
		var skillAttributeValue : SAbilityAttributeValue;
		
		if ( !act )
		{
			rf_log2( "W3SignEntity.FillActionDamageFromSkill: action does not exist!", false );
			return;
		}
				
		dm = theGame.GetDefinitionsManager();
		dm.GetAbilityAttributes( SpellSkillEnumToName( skillEnum ), attrs );
		size = attrs.Size();

		for ( i = 0; i < size; i += 1 )
		{
			if ( IsDamageTypeNameValid( attrs[i] ) )
			{
				
				val = GetSpellConfig().GetSpellAttributeValue( SpellSkillEnumToName(skillEnum), attrs[i]);

				//FIXME scaling
				act.AddDamage( attrs[i], val );

				//DEBUG
				rf_log1( attrs[i] + ": " + val, false);
				//DEBUG

			}
		}
	}
	
	protected function FillActionBuffsFromSkill(act : W3DamageAction)
	{
		var i : int;
		
		for(i=0; i<actionBuffs.Size(); i+=1)
			act.AddEffectInfo(actionBuffs[i].effectType, , , actionBuffs[i].effectAbilityName);
	}

	protected function CacheActionBuffsFromSkill()
	{
		var attrs : array< name >;
		var i, size : int;
		var signAbilityName : name;
		var dm : CDefinitionsManagerAccessor;
		var buff : SEffectInfo;
		
		actionBuffs.Clear();
		dm = theGame.GetDefinitionsManager();
		signAbilityName = SpellSkillEnumToName( skillEnum );
		dm.GetContainedAbilities( signAbilityName, attrs );
		size = attrs.Size();
		
		for( i = 0; i < size; i += 1 )
		{
			if( IsEffectNameValid(attrs[i]) )
			{
				EffectNameToType(attrs[i], buff.effectType, buff.effectAbilityName);
				actionBuffs.PushBack(buff);
			}		
		}
	}


	/////////////////////////////////////////////////////////////////////////
	// SETTERS GETTERS
	public function GetSpellSkill() : ESpellSkill
	{
		return skillEnum;
	}
	public function SetSpellSkill(s : ESpellSkill)
	{
		skillEnum = s;
	}
	public function GetSignSkill() : ESkill
	{
		return skillEnumSign;
	}
	public function SetSignSkill(s : ESkill)
	{
		skillEnumSign = s;
	}
	
	public function GetSignType() : ESignType
	{
		return signType;
	}
	public function SetSignType(s : ESignType)
	{
		signType = s;
	}
	public function GetSpellType() : ESpellType
	{
		return SPT_None;
	}

	public function GetSignEntitySpell() : W3SignEntity
	{
		return signEnt;
	}
	public function GetUsedFocus() : bool
	{
		return usedFocus;
	}
	
	public function SetUsedFocus( b : bool )
	{
		usedFocus = b;
	}
	public function GetOwner() : W3SignOwner
	{
		return owner;
	}


	///////////////////////////////////////////////////////////////////////////
	/////////////////////////////////// TIMERS ////////////////////////////////
	///////////////////////////////////////////////////////////////////////////

	timer function TimedDestroy( delta : float , id : int)
	{
		
		DestroyAfter(3);
	}

	timer function DestroyCastFriendlyTimer(dt : float, id : int)
	{
		var active : bool;

		active = IsEffectActive( friendlyCastEffect );
			
		if(!active)
		{
			Destroy();
		}
	}

	timer function RemoveSpellSloMo( delta : float , id : int)
	{
		
		
		theGame.RemoveTimeScale( theGame.GetTimescaleSource(ETS_InstantKill) );
		GCameraShake(0.5f, true, this.GetWorldPosition(), 30.0f);
	}

	

}



///////////////////////////////////////////////////////////////////////////
//////////////////////////// GLOBAL FUNCTIONS /////////////////////////////
///////////////////////////////////////////////////////////////////////////














