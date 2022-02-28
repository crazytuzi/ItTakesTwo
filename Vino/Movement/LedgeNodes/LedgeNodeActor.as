import Vino.Movement.LedgeNodes.LedgeNodeComponent;

const FName DummyMeshName = n"ShowHangLocationDummyMesh";
const FName PlayerCollisionProfile = n"PlayerCharacter";

class ALedgeNodeActor : AHazeActor
{
#if EDITOR
	default bRunConstructionScriptOnDrag = true;
#endif	

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.StaticMesh = Asset("/Engine/BasicShapes/Cube.Cube");
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, ShowOnActor)
	ULedgeNodeComponent LedgeNode;
	default LedgeNode.RelativeLocation = FVector(-100.f, 0.f, 50.f);

	UPROPERTY()
	FPlayerGrabbedLedgeNodeEvent OnLedgeNodeGrabbed;

	UPROPERTY()
	FPlayerLeftLedgeNodeEvent OnLedgeNodeLeft;

	FLedgeNodeGrabSettings Settings;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UHazeCharacterSkeletalMeshComponent DummyMesh = UHazeCharacterSkeletalMeshComponent::Create(this, DummyMeshName);
	
		DummyMesh.SetAnimationMode(EAnimationMode::AnimationSingleNode);
		DummyMesh.AnimationData.AnimToPlay = Asset("/Game/Animations/Characters/Cody/Traversal/LedgeGrab/Cody_Trav_LedgeGrab_mh.Cody_Trav_LedgeGrab_mh");

		DummyMesh.SetSkeletalMesh(Asset("/Game/Characters/Cody/Cody.Cody"));

		FQuat NodeRotation = LedgeNode.RelativeRotation.Quaternion();

		DummyMesh.AttachTo(LedgeNode);
		DummyMesh.RelativeLocation = -NodeRotation.UpVector * Settings.HangOffset - NodeRotation.ForwardVector * 45.f;
		DummyMesh.bIsEditorOnly = true;
		DummyMesh.CastShadow = false;
		DummyMesh.SetHiddenInGame(true);

		FHazeTraceParams LocationFreeTrace;
		LocationFreeTrace.InitWithCollisionProfile(PlayerCollisionProfile);
		LocationFreeTrace.SetToCapsule(30, 88.f);
		LocationFreeTrace.OverlapLocation = LedgeNode.WorldLocation -LedgeNode.UpVector * Settings.HangOffset;

		TArray<FOverlapResult> OverlapResults;
		const bool bIsInCollision = LocationFreeTrace.Overlap(OverlapResults);
		LedgeNode.PlacementCollisionState = bIsInCollision;
		UMaterial ClearMat = bIsInCollision ? Asset("/Game/Blueprints/Movement/LedgeNodes/Dev_LedgeNodeInvalidHang.Dev_LedgeNodeInvalidHang") : Asset("/Game/Blueprints/Movement/LedgeNodes/Dev_LedgeNodeHang.Dev_LedgeNodeHang");
		
		int MaterialAmount = DummyMesh.GetNumMaterials();
		for (int iMat = 0; iMat < MaterialAmount; ++iMat)
		{
			DummyMesh.SetMaterial(iMat, ClearMat);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FPlayerGrabbedLedgeNodeDelegate LedgeNodeGrabbedDelegate;
		LedgeNodeGrabbedDelegate.BindUFunction(this, n"LedgeNodeGrabbed");
		BindOnLedgeNodeGrabbed(this, LedgeNodeGrabbedDelegate);

		FPlayerLeftLedgeNodeDelegate LedgeNodeLeftDelegate;
		LedgeNodeLeftDelegate.BindUFunction(this, n"LedgeNodeLeft");
		BindOnLedgeNodeLetGo(this, LedgeNodeLeftDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LedgeNodeGrabbed(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter Player)
	{
		OnLedgeNodeGrabbed.Broadcast(LedgeNode, Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void LedgeNodeLeft(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter Player, ELedgeNodeLeaveType LeaveType)
	{
		OnLedgeNodeLeft.Broadcast(LedgeNode, Player, LeaveType);
	}
}
