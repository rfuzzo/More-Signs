///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////

/*
Spell is
- charged
- cast (not channeled)
*/




statemachine class CSpell_Sparks extends CSpell
{
	

	public 				var caster : W3SignOwner;
	editable 			var projDestroyFxEntTemplate		: CEntityTemplate;
	 					var fxcount 						: int;					default fxcount = 3;
	public 				var isChanneled						: bool;					default isChanneled = false;

    ///////////////////////////////////////////////////////////////////////////
	//////////////////////////////// EVENTS ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////////

	public function GetSpellType() : ESpellType
	{
		return SPT_Sparks;

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


		//if ( theInput.IsActionPressed('CastSignHold') )
		if ( theInput.GetActionValue( 'CastSignHold' ) > 0.f ) 
		{
			
			owner.GetPlayer().SetBehaviorVariable( 'alternateSignCast', 1 );
			GotoState('SparksChanneling');
			isChanneled = true;

		}
		else
			CleanUpSpecific();
		
	}


	

	

	

	///////////////////////////////////////////////////////////////////////////
	//////////////////////////////// FUNCTIONS ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////////


	function InitSpecific()
	{
		caster = super.GetOwner();

		super.SetSignType( GetSignTypeForSpell( SPT_Sparks ) );
		super.SetSpellSkill( S_modspell_y_02 ); //this sets the custom xml ability
		super.SetSignSkill( S_Magic_s03 ); 		//this sets the sign xml ability  used for bonus damage from equipped signs

		
	}

	protected function InitThrown()
	{	
	}
	


	function CleanUpSpecific()
	{
		
		super.GetSignEntitySpell().DestroyAfter( 0.1f );

	}

	

}
///////////////////////////////////////////////////////////////////////////
//////////////////////////////// STATES ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////




// CHANNELING
////////////////////////////////////////////////////////////////////////////////////

