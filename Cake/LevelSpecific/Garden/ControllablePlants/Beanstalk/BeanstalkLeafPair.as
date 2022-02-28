import Vino.Tilt.TiltComponent;

import FRotator GetClampedLeafRotation(AActor, FRotator) from "Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk";

UCLASS(Abstract)
class ABeanstalkLeafPair : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MeshAttach;

	UPROPERTY(DefaultComponent, Attach = MeshAttach)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent, Attach = MeshAttach)
	UStaticMeshComponent LeftLeaf;

	UPROPERTY(DefaultComponent, Attach = MeshAttach)
	UStaticMeshComponent RightLeaf;

	UHazeSplineComponent BeanstalkVisualSpline;
	UHazeSplineComponent BeanstalkSpline;
	AActor Beanstalk;

	private FVector StartLocation;

	UPROPERTY()
	FHazeTimeLike SpawnLeafPairTimeLike;
	default SpawnLeafPairTimeLike.Duration = 1.0f;

	float LeftLeafTargetScale = 2.0f;
	float RightLeafTargetScale = 2.0f;

	bool bSpawning = true;
	bool bDespawn = false;

	bool bPulsating = true;

	private bool bFinishedDespawning = false;

	FQuat RotationCurrent;

	bool HasFinishidedDespawning() const { return bFinishedDespawning; }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnLeafPairTimeLike.BindUpdate(this, n"UpdateSpawnLeafPair");
		SpawnLeafPairTimeLike.BindFinished(this, n"FinishSpawnLeafPair");
	}

	UFUNCTION()
	void UpdateSpawnLeafPair(float CurValue)
	{
		LeftLeaf.SetWorldScale3D(LeftLeafTargetScale * CurValue);
		RightLeaf.SetWorldScale3D(RightLeafTargetScale * CurValue);
	}

	UFUNCTION()
	void FinishSpawnLeafPair()
	{
		if(bDespawn)
		{
			SetActorHiddenInGame(true);
			bFinishedDespawning = true;
			SetActorTickEnabled(false);
		}
		else
		{
			SetActorEnableCollision(true);
		}

	}

	void SetLeafScale(float LeftLeaf, float RightLeaf)
	{
		LeftLeafTargetScale = LeftLeaf;
		RightLeafTargetScale = RightLeaf;
	}

	void SpawnLeafPair(FVector SpawnLoc, FRotator SpawnRot)
	{
		SetActorLocationAndRotation(SpawnLoc, SpawnRot);
		StartLocation = SpawnLoc;
		bSpawning = true;
		SpawnLeafPairTimeLike.PlayFromStart();
		SetActorHiddenInGame(false);
		bFinishedDespawning = false;
		bDespawn = false;
		SetActorTickEnabled(true);
		RotationCurrent = SpawnRot.Quaternion();
	}

	UFUNCTION()
	void DespawnLeaf()
 	{
		SetActorEnableCollision(false);
		bSpawning = false;
		bDespawn = true;
		SpawnLeafPairTimeLike.ReverseFromEnd();
		SetActorEnableCollision(false);
	}

	UFUNCTION()
	void UpdatePulseCurve(float CurveValue)
	{
		LeftLeaf.SetWorldScale3D(CurveValue);
		RightLeaf.SetWorldScale3D(CurveValue);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(BeanstalkVisualSpline != nullptr && BeanstalkSpline != nullptr)
		{
			const float SplineLength = BeanstalkSpline.SplineLength;
			const float VisualSplineLength = BeanstalkVisualSpline.SplineLength;
			const float ModifiedOriginalDistance = BeanstalkVisualSpline.GetDistanceAlongSplineAtWorldLocation(StartLocation);
			// Don't really know why making this value half the size creates a better flow for leafs. Could be a coincidence with the current speed of stalk animation.
			const float SplineDistanceOffset = (VisualSplineLength - SplineLength);
			const float DistanceOnSpline = ModifiedOriginalDistance + SplineDistanceOffset;
/*
			PrintToScreen("SplineLength " + SplineLength);
			PrintToScreen("VisualSplineLength " + VisualSplineLength);
			PrintToScreen("ModifiedOriginalDistance " + ModifiedOriginalDistance);
			PrintToScreen("SplineDistanceOffset " + SplineDistanceOffset);
			PrintToScreen("DistanceOnSpline " + DistanceOnSpline);
*/

			const FVector LocationOnSpline = BeanstalkVisualSpline.GetLocationAtDistanceAlongSpline(DistanceOnSpline, ESplineCoordinateSpace::World);
			FRotator RotationOnSpline = BeanstalkVisualSpline.GetRotationAtDistanceAlongSpline(DistanceOnSpline, ESplineCoordinateSpace::World);
			RotationOnSpline = GetClampedLeafRotation(Beanstalk, RotationOnSpline);
			RotationCurrent = FQuat::Slerp(ActorRotation.Quaternion(), RotationOnSpline.Quaternion(), DeltaTime * 3.0f);
			SetActorLocationAndRotation(LocationOnSpline, RotationCurrent);
		}
	}
}