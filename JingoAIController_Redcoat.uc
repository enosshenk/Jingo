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

function name GetReturnState()
{
	if (JingoPawn.LeadingFormation)
	{
		return 'Leading';
	}
	else
	{
		return 'Following';
	}
}

function SetEnemy(Pawn E)
{
	Enemy = E;
	Focus = E;
	GoalPoint = E.Location;
	GotoState('Moving');
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
	event SeePlayer( Pawn Seen )
	{
		GoalPoint = Seen.Location;
		Enemy = Seen;
		Focus = Seen;
		GotoState('Moving');
	}
	
	event EnemyNotVisible()
	{
		LastEnemy = Enemy;
		Focus = none;
		Enemy = none;
	}
	
	Begin:
		if (Enemy != none)
		{
			GoalPoint = Enemy.Location;
		}
		else
		{
			GoalPoint = LastEnemy.Location;
			GoalPoint.X += -512 + rand(512);
			GoalPoint.Y += -512 + rand(512);
		}
		Sleep(1);
		Goto 'Begin';
}

state Following
{
	Begin:
		GoalPoint = GetFormationLocation();
		GotoState('Moving');
}

state Moving
{
   function bool FindNavMeshPath()
	{
		// Clear cache and constraints (ignore recycling for the moment)
		NavigationHandle.PathConstraintList = none;
		NavigationHandle.PathGoalList = none;

		// Create constraints
		class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, GoalPoint);
		class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, GoalPoint, 32);

		// Find path
		return NavigationHandle.FindPath();
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
		GotoState(GetReturnState());
	}
	else if( FindNavMeshPath() )
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
			GotoState(GetReturnState());
		}
	}
	else
	{
		//Can't path there, go back to idle
		Sleep(1);
		GotoState(GetReturnState());
	}
	goto 'Begin';		
}

state Dead
{
	Begin:
}

defaultproperties 
{
	AIDebug = true
}