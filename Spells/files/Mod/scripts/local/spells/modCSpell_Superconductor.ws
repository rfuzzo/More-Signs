///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////

/*
Spell is
- charged
- cast (not channeled)
*/




statemachine class CSpell_Superconductor extends CSpell
{
	

	private 			var caster 							: W3SignOwner;
	editable 			var projDestroyFxEntTemplate		: CEntityTemplate;
	 					var fxcount 						: int;					default fxcount = 4;

    ///////////////////////////////////////////////////////////////////////////
	//////////////////////////////// EVENTS ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////////

	public function GetSpellType() : ESpellType
	{
		return SPT_Superconductor;
	}

	//AUTO EVENTS
	///////////////////////////////////////////////////////////////////////////

	
	event OnSpawned(spawnData : SEntitySpawnData)
	{
		//DEBUG
		rf_log2("child OnSpawned");
		//DEBUG

		super.OnSpawned(spawnData);

		InitSpecific();

	}

	




	//CUSTOM EVENTS
	///////////////////////////////////////////////////////////////////////////

	event OnStarted()
	{
		rf_log2("child OnStarted");

		super.OnStarted();


		//if ( theInput.GetActionValue( 'CastSignHold' ) > 0.f )
		if ( theInput.IsActionPressed('CastSignHold') ) 
		{
			
			owner.GetPlayer().SetBehaviorVariable( 'alternateSignCast', 1 );
			GotoState('SuperconductorCharge');

		}
		else
		{

			GotoState('SuperconductorCast');
		}

	}


	

	

	

	///////////////////////////////////////////////////////////////////////////
	//////////////////////////////// FUNCTIONS ////////////////////////////////
	///////////////////////////////////////////////////////////////////////////


	function InitSpecific()
	{
		caster = super.GetOwner(); // this doesn't work //fixme

		super.SetSignType( GetSignTypeForSpell( SPT_Superconductor ) );
		super.SetSpellSkill( S_modspell_y_01 ); //this sets the custom xml ability
		super.SetSignSkill( S_Magic_s03 ); 		//this sets the sign xml ability  used for bonus damage from equipped signs
		
	}

	protected function InitThrown()
	{


		
	}
	


	function CleanUpSpecific()
	{
		
		super.GetSignEntitySpell().DestroyAfter( 0.5f );

	}

	



	//SPELL MECHANICS
	/////////////////////////////////////////////////////////////////////////////

	public function ProcessSpell( bonusMult : float)
	{
		var targets : array<CActor>; // needs only be CNode
		var targetActor : CActor;
		var hitEntity : CEntity;
		
		var component : CComponent;
		var i : int;

		caster = super.GetOwner(); //FIXME HACK
		hitEntity = NULL;
		
		targets = thePlayer.GetNPCsAndPlayersInCone(50, VecHeading(thePlayer.GetHeadingVector()), 90, 20, , /*FLAG_OnlyAliveActors + FLAG_TestLineOfSight*/);
			
		//FindGameplayEntitiesInCone( targets, playerPos, VecHeading( direction ), maxDoorAngleGather, maxDist + maxDoorBack, 100, 'navigation_correction' );
		
		
		

		for( i = 0; i < targets.Size(); i += 1 )
		{

			if (targets[i] != (CActor)thePlayer)
			{

				targetActor = targets[i];

				//DEBUG
				//rf_log1( "Got target: " + targetActor, true);
				//DEBUG

				if ( !targetActor )
				{
					continue;
				}
				if ( targetActor.GetHealth() <= 0.f || targetActor.IsInAgony() )
				{
					continue;
				}
				if(targetActor && targetActor.GetGameplayVisibility())
				{

					hitEntity = ShootTarget(targetActor, true, 0.2f, false, bonusMult);

				}
			}
		}

	}

	var traceFrom, traceTo : Vector;
	private function ShootTarget( targetNode : CNode, useTargetsPositionCorrection : bool, extraRayCastLengthPerc : float, useProjectileGroups : bool , bonusMult : float) : CEntity
	{
		var results : array<SRaycastHitResult>;
		var i, ind : int;
		var min : float;
		var collisionGroupsNames : array<name>;
		var entity : CEntity;
		var targetActor : CActor;
		var targetPos : Vector;
		var physTest : bool;
		var yrdenEnt : W3YrdenEntity;

		//DEBUG
		//rf_log1( "ShootTarget " + targetNode, true);
		//DEBUG


		yrdenEnt = (W3YrdenEntity)GetSignEntitySpell();

		//COLLISION
		traceFrom = yrdenEnt.GetWorldPosition();
		//traceFrom.Z += 1.f;
		targetPos = targetNode.GetWorldPosition();
		traceTo = targetPos;
		if(useTargetsPositionCorrection)
			traceTo.Z += 1.f;
		traceTo = traceFrom + (traceTo - traceFrom) * (1.f + extraRayCastLengthPerc);
		
		collisionGroupsNames.PushBack( 'RigidBody' );
		collisionGroupsNames.PushBack( 'Static' );
		collisionGroupsNames.PushBack( 'Debris' );	
		collisionGroupsNames.PushBack( 'Destructible' );	
		collisionGroupsNames.PushBack( 'Terrain' );
		collisionGroupsNames.PushBack( 'Phantom' );
		collisionGroupsNames.PushBack( 'Water' );
		collisionGroupsNames.PushBack( 'Boat' );		
		collisionGroupsNames.PushBack( 'Door' );
		collisionGroupsNames.PushBack( 'Platforms' );
		collisionGroupsNames.PushBack( 'Projectile' );
		collisionGroupsNames.PushBack( 'Character' );
		
		
		
		//TEST COLLISIONS
		physTest = theGame.GetWorld().GetTraceManager().RayCastSync(traceFrom, traceTo, results, collisionGroupsNames);
		if ( !physTest || results.Size() == 0 )
			FindActorsAtLine( traceFrom, traceTo, 0.05f, results, collisionGroupsNames );
		
		//Go THROUGH COLLISIONS
		if ( results.Size() > 0 )
		{
			
			while(results.Size() > 0)
			{
				
				min = results[0].distance;
				ind = 0;
				
				for(i=1; i<results.Size(); i+=1)
				{
					if(results[i].distance < min)
					{
						min = results[i].distance;
						ind = i;
					}
				}
				
				
				if(results[ind].component)
				{
					entity = results[ind].component.GetEntity();
					targetActor = (CActor)entity;
					
					//attitudes
					if(targetActor && IsRequiredAttitudeBetween(targetActor, caster.GetActor(), false, false, true))
						return NULL;
					
					//Hit Enemy
					if( (targetActor && targetActor.GetHealth() > 0.f && targetActor.IsAlive()) || (!targetActor && entity) )
					{
						
						HitEnemy(targetActor, results[ind].position, bonusMult);						
						return entity;
					}
					else if(targetActor)
					{
						results.EraseFast(ind);
					}
				}
				else
				{
					break;
				}
			}
		}
		
		return NULL;

	}

	private function HitEnemy(entity : CEntity, hitPosition : Vector, bonusMult : float)
	{
		var component : CComponent;
		var targetActor, casterActor : CActor;
		var action : W3DamageAction;
		var player : W3PlayerWitcher;
		var i,j : int;
		var damages : array<SRawDamage>;
		var yrdenEnt : W3YrdenEntity;
		//bonus dmg
		var damageBonus	: float;
		var turretLevel	: int;
		var fxEntities : array< CEntity >;
		var fxEntity : CEntity;
		var fxpos, fxoffset : Vector;
		var coordoffset : float;

		coordoffset = 0.5;

		//DEBUG
		rf_log1( "HitEnemy " + entity, false);
		//DEBUG
		
		//PLAY EFFECTS
		theGame.SetTimeScale( 0.5, theGame.GetTimescaleSource( ETS_InstantKill ), theGame.GetTimescalePriority( ETS_InstantKill ), true, true );

		yrdenEnt = (W3YrdenEntity)GetSignEntitySpell();

		//yrdenEnt.PlayEffect( 'yrden_shock_activate' );
		targetActor = (CActor)entity;
		if(targetActor)
		{
			component = targetActor.GetComponent('torso3effect');		
			if ( component )
			{
				fxpos = component.GetWorldPosition();
			}
		}
		if(!targetActor || !component)
		{
			fxpos = targetActor.GetWorldPosition();
			fxpos.Z += 1;
		}

		

		//CREATE FX entities
		for(j=0; j<fxcount; j+=1)
		{
			fxoffset = fxoffset*0;
			
			fxoffset.X = RandRangeF( coordoffset, -coordoffset );
			fxoffset.Y = RandRangeF( coordoffset, -coordoffset );
			fxoffset.Z = RandRangeF( coordoffset*0.5, -coordoffset*0.5 );
			
			fxpos = fxpos + fxoffset;
			
			fxEntity = theGame.CreateEntity( projDestroyFxEntTemplate, fxpos );
			fxEntities.PushBack( fxEntity );

			yrdenEnt.PlayEffect( 'yrden_shock_activate', fxEntity );
		}

		//INIT DAMAGE ACTION
		casterActor = caster.GetActor();
		if ( casterActor && (CGameplayEntity)entity)
		{
			

			//Initialize damage action as heavy sign hit with Yrden FX
			action =  new W3DamageAction in theGame.damageMgr;
			action.Initialize( casterActor, (CGameplayEntity)entity, this, casterActor.GetName()+"_spell", EHRT_Heavy, CPS_SpellPower, false, false, true, false, 'yrden_shock', 'yrden_shock', 'yrden_shock', 'yrden_shock');
			super.InitSignDataForDamageAction(action);
			action.hitLocation = hitPosition;
			action.SetCanPlayHitParticle(true);
			
			//MANAGE BONUS DAMAGE
			if( caster.CanUseSkill(super.GetSignSkill()) )
			{
				turretLevel = caster.GetSkillLevel(super.GetSignSkill());
				damageBonus = GetSpellConfig().GetSpellAttributeValue( SpellSkillEnumToName(super.GetSpellSkill() ), 'damage_bonus_flat_after_1') * ( turretLevel - 1 );

				//FIXME
				if( caster.CanUseSkill(S_Magic_s16) )
					damageBonus = GetSpellConfig().GetSpellAttributeValue( SpellSkillEnumToName(super.GetSpellSkill()) , 'turret_bonus_damage') * caster.GetSkillLevel(S_Magic_s16);
			}
			else
			{
				turretLevel = 0;
				damageBonus = 0;
			}

			

			if(damageBonus > 0)
			{
				//get damages
				action.GetDTs(damages);
				//action.ClearDamage();

				for(i=0; i<damages.Size(); i+=1)
				{
					damages[i].dmgVal += damageBonus;
					action.AddDamage(damages[i].dmgType, damages[i].dmgVal);

					//DEBUG
					rf_log1( damages[i].dmgType + "- Bonus: " + damageBonus, false);
					//DEBUG
					
				}
			}

			if(bonusMult > 0)
			{
				//get damages
				action.GetDTs(damages);
				//action.ClearDamage();

				for(i=0; i<damages.Size(); i+=1)
				{
					damages[i].dmgVal *= (1 + bonusMult);
					action.AddDamage(damages[i].dmgType, damages[i].dmgVal);

					//DEBUG
					rf_log2( damages[i].dmgType + "- Charge Bonus: " + bonusMult, false);
					//DEBUG
					
				}

			}
			
			
			theGame.damageMgr.ProcessAction( action );
			targetActor.PlayEffect('hit_electric');

			//Cleanup fxEntities
			for(j=0; j<fxEntities.Size(); j+=1)
			{
				fxEntities[j].DestroyAfter(0.1f);
			}
		}
		else
		{
			if( !yrdenEnt.IsEffectActive( 'yrden_shock_activate' ) )
				yrdenEnt.PlayEffect( 'yrden_shock_activate', entity );	
		}
	}

}
///////////////////////////////////////////////////////////////////////////
//////////////////////////////// STATES ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////


