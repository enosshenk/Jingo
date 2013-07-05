class JingoWeapon_Shotgun extends JingoWeapon;

var ParticleSystem MuzzleFlashPS;

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

simulated function CustomFire()
{
	// Fire ze weapon
	local vector			StartTrace, EndTrace;
	local Array<ImpactInfo>	ImpactList;
	local int				Idx, ShotCount;
	local ImpactInfo		RealImpact;

	while (ShotCount < 8)
	{
		// define range to use for CalcWeaponFire()
		StartTrace = Instigator.GetWeaponStartTraceLocation();
		EndTrace = StartTrace + vector(GetAdjustedAim(StartTrace)) * GetTraceRange();

		// Perform shot
		RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

		// Process all Instant Hits on local player and server (gives damage, spawns any effects).
		for (Idx = 0; Idx < ImpactList.Length; Idx++)
		{
			ProcessInstantHit(CurrentFireMode, ImpactList[Idx]);
		}
		
		ShotCount += 1;
	}

	WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(MuzzleFlashPS, SkelMesh, 'FireSocket', true);
	PlaySound(SoundCue'JingoSounds.cannon1_Cue');
}

simulated function ProcessInstantHit(byte FiringMode, ImpactInfo Impact, optional int NumHits)
{
	if (JingoEnemyPawn(Impact.HitActor) != none)
	{
		// Hit a dude, go with the blood
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'JingoItems.splat_ps', Impact.HitLocation);
		Impact.HitActor.TakeDamage(InstantHitDamage[FiringMode], Instigator.Controller, Normal(Impact.HitActor.Location - Instigator.GetWeaponStartTraceLocation()) * InstantHitMomentum[FiringMode], Impact.HitLocation, class'DamageType');
	}
	else
	{
		WorldInfo.MyDecalManager.SpawnDecal (Material'JingoItems.bullethole_mat', Impact.HitLocation, rotator(-Impact.HitNormal), 64, 64, 256, false, FRand() * 360, Impact.HitInfo.HitComponent);
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'JingoItems.Impact_ps', Impact.HitLocation);
	}
}

defaultproperties
{
	FiringStatesArray(0) = WeaponFiring
	WeaponFireTypes(0) = EWFT_Custom
	FireInterval(0) = 3
	InstantHitDamage(0) = 20
	InstantHitMomentum(0) = 100
	Spread(0) = 0.5
	
	MuzzleFlashPS = ParticleSystem'JingoItems.cannonsmoke_ps'
	
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		SkeletalMesh = SkeletalMesh'JingoItems.shotgun'
	End Object	
	Mesh = SkeletalMeshComponent0
	SkelMesh = SkeletalMeshComponent0
}