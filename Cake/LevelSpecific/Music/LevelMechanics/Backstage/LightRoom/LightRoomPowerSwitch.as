import Vino.Interactions.InteractionComponent;

event void FPowerSwitchActivated();

class ALightRoomPowerSwitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshBase;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent SwitchMeshRoot;

	UPROPERTY(DefaultComponent, Attach = SwitchMeshRoot)
	UStaticMeshComponent SwitchMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = InteractionComp)
	USkeletalMeshComponent PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default PreviewMesh.bHiddenInGame = true;

	UPROPERTY()
	FHazeTimeLike MoveSwitchTimeline;
	default MoveSwitchTimeline.Duration = 0.1f;

	UPROPERTY()
	FPowerSwitchActivated OnPowerSwitchActivated;

	FRotator StartingRot = FRotator::ZeroRotator;
	FRotator TargetRot = FRotator(-40.f, 0.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		MoveSwitchTimeline.BindUpdate(this, n"MoveSwitchTimelineUpdate");
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Component, AHazePlayerCharacter PlayerActivated)
	{
		for (auto Player : Game::GetPlayers())
			Component.DisableForPlayer(Player, n"Activated");
		
		MoveSwitchTimeline.Play();
		OnPowerSwitchActivated.Broadcast();
	}

	UFUNCTION()
	void MoveSwitchTimelineUpdate(float CurrentValue)
	{	
		SwitchMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRot, TargetRot, CurrentValue));
	}
}