// CHARGING
////////////////////////////////////////////////////////////////////////////////////

state SuperconductorCharge in CSpell_Superconductor extends BaseCharge
{
	var bonusMult : float;

	default bonusMult = 0.f;
	
	event OnEnterState(prevStateName : name)
	{
		//DEBUG
		rf_log1("child charge OnEnterState", true);
		//DEBUG

		super.OnEnterState( prevStateName );

		caster.OnDelayOrientationChange();
	}

	
	event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log1("child charge OnLeaveState", true);


		super.OnLeaveState( nextStateName );
	}

	event OnThrowing()
	{
		//DEBUG
		rf_log1("child Charging OnThrowing", true);
		//DEBUG

		if ( super.OnThrowing() )
		{
			//parent.InitThrown(); //unused
			ChargeSuperconductor();
		}

	}

	entry function ChargeSuperconductor()
	{
		caster.GetActor().OnSignCastPerformed(virtual_parent.GetSignType(), true);
		while( Update(theTimer.timeDelta, bonusMult) ) 
		{
			Sleep(theTimer.timeDelta); 	
			//DEBUG
			rf_log1("Charge Bonus: " + bonusMult, false);
			//DEBUG	
		}
	}



	event OnEnded(optional isEnd : bool)
	{
		//DEBUG
		rf_log1("child charge OnEnded", true);
		//DEBUG

		
		parent.ProcessSpell( bonusMult ); //in class, handles damage and effects for now
		
		parent.CleanUpSpecific();

		parent.AddTimer( 'RemoveSpellSloMo', 0.2 );
		
		super.OnEnded(isEnd);

		if ( caster.IsPlayer() )
		{
			caster.GetPlayer().LockToTarget( false );
			caster.GetPlayer().ResetRawPlayerHeading();		
		}		
		
		parent.AddTimer('RangeFXTimedOutDestroy', 0.1, , , , true);
		parent.AddTimer('CollisionFXTimedOutDestroy', 0.3, , , , true);
	}


	
		
}










