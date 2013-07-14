class JingoAIController_Redcoat extends AIController;

var vector GoalPoint;			// Our current location to go to
var vector TempDest;
var bool AIDebug;
var JingoEnemyPawn_Redcoat JingoPawn;
var Pawn LastEnemy;

event Possess(Pawn inPawn, bool bVehicleTransition)
{
	super.Possess(inPawn, bVehicleTransition);
	
	inPawn.SetMovementPhysics();
	JingoPawn = JingoEnemyPawn_Redcoat(inPawn);
}

function vector GetFormationLocation()
{
	local vector TempVector;
	
	// This function gets a vector that we should move to to stay in formation
	// It's based on our redcoat's FormationID
	
	if (JingoPawn.FormationID % 2 == 0 && JingoPawn.FormationID != 0)
	{
		// Modulus of the ID is zero, this pawn is even numbered
		// Return a position 128 units left of the ID 2 less than ours
		TempVector = JingoPawn.Formation.Redcoats[JingoPawn.FormationID - 2].Location;
		TempVector += vect(0,-128,0) >> JingoPawn.Formation.Redcoats[JingoPawn.FormationID - 2].Rotation;
		return TempVector;
	}
	else if (JingoPawn.FormationID != 0)
	{
		// Mod ID is non-zero, this pawn is odd numbered
		// Return a position 128 units behind the ID 1 less than ours
		TempVector = JingoPawn.Formation.Redcoats[JingoPawn.FormationID - 1].Location;
		TempVector += vect(-128,0,0) >> JingoPawn.Formation.Redcoats[JingoPawn.FormationID - 1].Rotation;
		return TempVector;		
	}
}

function SetEnemy(Pawn E)
{
	Enemy = E;
	Focus = E;
}

function bool FindNavMeshPath(vector Point)
{
	// Clear cache and constraints (ignore recycling for the moment)
	NavigationHandle.PathConstraintList = none;
	NavigationHandle.PathGoalList = none;

	// Create constraints
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, Point);
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, Point, 32);

	// Find path
	return NavigationHandle.FindPath();
}
	
auto state Spawning
{
	Begin:		
		if (JingoPawn.LeadingFormation)
		{
			GotoState('Leading');
		}
		else
		{
			GotoState('Following');
		}
}

state Leading
{
	Begin:
	Sleep(5);
	if (Enemy != none)
	{
		GoalPoint = Enemy.Location;
		Focus = Enemy;
	}
	else
	{
		GoalPoint = Location;
		GoalPoint.X += -512 + Rand(512);
		GoalPoint.Y += -512 + Rand(512);
	}
	GotoState('LeaderMoving');
}

