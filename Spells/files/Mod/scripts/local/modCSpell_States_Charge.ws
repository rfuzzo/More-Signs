///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////


// CHARGING
////////////////////////////////////////////////////////////////////////////////////

state BaseCharge in CSpell
{
	var caster : W3SignOwner;

	event OnEnterState(prevStateName : name)
	{
		//DEBUG
		rf_log1("parent BaseCharge OnEnterState");
		//DEBUG

		caster = parent.owner;
		parent.cachedCost = -1.0f;

		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent.owner.GetActor(), 'CastSignAction', -1, 8.0f, 0.2f, -1, true );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent, 'CastSignActionFar', -1, 30.0f, -1.f, -1, true );
	

		
	}

	
	
	
	var chargeBonusMultMax : float;
	default chargeBonusMultMax = 3.f;

	function Update(dt : float, out mult : float) : bool
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
			if( ShouldStopCharging(mult) )
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
			//DEBUG
			rf_log1("Update Ended", false);
			//DEBUG	
			OnEnded();
			return false;
		}
		else
		{
			//DEBUG
			if ( !thePlayer.IsEffectActive( 'ability_gryphon_set' ) )
				thePlayer.PlayEffect( 'ability_gryphon_set' );
			//DEBUG

			//calulate charge bonus multiplier
			// in one second: plus 1. 
			mult += dt;


			reductionCounter = caster.GetSkillLevel( parent.GetSignSkill() ) - 1;
			multiplier = 1;
			if(reductionCounter > 0)
			{
				costReduction = GetSpellConfig().GetSpellAttribute( SpellSkillEnumToName(parent.skillEnum), 'stamina_cost_reduction_after_1') * reductionCounter
				;				
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

	private function ShouldStopCharging(mult : float) : bool
	{
		if (mult > chargeBonusMultMax)
		{
			return true;
		}

		if ( theInput.GetActionValue( 'CastSignHold' ) > 0.f )
		{
			return false;
		}
		else
		{
			return true;
		}
	}

	event OnCheckCharging()
	{
		return true;
	}

	event OnThrowing()
	{
		return true;
		
	}

	event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log1("parent BaseCharge OnLeaveState");
		thePlayer.StopEffect('ability_gryphon_set');
		//DEBUG

		caster.GetActor().ResumeStaminaRegen( 'SignCast' );
		
		theGame.GetBehTreeReactionManager().RemoveReactionEvent( parent.owner.GetActor(), 'CastSignAction' );
		theGame.GetBehTreeReactionManager().RemoveReactionEvent( parent, 'CastSignActionFar' );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent.owner.GetActor(), 'CastSignAction', -1, 8.0f, -1.f, -1, true );
		theGame.GetBehTreeReactionManager().CreateReactionEventIfPossible( parent, 'CastSignActionFar', -1, 30.0f, -1.f, -1, true );

		super.OnLeaveState( nextStateName );
	}

	//called from Update on Stop, does nothing, because after charge comes cast, but cast is called from the anim events
	event OnEnded(optional isEnd : bool)
	{
		//DEBUG
		rf_log1("parent BaseCharge OnEnded");
		//DEBUG

		parent.GotoState( 'Finished' );

	}




	
}
































