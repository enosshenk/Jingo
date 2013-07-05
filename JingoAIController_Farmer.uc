class JingoAIController_Farmer extends AIController;

var Vector TempDest, GoalPoint;
var bool AIDebug;
var Pawn MyPawn;

// Set up physics as soon as we posess our pawn.
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	super.Possess(inPawn, bVehicleTransition);
	inPawn.SetMovementPhysics();
	MyPawn = inPawn;
}

auto state Spawning
{
	Begin:
	`log("State Spawning");
	// Get pointer to the GoalPoint.
	GoalPoint = Location;
	GoalPoint.X += -512 + Rand(512);
	GoalPoint.Y += -512 + Rand(512);
		if (AIDebug == true) {
			DrawDebugSphere(GoalPoint,16,20,0,255,0,true);
		}
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
        class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, GoalPoint, 64);

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
        MoveTo(GoalPoint, ,64);
		GotoState('ReachedGoal');
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
			GotoState('Spawning');
		}
    }
    else
    {
		`log("Can't path");
        //Can't path there, go back to idle
		Sleep(1);
        GotoState('Spawning');
    }
    goto 'Begin';
}

state ReachedGoal
{
	Begin:
	Sleep(5);
	GotoState('Spawning');
}

defaultproperties 
{
	AIDebug = true
}