state LeaderMoving
{
	event SeePlayer( Pawn Seen )
	{
		Enemy = Seen;
		Focus = Seen;
		GotoState('LeadingAttack');
	}
	
	event BeginState(Name PreviousStateName)
	{
		JingoPawn.Formation.LeaderMoving = true;
	}
	
	event EndState(Name PreviousStateName)
	{
		JingoPawn.Formation.LeaderMoving = false;
	}
	
	Begin:	
	if(NavigationHandle.PointReachable(GoalPoint))
	{
		FlushPersistentDebugLines();
		//Direct move
		if (AIDebug == true) {
			DrawDebugSphere(GoalPoint,16,20,0,255,0,true);
		}
		MoveTo(GoalPoint, ,32);
		GotoState('Leading');
	}
	else if( FindNavMeshPath(GoalPoint) )
	{
		NavigationHandle.SetFinalDestination(GoalPoint);
		FlushPersistentDebugLines();
		if (AIDebug == true) {
			NavigationHandle.DrawPathCache(,TRUE);
		}
		
		// move to the first node on the path
		if( NavigationHandle.GetNextMoveLocation(TempDest, Pawn.GetCollisionRadius()))
		{
			if (AIDebug == true) {
				DrawDebugLine(Pawn.Location,TempDest,255,0,0,true);
				DrawDebugSphere(TempDest,16,20,255,0,0,true);
			}
			MoveTo(TempDest, ,32);
		}
		else
		{
			`log("Failure in moving path");
			GotoState('Leading');
		}
	}
	else
	{
		//Can't path there, go back to idle
		Sleep(1);
		GotoState('Leading');
	}
	goto 'Begin';		
}

state LeadingAttack
{
	event BeginState(Name PreviousStateName)
	{
		local rotator TempRot;
		local JingoEnemyPawn_Redcoat RC;
		
		JingoPawn.Formation.LeaderMoving = true;
		TempRot = Rotator(Pawn.Location - Enemy.Location);
		GoalPoint = Enemy.Location;
		GoalPoint += vect(512,0,0) >> TempRot;
		
		foreach JingoPawn.Formation.Redcoats(RC)
		{
			if (RC.FormationID != 0)
			{
//				JingoAIController_Redcoat(RC.Controller).SetEnemy(Enemy);
				JingoAIController_Redcoat(RC.Controller).GotoState('FollowingAttack');
			}
		}
	}
	
	event EndState(Name PreviousStateName)
	{
		JingoPawn.Formation.LeaderMoving = false;
	}
	
	Begin:	
	if (Pawn.ReachedPoint(GoalPoint, Pawn))
	{
		GotoState('Leading');
	}
	else
	{
		if( !NavigationHandle.PointReachable(GoalPoint))
		{
			if( FindNavMeshPath(GoalPoint) )
			{
				NavigationHandle.DrawPathCache(,TRUE);
			}
			else
			{
				//give up because the nav mesh failed to find a path
				`warn("FindNavMeshPath failed to find a path to"@GoalPoint);
				Sleep(2);
				GotoState('Leading');
			}   
		}
		else
		{
			// then move directly to the actor
			MoveTo(GoalPoint);
			FlushPersistentDebugLines();
			DrawDebugLine(Pawn.Location,GoalPoint,0,255,0,true);
			GotoState('LeadingFiring');
		}

		while( Pawn != None && !Pawn.ReachedPoint(GoalPoint, Pawn))
		{	
			if (Pawn.Health <= 0)
			{
				`log("Pawn death detected");
				GotoState('Dead');
			}
			// move to the first node on the path
			if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
			{
				// suggest move preparation will return TRUE when the edge's
			    // logic is getting the bot to the edge point
					// FALSE if we should run there ourselves
				if (!NavigationHandle.SuggestMovePreparation( TempDest,self))
				{
					MoveTo(TempDest);	
					FlushPersistentDebugLines();
					DrawDebugLine(Pawn.Location,TempDest,255,0,0,true);
					DrawDebugSphere(TempDest,16,20,255,0,0,true);		
					GotoState('LeadingFiring');
				}
			}
			sleep(1);
		}
	}
	sleep(1);
	GotoState('Leading');	
}

state LeadingFiring
{
	Begin:
	
	while (VSize(Pawn.Location - Enemy.Location) >= 512)
	{
		if (VSize(Pawn.Location - Enemy.Location) < 1500)
		{
			Pawn.StartFire(0);
			Pawn.StopFire(1);
			JingoPawn.Formation.LeaderAttacking = true;
			Sleep(3);
		}
		else
		{
			Pawn.StopFire(0);
			Pawn.StopFire(1);
			JingoPawn.Formation.LeaderAttacking = false;
			GotoState('Leading');
		}
	}
	
	if (VSize(Pawn.Location - Enemy.Location) <= 160)
	{
		Pawn.StopFire(0);
		Pawn.StartFire(1);
		Sleep(2);
	}
	else
	{
		Pawn.StopFire(0);
		Pawn.StopFire(1);
		JingoPawn.Formation.LeaderAttacking = false;
		GotoState('Leading');
	}
}

state Following
{
	function SetEnemy(Pawn E)
	{
		Enemy = E;
		Focus = E;
		GotoState('FollowingAttack');
	}
	
	Begin:

	while (Pawn != none && !Pawn.ReachedPoint(GetFormationLocation(), Pawn))
	{
		if( !NavigationHandle.PointReachable(GetFormationLocation()))
		{
			if( FindNavMeshPath(GetFormationLocation()) )
			{
				NavigationHandle.DrawPathCache(,TRUE);
			}
			else
			{
				//give up because the nav mesh failed to find a path
				`warn("FindNavMeshPath failed to find a path to"@GetFormationLocation());
				Sleep(1);
				Goto 'Begin';
			}   
		}
		else
		{
//			`log("Direct move");
			// then move directly to the actor
			MoveTo(GetFormationLocation());
//			FlushPersistentDebugLines();
//			DrawDebugLine(Pawn.Location,GoalPoint,0,255,0,true);
			Goto 'Begin';
		}

		while( Pawn != None && !Pawn.ReachedPoint(GetFormationLocation(), Pawn))
		{	
			if (Pawn.Health <= 0)
			{
				`log("Pawn death detected");
				GotoState('Dead');
			}
			// move to the first node on the path
			if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
			{
				// suggest move preparation will return TRUE when the edge's
			    // logic is getting the bot to the edge point
					// FALSE if we should run there ourselves
				if (!NavigationHandle.SuggestMovePreparation( TempDest,self))
				{
//					`log("Path move");
					MoveTo(TempDest);	
//					FlushPersistentDebugLines();
//					DrawDebugLine(Pawn.Location,TempDest,255,0,0,true);
//					DrawDebugSphere(TempDest,16,20,255,0,0,true);		
					Goto 'Begin';
				}
			}
			sleep(0.5);
		}
		Sleep(0.5);
		Goto 'Begin';
	}
	Sleep(0.5);
	Goto 'Begin';
}

