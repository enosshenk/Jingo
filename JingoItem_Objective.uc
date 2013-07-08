class JingoItem_Objective extends Actor
	placeable;
	
var() const editconst StaticMeshComponent	StaticMeshComponent;
var() float SizeMultiplier;
var() enum EObjectiveType
{
	O_Timer,
	O_Location,
	O_GetItem,
	O_Kill
} ObjectiveType;

var() bool UseLocation;
var() bool AnnounceOnHUD;
var() string ObjectiveName;
var() int ObjectiveNumber;
var() float ObjectiveTimer;
var() JingoItem ItemObjective;

var bool ActiveObjective;

event PostBeginPlay()
{	
	local vector TempVect;
	
	TempVect.X = 128 * SizeMultiplier;
	TempVect.Y = 128 * SizeMultiplier;
	TempVect.Z = 1;
	
	SetDrawScale3D(TempVect);
	
	SetCollisionType(COLLIDE_TouchAll);
	
	StaticMeshComponent.SetHidden(true);
	
	super.PostBeginPlay();
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if (JingoPawn(Other) != none && ObjectiveType == O_Location && ActiveObjective)
	{
		JingoGameInfo(WorldInfo.Game).NextObjective();
		StaticMeshComponent.SetHidden(true);
	}
}

function ActivateObjective()
{
	ActiveObjective = true;
	StaticMeshComponent.SetHidden(!UseLocation);
}

function DeactivateObjective()
{
	ActiveObjective = false;
	StaticMeshComponent.SetHidden(true);
}

function CompleteObjective()
{
	ActiveObjective = false;
	JingoGameInfo(WorldInfo.Game).NextObjective();
	StaticMeshComponent.SetHidden(true);
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
	
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Crowd.T_Crowd_Behavior'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		bIsScreenSizeScaled=True
		ScreenSize=0.0025
		SpriteCategoryName="Effects"
	End Object
	Components.Add(Sprite)
	
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=128.000000
		CollisionHeight=128.000000
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
}