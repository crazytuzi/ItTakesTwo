import Vino.Movement.LedgeNodes.LedgeNodeComponent;

UCLASS(Abstract)
class AWeightedSpaceHangPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HangPointRoot;

	UPROPERTY(DefaultComponent, Attach = HangPointRoot)
	UStaticMeshComponent HangPointMesh;

	UPROPERTY(DefaultComponent, Attach = HangPointRoot)
	UNiagaraComponent SweatEffectComp;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;
	FVector StartLocation;

	float TargetVerticalOffset = 0.f;
	float CurrentVerticalOffset = 0.f;
	float OffsetPerPlayer = 400.f;

	float CurrentVerticalOffsetSpeedMultiplier = 1.f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveHangPointTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike VerticalOffsetSpeedMultiplierTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance HappyFaceMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance AngryFaceMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance ConfusedFaceMaterial;

	int FaceMaterialSlot = 2;

	bool bTopGrabbed = false;
	bool bBottomGrabbed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = ActorTransform.TransformPosition(EndLocation);

		MoveHangPointTimeLike.BindUpdate(this, n"UpdateMoveHangPoint");
		VerticalOffsetSpeedMultiplierTimeLike.BindUpdate(this, n"UpdateVerticalOffsetSpeedMultiplier");

		MoveHangPointTimeLike.PlayFromStart();
		VerticalOffsetSpeedMultiplierTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveHangPoint(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateVerticalOffsetSpeedMultiplier(float CurValue)
	{
		CurrentVerticalOffsetSpeedMultiplier = CurValue;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float InterpSpeed = 250.f * CurrentVerticalOffsetSpeedMultiplier;
		CurrentVerticalOffset = FMath::FInterpConstantTo(CurrentVerticalOffset, TargetVerticalOffset, DeltaTime, InterpSpeed);
		HangPointRoot.SetRelativeLocation(FVector(0.f, 0.f, CurrentVerticalOffset));
	}

	UFUNCTION()
	void TopLedgeNodeGrabbed(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter Player)
	{
		bTopGrabbed = true;
		TargetVerticalOffset += OffsetPerPlayer;

		if (bBottomGrabbed)
			HangPointMesh.SetMaterial(FaceMaterialSlot, ConfusedFaceMaterial);
		else
			HangPointMesh.SetMaterial(FaceMaterialSlot, AngryFaceMaterial);

		SweatEffectComp.Activate();
	}

	UFUNCTION()
	void TopLedgeNodeLetGo(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter Player, ELedgeNodeLeaveType LeaveType)
	{
		bTopGrabbed = false;
		TargetVerticalOffset -= OffsetPerPlayer;

		if (!bBottomGrabbed)
		{
			HangPointMesh.SetMaterial(FaceMaterialSlot, HappyFaceMaterial);
			SweatEffectComp.Deactivate();
		}
		else
			HangPointMesh.SetMaterial(FaceMaterialSlot, AngryFaceMaterial);
	}
	
	UFUNCTION()
	void BottomLedgeNodeGrabbed(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter Player)
	{
		bBottomGrabbed = true;
		TargetVerticalOffset -= OffsetPerPlayer;

		if (bTopGrabbed)
			HangPointMesh.SetMaterial(FaceMaterialSlot, ConfusedFaceMaterial);
		else
			HangPointMesh.SetMaterial(FaceMaterialSlot, AngryFaceMaterial);

		SweatEffectComp.Activate();
	}

	UFUNCTION()
	void BottomLedgeNodeLetGo(ULedgeNodeComponent LedgeNode, AHazePlayerCharacter Player, ELedgeNodeLeaveType LeaveType)
	{
		bBottomGrabbed = false;
		TargetVerticalOffset += OffsetPerPlayer;

		if (!bTopGrabbed)
		{
			HangPointMesh.SetMaterial(FaceMaterialSlot, HappyFaceMaterial);
			SweatEffectComp.Deactivate();
		}
		else
			HangPointMesh.SetMaterial(FaceMaterialSlot, AngryFaceMaterial);
	}
}