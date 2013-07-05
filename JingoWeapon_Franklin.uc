class JingoWeapon_Franklin extends JingoWeapon;

var ParticleSystemComponent MuzzleComponent;
var ParticleSystemComponent ImpactComponent;
var ParticleSystemComponent BeamComponent;
var Pawn LockedTarget;
var vector ImpactLoc;
var int BranchesElapsed;
var bool CanBranch;

simulated event PostBeginPlay()
{
	MuzzleComponent = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(ParticleSystem'JingoItems.franklinmuzzle_ps', SkelMesh, 'FireSocket', true);
	MuzzleComponent.SetColorParameter('ColorParam', MakeColor(255,255,255,0));	
	
	ImpactComponent = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'JingoItems.franklinimpact_ps', Location);
	ImpactComponent.SetColorParameter('ColorParam', MakeColor(255,255,255,0));	
	ImpactComponent.SetColorParameter('ColorParam2', MakeColor(255,255,255,0));	
	
	super.PostBeginPlay();
}

simulated function TimeWeaponEquipping()
{
	if (Instigator != none)
	{
		AttachWeaponTo(Instigator.Mesh);
	}
	super.TimeWeaponEquipping();
}

simulated function AttachWeaponTo( SkeletalMeshComponent MeshCpnt, optional Name SocketName )
{
	MeshCpnt.AttachComponentToSocket(Mesh, 'WeaponSocket');
}

simulated function DetachWeapon()
{
	Instigator.Mesh.DetachComponent(Mesh);
}

simulated function StartFire(byte FireModeNum)
{
	super.StartFire(FireModeNum);
	
	MuzzleComponent.SetColorParameter('ColorParam', MakeColor(255,255,255,255));
		
	BeamComponent = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(ParticleSystem'JingoItems.spark_ps', SkelMesh, 'FireSocket', true);
}

simulated function StopFire(byte FireModeNum)
{
	super.StopFire(FireModeNum);
	
	MuzzleComponent.SetColorParameter('ColorParam', MakeColor(255,255,255,0));
	
	BeamComponent.DeactivateSystem();
	BeamComponent = none;
	
	LockedTarget = none;
}

simulated function CustomFire()
{
	local vector			StartTrace, EndTrace;
	local Array<ImpactInfo>	ImpactList;
	local int				Idx, ShotCount;
	local ImpactInfo		RealImpact;
		
	if (LockedTarget == none)
	{
		// We don't have a locked target, so do an instant trace and see if we hit anyone

		// define range to use for CalcWeaponFire()
		StartTrace = Instigator.GetWeaponStartTraceLocation();
		EndTrace = StartTrace + vector(GetAdjustedAim(StartTrace)) * GetTraceRange();

		// Perform shot
		RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

		if (ImpactList.Length == 0)
		{
			ImpactLoc = EndTrace;
		}
		
		// Process all Instant Hits on local player and server (gives damage, spawns any effects).
		for (Idx = 0; Idx < ImpactList.Length; Idx++)
		{
			ProcessInstantHit(CurrentFireMode, ImpactList[Idx]);
		}
	}
}

simulated function ProcessInstantHit(byte FiringMode, ImpactInfo Impact, optional int NumHits)
{
	if (JingoEnemyPawn(Impact.HitActor) != none)
	{
		// We hit an enemy with the first trace, lock onto him
		LockedTarget = Pawn(Impact.HitActor);
		
	}
	else
	{
		LockedTarget = none;
		ImpactLoc = Impact.HitLocation;
	} 
}

