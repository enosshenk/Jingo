class JingoItem_Musket extends Actor
	placeable;
	
var() const editconst StaticMeshComponent	StaticMeshComponent;

event PostBeginPlay()
{	
	SetCollisionType(COLLIDE_TouchAll);
	super.PostBeginPlay();
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (JingoPawn(Other) != none)
	{
		JingoPawn(Other).InvManager.CreateInventory(class'JingoWeapon_Musket');
		self.Destroy();
	}
}

defaultproperties
{
	Physics = PHYS_Rotating
	RotationRate = (Pitch=0, Roll=0, Yaw=1000)
	
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh = StaticMesh'JingoItems.musket_static';
		bAllowApproximateOcclusion=TRUE
		bForceDirectLightMap=TRUE
		bUsePrecomputedShadows=TRUE
		CollideActors=True
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}