// CAST
////////////////////////////////////////////////////////////////////////////////////

state SuperconductorCast in CSpell_Superconductor extends NormalCast
{
	var bonusMult : float;

	default bonusMult = 0;


	/*event OnEnterState(prevStateName : name)
	{
		//DEBUG
		rf_log2( "child cast OnEnterState" );
		//DEBUG

		super.OnEnterState(prevStateName);


	}*/

	/*event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log2("child cast OnLeaveState");
		//DEBUG


		super.OnLeaveState( nextStateName );

	}*/


	event OnThrowing()
	{
		var player				: CR4Player;
	
		//DEBUG
		rf_log2( "child cast OnThrowing", false );
		//DEBUG

		if( super.OnThrowing() ) //just returns 1 for now
		{
			parent.InitThrown(); //unused, handles thrown effects

			parent.ProcessSpell( bonusMult ); //in class, handles damage and effects for now
			
			player = caster.GetPlayer();
			
			if( player )
			{
				parent.ManagePlayerStamina();
			}
			else
			{
				caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SpellSkillEnumToName( parent.skillEnum ) );
			}
		}
	}

	

	event OnEnded(optional isEnd : bool)
	{
		parent.CleanUpSpecific();

		parent.AddTimer( 'RemoveSpellSloMo', 0.2 );
		
		super.OnEnded(isEnd);
	}




}








