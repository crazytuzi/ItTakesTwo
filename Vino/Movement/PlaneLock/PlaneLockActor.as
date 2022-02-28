import Vino.Movement.PlaneLock.PlaneLockStatics;

class APlaneLockActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, showonactor)
	UPlaneLockComponent Root;

	default Root.SetbVisualizeComponent(true);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UStaticMeshComponent DummyMesh = UStaticMeshComponent::Create(this, n"PlaneRep");
	
		DummyMesh.StaticMesh = Asset("/Game/Environment/BasicShapes/Plane.Plane");
		DummyMesh.RelativeRotation = FRotator(0.f, 0.f, 90.f);
		DummyMesh.bIsEditorOnly = true;
		DummyMesh.CastShadow = false;
		DummyMesh.SetHiddenInGame(true);
		DummyMesh.CollisionProfileName = n"NoCollision";
	}

	UFUNCTION()
	void LockActorToPlane(AHazeActor ActorToLock)
	{
		Root.LockActorToPlane(ActorToLock);
	}

	UFUNCTION()
	void StopLockingActorToPlane(AHazeActor ActorToLock)
	{
		StopPlaneLockMovement(ActorToLock);
	}
}

enum EPlaneLockEnterType
{
	Snap,
	Lerp,
	Speed,
}

class UPlaneLockComponent : USceneComponent
{
	UPROPERTY()
	float DebugLineDistance = 3000.f;

	UPROPERTY()
	int DebugHeightLineCount = 30;

	UPROPERTY(meta = (EditCondition = EnterType, EditValue = EPlaneLockEnterType::Lerp))
	float LerpTime = 0.f;

	UPROPERTY(meta = (EditCondition = EnterType, EditValue = EPlaneLockEnterType::Speed))
	float LocationLerpSpeed = 0.f;

	UPROPERTY(meta = (EditCondition = EnterType, EditValue = EPlaneLockEnterType::Speed))
	float RotationLerpSpeed = 0.f;

	UPROPERTY()
	EPlaneLockEnterType EnterType = EPlaneLockEnterType::Snap; 

	UPROPERTY()
	bool bUpdatePlaneWithComponent = false;

	UFUNCTION()
	void LockActorToPlane(AHazeActor ActorToLock)
	{
		FPlaneConstraintSettings Settings;
		Settings.Normal = ComponentQuat.RightVector;
		Settings.Origin = WorldLocation;
		if (bUpdatePlaneWithComponent)
			Settings.PlaneDefiner = this;

		switch(EnterType)
		{
			case EPlaneLockEnterType::Lerp:
			{
				StartPlaneLockMovementWithLerp(ActorToLock, Settings, LerpTime);
				break;
			}
			
			case EPlaneLockEnterType::Speed:
			{
				StartPlaneLockMovementWithSpeed(ActorToLock, Settings, LocationLerpSpeed, RotationLerpSpeed);
				break;
			}

			default:
			{
				StartPlaneLockMovement(ActorToLock, Settings);
			}
		}
	}

	UFUNCTION()
	void StopLockingActorToPlane(AHazeActor ActorToLock)
	{
		StopPlaneLockMovement(ActorToLock);
	}
}

class UPlaneLockComponentVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPlaneLockComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto Comp = Cast<UPlaneLockComponent>(Component);
        if (Comp == nullptr)
            return;

		FVector LineDelta = Comp.ComponentQuat.ForwardVector * Comp.DebugLineDistance;
		FVector HeightDelta = Comp.ComponentQuat.UpVector * 50.f;
		FVector WorldLoc = Comp.WorldLocation;

		for (int LineAmount = 0; LineAmount < Comp.DebugHeightLineCount; LineAmount++)
		{
			FVector Start = WorldLoc + (HeightDelta * LineAmount) - LineDelta;
			FVector End = WorldLoc + (HeightDelta * LineAmount) + LineDelta;
			DrawArrow(Start, End, FLinearColor::Teal, 1.f);

			Start = WorldLoc + (-HeightDelta * LineAmount) - LineDelta;
			End = WorldLoc + (-HeightDelta * LineAmount) + LineDelta;
			DrawArrow(Start, End, FLinearColor::Teal, 1.f);
		}
    }
}

