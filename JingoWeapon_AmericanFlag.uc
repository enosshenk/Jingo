class JingoWeapon_AmericanFlag extends JingoWeapon;

simulated function TimeWeaponEquipping()
{
	if (Instigator != none)
	{
		AttachWeaponTo(Instigator.Mesh);
	}
	
	SkelMesh.SetEnableClothSimulation(true);
	
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
	
	
}

simulated state WeaponFiring
{
	simulated event BeginState( Name PreviousStateName )
	{
		local vector StartTrace, EndTrace, HitLocation, HitNormal, TraceExtent;
		local actor HitActor;
		
		Instigator.Mesh.GetSocketWorldLocationAndRotation('WeaponTraceSocket', StartTrace);
		EndTrace = StartTrace + vector(GetAdjustedAim(StartTrace)) * GetTraceRange();
		DrawDebugLine(StartTrace,EndTrace,255,0,0,true);
		TraceExtent.X = 32;
		TraceExtent.Y = 32;
		
		HitActor = Trace(HitLocation, HitNormal, EndTrace, StartTrace, true, TraceExtent);
		
		if (JingoEnemyPawn(HitActor) != none)
		{
			// Bashed an enemy
			HitActor.TakeDamage(InstantHitDamage[0], Instigator.Controller, HitActor.Location * InstantHitMomentum[0], HitLocation, class'DamageType');
//			JingoEnemyPawn(HitActor).Knockdown();
			
		}
		`log("Whacked " $HitActor);
		
		JingoPawn(Instigator).PriorityAnimSlot.PlayCustomAnimByDuration('swingflag', 0.5, 0.1, 0.1, false, true);
		Super.BeginState(PreviousStateName);
	}
}

defaultproperties
{
	WeaponRange = 256
	
	FiringStatesArray(0) = WeaponFiring
	WeaponFireTypes(0) = EWFT_Custom
	FireInterval(0) = 0.5
	InstantHitDamage(0) = 50
	InstantHitMomentum(0) = 8
	Spread(0) = 0.05
	
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		SkeletalMesh = SkeletalMesh'JingoItems.flag'
	End Object	
	Mesh = SkeletalMeshComponent0
	SkelMesh = SkeletalMeshComponent0
}