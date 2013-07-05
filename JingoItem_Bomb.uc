class JingoItem_Bomb extends KActor
	notplaceable;

var ParticleSystemComponent FuseSparks;
var ParticleSystemComponent ExplosionPS;
var float BombDamage;
var float BombDamageRadius;
var float FuseTime;
var float FuseTimeElapsed;

simulated event PostBeginPlay()
{
	FuseSparks = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'JingoItems.bombsparks_ps', Location, Rotation, self);
	
	super.PostBeginPlay();
}

function Tick(float DeltaTime)
{
	// Burn the fuse
	FuseTimeElapsed += DeltaTime;
	if (FuseTimeElapsed >= FuseTime)
	{
		// EXPLODE
		ExplosionPS = WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem'ScottPlosion.FX.ScottPlosion1', Location);
		HurtRadius(BombDamage, BombDamageRadius, class'JingoDamageType_Bomb', 150, Location);
		FuseSparks.DeactivateSystem();
		PlaySound(SoundCue'JingoSounds.Bomb_Cue',,,,Location);
		self.Destroy();
	}
	
	super.Tick(DeltaTime);
}

defaultproperties
{
	BombDamage = 75
	BombDamageRadius = 1024
	FuseTime = 3
	
	bNoDelete = false
	bStatic = false
	bBlockActors=true
	bAlwaysRelevant=true
	bCollideActors=true

	Begin Object Name=StaticMeshComponent0
		StaticMesh = StaticMesh'JingoItems.Bomb'
		bAllowApproximateOcclusion=TRUE
		bForceDirectLightMap=TRUE
		bUsePrecomputedShadows=TRUE
	End Object
}