state FollowingAttack
{
	Begin:

	while (Pawn != none && !Pawn.ReachedPoint(GetFormationLocation(), Pawn))
	{
		if( !NavigationHandle.PointReachable(GetFormationLocation()))
		{
			if( FindNavMeshPath(GetFormationLocation()) )
			{
				NavigationHandle.DrawPathCache(,TRUE);
			}
			else
			{
				//give up because the nav mesh failed to find a path
				`warn("FindNavMeshPath failed to find a path to"@GetFormationLocation());
				Sleep(1);
				Goto 'Begin';
			}   
		}
		else
		{
//			`log("Direct move");
			// then move directly to the actor
			MoveTo(GetFormationLocation());
//			FlushPersistentDebugLines();
//			DrawDebugLine(Pawn.Location,GoalPoint,0,255,0,true);
			GotoState('FollowingFiring');
		}

		while( Pawn != None && !Pawn.ReachedPoint(GetFormationLocation(), Pawn))
		{	
			if (Pawn.Health <= 0)
			{
				`log("Pawn death detected");
				GotoState('Dead');
			}
			// move to the first node on the path
			if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
			{
				// suggest move preparation will return TRUE when the edge's
			    // logic is getting the bot to the edge point
					// FALSE if we should run there ourselves
				if (!NavigationHandle.SuggestMovePreparation( TempDest,self))
				{
//					`log("Path move");
					MoveTo(TempDest);	
//					FlushPersistentDebugLines();
//					DrawDebugLine(Pawn.Location,TempDest,255,0,0,true);
//					DrawDebugSphere(TempDest,16,20,255,0,0,true);		
					GotoState('FollowingFiring');
				}
			}
			sleep(0.5);
		}
		Sleep(0.5);
		Goto 'Begin';
	}
	Sleep(0.5);
	Goto 'Begin';
}

state FollowingFiring
{
	Begin:
	
	while (JingoPawn.Formation.LeaderAttacking)
	{
		if (VSize(Pawn.Location - Enemy.Location) < 1500 && VSize(Pawn.Location - Enemy.Location) > 160)
		{
			Pawn.StartFire(0);
			Pawn.StopFire(1);
			Sleep(3);
		}
		else if (VSize(Pawn.Location - Enemy.Location) < 160)
		{
			Pawn.StartFire(1);
			Pawn.StopFire(0);
			Sleep(2);		
		}
		else
		{
			Pawn.StopFire(0);
			Pawn.StopFire(1);
			GotoState('Following');
		}
	}
	
	Pawn.StopFire(1);
	Pawn.StopFire(0);
	GotoState('Following');
}

state Dead
{
	Begin:
}

defaultproperties 
{
	AIDebug = true
}