state SparksChanneling in CSpell_Sparks extends Channeling
{


	event OnEnterState( prevStateName : name )
	{
		//DEBUG
		rf_log2("child Channeling OnEnterState");
		//DEBUG

		super.OnEnterState( prevStateName );
				
		caster.OnDelayOrientationChange();
	}


	event OnThrowing()
	{
		//DEBUG
		rf_log2("child Channeling OnThrowing", false);
		//DEBUG

		if ( super.OnThrowing() && parent.isChanneled )
		{
			//parent.InitThrown(); //unused
			ChannelSparks();
		}
	}

	event OnEnded(optional isEnd : bool)
	{
		//DEBUG
		rf_log2("child Channeling OnEnded");
		//DEBUG

		super.OnEnded(isEnd); //this calls OnEnded in BaseCast since there is no OnEnded in Channeling
		
		if ( caster.IsPlayer() )
		{
			caster.GetPlayer().LockToTarget( false );
			caster.GetPlayer().ResetRawPlayerHeading();		
		}		
		
				
		CleanUp();
		
		
		//parent.StopEffect( parent.effects[parent.fireMode].throwEffect );
		//parent.StopEffect( parent.effects[parent.fireMode].throwEffectSpellPower );			
	}

	event OnSignAborted( optional force : bool )
	{
		if ( caster.IsPlayer() )
		{
			caster.GetPlayer().LockToTarget( false );
		}
		
		CleanUp();
		
		//super.OnSignAborted( force );
	}


	entry function ChannelSparks()
	{
		var delayTick, delayTickMax : float;
		delayTickMax = 0.5f;
		delayTick = -1.f;
		

		caster.GetActor().OnSignCastPerformed(parent.GetSignType(), true);
		while( Update(theTimer.timeDelta) )
		{
			//delayTick = delayTick - theTimer.timeDelta;

			//if ( delayTick <  0.f )
			{
				//delayTick =delayTickMax;
				ProcessThrow(theTimer.timeDelta); 
			}
			Sleep(theTimer.timeDelta * 5);
		}
	}

	private function ProcessThrow(dt : float)
	{

		var targets : array<CActor>; // needs only be CNode
		var targetActor : CActor;
		var hitEntity : CEntity;
		
		var component : CComponent;
		var i : int;

		
		hitEntity = NULL;
		
		targets = thePlayer.GetNPCsAndPlayersInCone(10, VecHeading(thePlayer.GetHeadingVector()), 90, 20, , /*FLAG_OnlyAliveActors + FLAG_TestLineOfSight*/);

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

					hitEntity = ShootTarget(targetActor, true, 0.2f, false);

				}
			}
		}
	}

	var traceFrom, traceTo : Vector;
	private function ShootTarget( targetNode : CNode, useTargetsPositionCorrection : bool, extraRayCastLengthPerc : float, useProjectileGroups : bool ) : CEntity
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


		yrdenEnt = (W3YrdenEntity)virtual_parent.GetSignEntitySpell();

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
						
						HitEnemy(targetActor, results[ind].position);						
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

	private function HitEnemy(entity : CEntity, hitPosition : Vector)
	{
		var component : CComponent;
		var targetActor, casterActor : CActor;
		var action : W3DamageAction;
		var player : W3PlayerWitcher;
		var i, j : int;
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
		//rf_log1( "HitEnemy " + entity, true);
		//DEBUG


		yrdenEnt = (W3YrdenEntity)virtual_parent.GetSignEntitySpell();
		
		//PLAY EFFECTS
		//theGame.SetTimeScale( 0.5, theGame.GetTimescaleSource( ETS_InstantKill ), theGame.GetTimescalePriority( ETS_InstantKill ), true, true );


		//yrdenEnt.PlayEffect( 'yrden_shock_activate' );
		targetActor = (CActor)entity;
		if( targetActor )
		{
			component = targetActor.GetComponent('torso3effect');	
			if ( component )
			{
				fxpos = component.GetWorldPosition();
			}
		}
		if( !targetActor || !component )
		{
			fxpos = targetActor.GetWorldPosition();
			fxpos.Z += 1;
		}
		
		//CREATE FX entities
		for(j=0; j<parent.fxcount; j+=1)
		{
			fxoffset = fxoffset*0;
			
			fxoffset.X = RandRangeF( coordoffset, -coordoffset );
			fxoffset.Y = RandRangeF( coordoffset, -coordoffset );
			fxoffset.Z = RandRangeF( coordoffset*0.5, -coordoffset*0.5 );
			
			fxpos = fxpos + fxoffset;
			
			fxEntity = theGame.CreateEntity( parent.projDestroyFxEntTemplate, fxpos );
			fxEntities.PushBack( fxEntity );

			yrdenEnt.PlayEffect( 'yrden_shock_activate', fxEntity );
		}

		//INIT DAMAGE ACTION
		casterActor = caster.GetActor();
		if ( casterActor && (CGameplayEntity)entity)
		{
			//Initialize damage action as heaby sign hit with Yrden FX
			action =  new W3DamageAction in theGame.damageMgr;
			action.Initialize( casterActor, (CGameplayEntity)entity, this, casterActor.GetName()+"_spell", EHRT_Igni, CPS_SpellPower, false, false, true, false, 'yrden_shock', 'yrden_shock', 'yrden_shock', 'yrden_shock');
			virtual_parent.InitSignDataForDamageAction(action);
			action.hitLocation = hitPosition;
			action.SetCanPlayHitParticle(true);
			
			//MANAGE BONUS DAMAGE
			if( caster.CanUseSkill(virtual_parent.GetSignSkill()) )
			{
				turretLevel = caster.GetSkillLevel( virtual_parent.GetSignSkill() );
				damageBonus = GetSpellConfig().GetSpellAttributeValue( SpellSkillEnumToName(virtual_parent.skillEnum) , 'damage_bonus_flat_after_1') * ( turretLevel - 1 );

				if( caster.CanUseSkill(S_Magic_s16) )
					damageBonus = GetSpellConfig().GetSpellAttributeValue( SpellSkillEnumToName(virtual_parent.skillEnum) , 'turret_bonus_damage') * caster.GetSkillLevel(S_Magic_s16);
				
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
				action.ClearDamage();

				for(i=0; i<damages.Size(); i+=1)
				{
					damages[i].dmgVal += damageBonus;
					action.AddDamage(damages[i].dmgType, damages[i].dmgVal);

					//DEBUG
					rf_log1( damages[i].dmgType + "- Bonus: " + damageBonus, true);
					//DEBUG
				}
			}
			theGame.damageMgr.ProcessAction( action );

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




	function CleanUp()
	{
		parent.CleanUpSpecific();
	}


}




