import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Peanuts.Spline.SplineComponent;

class ATownsfolkDrinker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UPoseableMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTimeControlActorComponent TimeControlComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY()
	AHazeActor TargetSpline;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY()
	UCurveFloat LocationCurve;
	UPROPERTY()
	UCurveFloat RotationCurve;

	UPROPERTY()
	bool bLeft = true;

	UPROPERTY(Category = "Preview", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewAlpha = 1.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetSpline == nullptr)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(TargetSpline);
		if (SplineComp == nullptr)
			return;

		FVector Loc = SplineComp.GetLocationAtTime(LocationCurve.GetFloatValue(PreviewAlpha), ESplineCoordinateSpace::World);
		FRotator Rot = SplineComp.GetRotationAtTime(PreviewAlpha, ESplineCoordinateSpace::World);
		if (RotationCurve != nullptr)
		{
			float RotationMultiplier = RotationCurve.GetFloatValue(PreviewAlpha);
			Rot.Yaw += RotationMultiplier * 180.f;
		}
		SetActorLocationAndRotation(Loc, Rot);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetSpline != nullptr)
		{
			TargetSplineComp = UHazeSplineComponent::Get(TargetSpline);
		}

		TimeControlComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");
	}

	UFUNCTION()
	void TimeIsChanging(float PointInTime)
	{
		if (!TimeControlComp.bCanBeTimeControlled)
			return;

		if (TargetSplineComp == nullptr)
			return;

		FVector Loc = TargetSplineComp.GetLocationAtTime(LocationCurve.GetFloatValue(PointInTime), ESplineCoordinateSpace::World);
		FRotator Rot = TargetSplineComp.GetRotationAtTime(PointInTime, ESplineCoordinateSpace::World);
		if (RotationCurve != nullptr)
		{
			float RotationMultiplier = RotationCurve.GetFloatValue(PointInTime);
			Rot.Yaw += RotationMultiplier * 180.f;
		}
		SetActorLocationAndRotation(Loc, Rot);
	}
}