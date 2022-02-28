import Peanuts.Spline.SplineComponent;

event void FClockTownGateGuardEvent();

UCLASS(Abstract)
class AClockTownGateGuard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY()
	FClockTownGateGuardEvent OnDistracted;

	UPROPERTY()
	FClockTownGateGuardEvent OnReturning;

	UPROPERTY()
	AHazeActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnMoveForwardEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnMoveBackwardsEvent;

	bool bDistracted = false;
	bool bReturning = false;
	float DistanceAlongSpline = 0.f;
	float TimeSpentInvestigating = 0.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Platform.SetCullDistance(Editor::GetDefaultCullingDistance(Platform) * CullDistanceMultiplier);
		SkelMesh.SetCullDistance(Editor::GetDefaultCullingDistance(SkelMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor != nullptr)
		{
			SplineComp = UHazeSplineComponent::Get(SplineActor);
		}
	}

	UFUNCTION()
	void GetDistracted()
	{
		if (bDistracted)
			return;

		TimeSpentInvestigating = 0.f;

		bDistracted = true;
		bReturning = false;

		OnDistracted.Broadcast();
		UHazeAkComponent::HazePostEventFireForget(OnMoveForwardEvent, SkelMesh.GetWorldTransform(), AttachToComp = SkelMesh);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (SplineComp == nullptr)
			return;

		if (bDistracted)
		{
			DistanceAlongSpline += 750.f * DeltaTime;
			DistanceAlongSpline = FMath::Clamp(DistanceAlongSpline, 0.f, SplineComp.SplineLength);
			FTransform CurTransform = SplineComp.GetTransformAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorTransform(CurTransform);
			if (DistanceAlongSpline >= SplineComp.SplineLength)
			{
				TimeSpentInvestigating += DeltaTime;
				if (TimeSpentInvestigating >= 2.8f)
				{
					bDistracted = false;
					bReturning = true;
					OnReturning.Broadcast();
					UHazeAkComponent::HazePostEventFireForget(OnMoveBackwardsEvent, SkelMesh.GetWorldTransform(), AttachToComp = SkelMesh);
				}
			}
		}

		if (bReturning)
		{
			DistanceAlongSpline -= 750.f * DeltaTime;
			FTransform CurTransform = SplineComp.GetTransformAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorTransform(CurTransform);
			if (DistanceAlongSpline <= 0.f)
			{
				bReturning = false;
			}
		}
	}
}