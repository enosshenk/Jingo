class JingoItem_Objective extends Actor
	placeable;
	
var() const editconst StaticMeshComponent	StaticMeshComponent;
var() float SizeMultiplier;

event PostBeginPlay()
{	
	local vector TempVect;
	
	TempVect.X = 128 * SizeMultiplier;
	TempVect.Y = 128 * SizeMultiplier;
	TempVect.Z = 1;
	
	SetDrawScale3D(TempVect);
	super.PostBeginPlay();
}

defaultproperties
{
	SizeMultiplier = 1
	
	bStatic = false
	
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh = StaticMesh'JingoItems.circle';
		bAllowApproximateOcclusion=TRUE
		bForceDirectLightMap=TRUE
		bUsePrecomputedShadows=TRUE
		CollideActors=True
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}