simulated state WeaponFiring
{
	event Tick(float DeltaTime)
	{
		local vector SourceVector;
		
		SkelMesh.GetSocketWorldLocationAndRotation('FireSocket', SourceVector);
		BeamComponent.SetBeamSourcePoint(0, SourceVector, 0);
		
		if (LockedTarget == none)
		{			
			BeamComponent.SetBeamEndPoint(0, ImpactLoc);
			ImpactComponent.SetAbsolute(true);
			ImpactComponent.SetTranslation(ImpactLoc);
			ImpactComponent.SetColorParameter('ColorParam', MakeColor(255,255,255,255));	
			ImpactComponent.SetColorParameter('ColorParam2', MakeColor(255,255,255,255));			
		}
		else
		{
			if (LockedTarget.Health <= 0)
			{
				LockedTarget = none;
			}
			else
			{
				ImpactLoc = LockedTarget.Location;
				BeamComponent.SetBeamEndPoint(0, ImpactLoc);
				ImpactComponent.SetAbsolute(true);
				ImpactComponent.SetTranslation(ImpactLoc);
				ImpactComponent.SetColorParameter('ColorParam', MakeColor(255,255,255,255));	
				ImpactComponent.SetColorParameter('ColorParam2', MakeColor(255,255,255,255));	
			}
		}
		super.Tick(DeltaTime);
	}	
	
	simulated event BeginState( Name PreviousStateName )
	{
		SetTimer(1, true, 'FranklinTick');
		SetTimer(0.1, true, 'EnableBranch');
		
		super.BeginState(PreviousStateName);
	}	
	
	simulated event EndState( Name NextStateName )
	{
		ClearTimer('FranklinTick');
		ClearTimer('EnableBranch');
		
		super.EndState(NextStateName);
	}
	
	function EnableBranch()
	{
		CanBranch = true;
	}
	
	function FranklinTick()
	{
		local float BranchDistance;
		local JingoEnemyPawn TestActor;
		local Actor CandidateActor;
		local ParticleSystemComponent BranchComponent;
		
		if (LockedTarget != none)
		{
			BranchesElapsed = 0;
			
			// Zap the locked on target
			LockedTarget.TakeDamage(InstantHitDamage[0], Instigator.Controller, LockedTarget.Location * InstantHitMomentum[0], LockedTarget.Location, class'DamageType');
			
			// Find a branch target
			BranchDistance = 999999;
			foreach LockedTarget.VisibleCollidingActors(class'JingoEnemyPawn', TestActor, 768)
			{
				if (VSize(LockedTarget.Location - TestActor.Location) < BranchDistance && TestActor.Health > 0)
				{
					BranchDistance = VSize(LockedTarget.Location - TestActor.Location);
					CandidateActor = TestActor;
				}
			}
			
			// Zap his ass
			if (CandidateActor != none)
			{
				ZapAndBranch(LockedTarget, Pawn(CandidateActor));
				BranchesElapsed += 1;
				CanBranch = false;
			
				// Spawn a branch beam and target it
				BranchComponent = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'JingoItems.spark_branch_ps', LockedTarget.Location);
				BranchComponent.SetBeamSourcePoint(0, LockedTarget.Location, 0);
				BranchComponent.SetBeamEndPoint(0, CandidateActor.Location);
			}
		}
	}
	
	function ZapAndBranch(Pawn Source, Pawn Victim)
	{
		local float BranchDistance;
		local JingoEnemyPawn TestActor;
		local Actor CandidateActor;
		local ParticleSystemComponent BranchComponent;
		
		if (BranchesElapsed <= 3)
		{
			// Zap the locked on target
			Victim.TakeDamage(InstantHitDamage[0], Instigator.Controller, Victim.Location * InstantHitMomentum[0], LockedTarget.Location, class'DamageType');
			
			// Find a branch target
			BranchDistance = 999999;
			foreach Victim.VisibleCollidingActors (class'JingoEnemyPawn', TestActor, 768)
			{
				if (VSize(LockedTarget.Location - TestActor.Location) < BranchDistance && TestActor.Health > 0)
				{
					BranchDistance = VSize(LockedTarget.Location - TestActor.Location);
					CandidateActor = TestActor;
				}
			}
			
			// Zap his ass
			if (CandidateActor != none && CanBranch)
			{
				CanBranch = false;
				ZapAndBranch(Victim, Pawn(CandidateActor));
				BranchesElapsed += 1;
				
				// Spawn a branch beam and target it
				BranchComponent = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'JingoItems.spark_branch_ps', Source.Location);
				BranchComponent.SetBeamSourcePoint(0, Source.Location, 0);
				BranchComponent.SetBeamEndPoint(0, CandidateActor.Location);
			}	
		}
	}
}

defaultproperties
{
	WeaponRange = 1024
	
	FiringStatesArray(0) = WeaponFiring
	WeaponFireTypes(0) = EWFT_Custom
	FireInterval(0) = 0.5
	InstantHitDamage(0) = 20
	InstantHitMomentum(0) = 3
	Spread(0) = 0.05
	
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		SkeletalMesh = SkeletalMesh'JingoItems.franklin'
	End Object	
	Mesh = SkeletalMeshComponent0
	SkelMesh = SkeletalMeshComponent0
}