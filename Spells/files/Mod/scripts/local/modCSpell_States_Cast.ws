///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////





// CAST
////////////////////////////////////////////////////////////////////////////////////

state BaseCast in CSpell
{
	var caster : W3SignOwner;

	event OnEnterState(prevStateName : name)
	{
		//DEBUG
		rf_log1("parent BaseCast OnEnterState");
		//DEBUG
		


		caster = parent.owner;
		if ( caster.IsPlayer() )
			caster.GetPlayer().GetMovingAgentComponent().EnableVirtualController( 'Signs', true );
		
	}

	event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log1("parent BaseCast OnLeaveState");
		//DEBUG


		caster.GetActor().SetBehaviorVariable( 'IsCastingSign', 0 );
		caster.SetCurrentlyCastSign( ST_None, NULL );

	}
	
	event OnThrowing()
	{		
		


		return true;
	}

	event OnEnded(optional isEnd : bool)
	{
		//DEBUG
		rf_log1("parent BaseCast OnEnded");
		//DEBUG

		

		parent.OnEnded(isEnd);
		parent.GotoState( 'Finished' );
	}

	/*event OnSignAborted( optional force : bool )
	{
		//DEBUG
		rf_log1("parent BaseCast OnSignAborted");
		//DEBUG
		
		
		parent.CleanUp();
		parent.StopAllEffects();
		parent.GotoState( 'Finished' );
	}*/

}

////////////////////////////////////////////////////////////////////////////////////

state NormalCast in CSpell extends BaseCast
{
	event OnEnterState( prevStateName : name )
	{
		//DEBUG
		rf_log1("parent NormalCast OnEnterState");
		//DEBUG

		super.OnEnterState(prevStateName);
		
		//CastEntry(); //unused, for latent functions


		
	}

	/*entry function CastEntry()
	{
		

	}*/
	
	event OnEnded(optional isEnd : bool)
	{
		//DEBUG
		rf_log1("parent NormalCast OnEnded");
		//DEBUG

		
		
		super.OnEnded(isEnd);
	}

	event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log1("parent NormalCast OnLeaveState");
		//DEBUG

		super.OnLeaveState(nextStateName);
				
	}
}













// CHANNELING
////////////////////////////////////////////////////////////////////////////////////

state Channeling in CSpell extends BaseCast
{
	

	event OnEnterState(prevStateName : name)
	{
		//DEBUG
		rf_log1("parent Channeling OnEnterState");
		//DEBUG

		super.OnEnterState( prevStateName );
		parent.cachedCost = -1.0f;
		
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent.owner.GetActor(), 'CastSignAction', -1, 8.0f, 0.2f, -1, true );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent, 'CastSignActionFar', -1, 30.0f, -1.f, -1, true );
	
	}


	event OnThrowing()
	{
		var actor : CActor;
		var player : CR4Player;
		var stamina : float;
		
		if( super.OnThrowing() )
		{
			actor = caster.GetActor();
			player = (CR4Player)actor;
			
			if(player)
			{
				if( parent.cachedCost <= 0.0f )
				{
					parent.cachedCost = player.GetStaminaActionCost( ESAT_Ability, SpellSkillEnumToName( parent.skillEnum ), 0 );
				}
			
				stamina = player.GetStat(BCS_Stamina);
			}
			
			if( player && player.CanUseSkill(S_Perk_09) && player.GetStat(BCS_Focus) >= 1 )
			{
				if( parent.cachedCost > 0 )
				{
					player.DrainFocus( 1 );
				}
				parent.SetUsedFocus( true );
			}
			else
			{
				actor.DrainStamina( ESAT_Ability, 0, 0, SpellSkillEnumToName( parent.skillEnum ) );
				actor.StartStaminaRegen();
				actor.PauseStaminaRegen( 'SignCast' );
				parent.SetUsedFocus( false );
			}
				
			return true;
		}
		
		return false;
	}
	
	

	function Update(dt : float) : bool
	{
		var multiplier, stamina, leftStaminaCostPerc, leftStaminaCost : float;
		var player : CR4Player;
		var reductionCounter : int;
		var stop : bool;
		var costReduction : SAbilityAttributeValue;

		player = GetWitcherPlayer();
		
		if(player)
		{
			stop = false;
			if( ShouldStopChanneling() )
			{
				stop = true;
			}
			else
			{
				if(player.CanUseSkill(S_Perk_09) && parent.usedFocus)
				{
					stop = (player.GetStat(BCS_Focus) <= 0); 
				}
				else
				{
					stop = (player.GetStat( BCS_Stamina ) <= 0);
				}
			}
		}		
		
		if(stop)
		{
			OnEnded(); //calls OnEnded here
			return false;
		}
		else
		{
			//DEBUG
			if ( !thePlayer.IsEffectActive( 'ability_gryphon_set' ) )
				thePlayer.PlayEffect( 'ability_gryphon_set' );
			//DEBUG

			reductionCounter = caster.GetSkillLevel( parent.GetSignSkill() ) - 1;
			multiplier = 1;
			if(reductionCounter > 0)
			{
				
				//FIXME make skill atributes custom
				costReduction = GetSpellConfig().GetSpellAttribute( SpellSkillEnumToName(parent.skillEnum), 'stamina_cost_reduction_after_1') * reductionCounter;
				multiplier = 1 - costReduction.valueMultiplicative;
			}
			
			if(player)
			{
				if( parent.cachedCost <= 0.0f )
				{	
					parent.cachedCost = multiplier * player.GetStaminaActionCost( ESAT_Ability, SpellSkillEnumToName( parent.skillEnum ), dt );
				}
			
				stamina = player.GetStat(BCS_Stamina);
				leftStaminaCostPerc = parent.cachedCost / player.GetStatMax(BCS_Stamina);
			}
			
			if(player && player.CanUseSkill(S_Perk_09) && parent.usedFocus )
			{
				player.DrainFocus( MinF(player.GetStat(BCS_Focus), leftStaminaCostPerc) );
			}
			else if(multiplier > 0.f)
			{
				caster.GetActor().DrainStamina( ESAT_Ability, 0, 0, SpellSkillEnumToName( parent.skillEnum ), dt, multiplier );
			}
			caster.OnProcessCastingOrientation( true );
			
		}
		return true;
	}

	private function ShouldStopChanneling() : bool
	{
		if ( theInput.GetActionValue( 'CastSignHold' ) > 0.f )
		{
			return false;
		}
		else
		{
			return true;
		}
	}

	event OnCheckChanneling()
	{
		return true;
	}

	event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log1("parent Channeling OnLeaveState");
		//DEBUG

		caster.GetActor().ResumeStaminaRegen( 'SignCast' );
		
		theGame.GetBehTreeReactionManager().RemoveReactionEvent( parent.owner.GetActor(), 'CastSignAction' );
		theGame.GetBehTreeReactionManager().RemoveReactionEvent( parent, 'CastSignActionFar' );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent.owner.GetActor(), 'CastSignAction', -1, 8.0f, -1.f, -1, true );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent, 'CastSignActionFar', -1, 30.0f, -1.f, -1, true );

		super.OnLeaveState( nextStateName );
	}

	//called from Update on Stop
	event OnEnded(optional isEnd : bool)
	{
		//DEBUG
		rf_log1("parent Channeling OnEnded");
		thePlayer.StopEffect('ability_gryphon_set');
		//DEBUG

		super.OnEnded(); //calls OnEnded in BaseCast
	}

	



	
}










