///////////////////////////////////////////////////////////////////////////
///////////////////////////// MOD SPELLS //////////////////////////////////
///////////////////////////// by rfuzzo ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////



// ACTIVE
////////////////////////////////////////////////////////////////////////////////////

state Active in CSpell
{
	
	event OnEnterState( prevStateName : name )
	{
		//DEBUG
		rf_log1("parent Active OnEnterState");
		//DEBUG

	}

	event OnLeaveState( nextStateName : name )
	{
		//DEBUG
		rf_log1("parent Active OnLeaveState");
		//DEBUG



	}
	
	
}

// FINISHED
////////////////////////////////////////////////////////////////////////////////////

state Finished in CSpell
{
	event OnEnterState( prevStateName : name )
	{
		
		//DEBUG
		rf_log1("parent Finished OnEnterState");
		//DEBUG

		
		
		if ( parent.owner.IsPlayer() )
		{
			
			parent.owner.GetPlayer().GetMovingAgentComponent().EnableVirtualController( 'Signs', false );	
		}
		
		

		parent.CleanUp();

		
	}
	
	event OnLeaveState( nextStateName : name )
	{
		
		//DEBUG
		rf_log1("parent Finished OnLeaveState");
		//DEBUG

		if ( parent.owner.IsPlayer() )
		{
			parent.owner.GetPlayer().RemoveCustomOrientationTarget( 'Signs' );
		}


	}
	
	
}


































