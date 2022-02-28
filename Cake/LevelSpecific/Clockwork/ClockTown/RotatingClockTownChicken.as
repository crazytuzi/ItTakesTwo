UCLASS(Abstract)
class ARotatingClockTownChicken : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeSkeletalMeshComponentBase ChickenMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 5000.f;
	default DisableComp.bAutoDisable = true;

	UPROPERTY()
	AHazeActor TargetToLookAt;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlatformMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PlatformMesh) * CullDistanceMultiplier);
		ChickenMesh.SetCullDistance(Editor::GetDefaultCullingDistance(ChickenMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetToLookAt == nullptr)
		{
			SetActorTickEnabled(false);
			return;
		}

		FVector DirToTarget = TargetToLookAt.ActorLocation - ActorLocation;
		DirToTarget = Math::ConstrainVectorToPlane(DirToTarget, FVector::UpVector);
		DirToTarget = DirToTarget.GetSafeNormal();
		SetActorRotation(DirToTarget.Rotation());
	}

	UFUNCTION()
	void SetLookAtTarget(AHazeActor Target)
	{
		if (Target == nullptr)
			return;

		TargetToLookAt = Target;
		SetActorTickEnabled(true);
	}
}