class JingoWeapon_Gatling extends JingoWeapon;

var ParticleSystem MuzzleFlashPS;
var UDKSkelControl_SpinControl BarrelControl;

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	// Collect all our skeletal mesh controls
	BarrelControl = UDKSkelControl_SpinControl(SkelComp.FindSkelControl('Barrel_Cont'));	
	super.PostInitAnimTree(SkelComp);
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
	if( Instigator == None || !Instigator.bNoWeaponFiring )
	{
		if( Role < Role_Authority )
		{
			// if we're a client, synchronize server
			ServerStartFire(FireModeNum);
		}

		// Spin up the barrels
		SkelMesh.FindSkelControl('Barrel_Cont').SetSkelControlActive(true);
		SetTimer(0.5, false, 'GatlingBeginFire');
	}
}

function GatlingBeginFire()
{
	BeginFire(0);
}

simulated function StopFire(byte FireModeNum)
{
	// Spin down the barrels
	SkelMesh.FindSkelControl('Barrel_Cont').SetSkelControlActive(false);
		
	// Locally shut down the fire sequence
	ClearTimer('GatlingBeginFire');
	EndFire(FireModeNum);

	// Notify the server
	if( Role < Role_Authority )
	{
		ServerStopFire(FireModeNum);
	}
}


simulated function InstantFire()
{
	local vector			StartTrace, EndTrace;
	
	super.InstantFire();
	
	StartTrace = Instigator.GetWeaponStartTraceLocation();
	EndTrace = StartTrace + vector(GetAdjustedAim(StartTrace)) * GetTraceRange();
//	DrawDebugLine(EndTrace, StartTrace, 1, 0, 0, true);
	WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(ParticleSystem'JingoItems.muzzlesmoke_ps', SkelMesh, 'FireSocket', true);
	PlaySound(SoundCue'JingoSounds.musket1_cue');
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
	WeaponFireTypes(0) = EWFT_InstantHit
	FireInterval(0) = 0.15
	InstantHitDamage(0) = 15
	InstantHitMomentum(0) = 75
	Spread(0) = 0.05
	
	MuzzleFlashPS = ParticleSystem'JingoItems.muzzlesmoke_ps'
	
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		SkeletalMesh = SkeletalMesh'JingoItems.gatling'
		AnimTreeTemplate=AnimTree'JingoItems.gatling_tree'
	End Object	
	Mesh = SkeletalMeshComponent0
	SkelMesh = SkeletalMeshComponent0
}