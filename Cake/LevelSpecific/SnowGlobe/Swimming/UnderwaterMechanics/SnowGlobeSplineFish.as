import Peanuts.Spline.SplineActor;
import Vino.Animations.PoseTrailComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;

struct FSplineFishBoneRotations
{
	UPROPERTY()
	FRotator Head;
	UPROPERTY()
	FRotator Neck;
	UPROPERTY()
	FRotator Spine2;
	UPROPERTY()
	FRotator Spine1;
	UPROPERTY()
	FRotator Spine;
	UPROPERTY()
	FRotator Tail1;
	UPROPERTY()
	FRotator Tail2;
	UPROPERTY()
	FRotator Tail3;
	UPROPERTY()
	FRotator Tail4;
}

namespace SnowGlobeSplineFish
{
	UFUNCTION()
	void GetSplineFishPose(UPoseTrailComponent PoseTrail, FSplineFishBoneRotations& Pose)
	{
		if (PoseTrail == nullptr)
			return;

		PoseTrail.Pose.Find(n"Head", Pose.Head);
		PoseTrail.Pose.Find(n"Neck", Pose.Neck);
		PoseTrail.Pose.Find(n"Spine2", Pose.Spine2);
		PoseTrail.Pose.Find(n"Spine1", Pose.Spine1);
		PoseTrail.Pose.Find(n"Spine", Pose.Spine);
		PoseTrail.Pose.Find(n"Tail1", Pose.Tail1);
		PoseTrail.Pose.Find(n"Tail2", Pose.Tail2);
		PoseTrail.Pose.Find(n"Tail3", Pose.Tail3);
		PoseTrail.Pose.Find(n"Tail4", Pose.Tail4);
	}
} 

UCLASS(Abstract)
class ASnowGlobeSplineFish : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent SceneRoot; 

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard; 

	UPROPERTY(DefaultComponent)
	USkeletalMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UPoseTrailComponent PoseTrail;
	default PoseTrail.Interval = 100.f;
	default PoseTrail.BoneInterpolationSpeed = 2.f;

	UPROPERTY(DefaultComponent)
	USnowGlobeSplineFishMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent, Attach = SceneRoot)
	USnowGlobeLakeDisableComponentExtension DisableComponentExtension;
	default DisableComponentExtension.ActiveType = ESnowGlobeLakeDisableType::ActiveUnderSurfaceAlways;
	default DisableComponentExtension.bActorIsVisualOnly = true;

	UPROPERTY(BlueprintReadOnly)
	FSplineFishBoneRotations BoneRotations;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSplineFishAudioEvent;

	UPROPERTY()
	ASplineActor SplineToFollow;

	UPROPERTY()
	float SpeedAlongSpline = 600.f; 

	FHazeAcceleratedRotator CurrentRotation;
	FHazeSplineSystemPosition CurrentPosition;
	float HeadOffsetAlongSpline = 0.f;
	float LastDistanceAlongSpline = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineToFollow != nullptr && SplineToFollow.Spline != nullptr)
		{
			auto Spline = SplineToFollow.Spline;
			const float SplineDistance = Spline.GetDistanceAlongSplineAtWorldLocation(GetActorLocation());
			const FVector SplineDir = Spline.GetDirectionAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
			const FVector WantedActorLocation = Spline.GetLocationAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);
			const bool bIsForwardOnSpline = SplineDir.DotProduct(GetActorForwardVector()) >= 0;
			FRotator Rot;
			if(bIsForwardOnSpline)
				Rot = SplineDir.Rotation();
			else
				Rot = (-SplineDir).Rotation();

			SetActorLocationAndRotation(WantedActorLocation, Rot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Along trail, head will always be at distance 0. All other offsets will thus depend on this
		float HeadOffsetAlongMesh = PoseTrail.GetBoneOffsetAlongMesh(n"Head", Mesh);

		TArray<FName> Anterior;	
		Anterior.Add(n"Spine");	
		Anterior.Add(n"Spine1"); 
		Anterior.Add(n"Spine2");
		Anterior.Add(n"Neck");
		Anterior.Add(n"Head"); 
		PoseTrail.AddBoneBranch(Anterior, Mesh, HeadOffsetAlongMesh);

		TArray<FName> Posterior;
		Posterior.Add(n"Tail1");
		Posterior.Add(n"Tail2");
		Posterior.Add(n"Tail3");
		Posterior.Add(n"Tail4");
		PoseTrail.AddBoneBranch(Posterior, Mesh, HeadOffsetAlongMesh);

		HazeAkComp.HazePostEvent(StartSplineFishAudioEvent);
	
		// Hips are placed at spline, so head offset along the spline needs to be adjusted by that
		HeadOffsetAlongSpline = HeadOffsetAlongMesh - PoseTrail.GetBoneOffsetAlongMesh(n"Hips", Mesh);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FTransform CurrentSplineTransform = CurrentPosition.GetWorldTransform();

		FVector SplineLocation = CurrentSplineTransform.GetLocation();
		FRotator TargetRotation = CurrentSplineTransform.Rotator(); 
		CurrentRotation.AccelerateTo(TargetRotation, 0.f, DeltaTime);
		
		// We want hips at spline location, adjust root location accordingly
		FTransform HipsInActorSpace = Mesh.GetSocketTransform(n"Hips", ERelativeTransformSpace::RTS_Actor);
		FTransform RootPos = HipsInActorSpace.Inverse() * FTransform(CurrentRotation.Value, SplineLocation);
		SetActorLocationAndRotation(RootPos.Location, RootPos.Rotation);

		// Find rotation of spline at head and drop a pose trail point there
		float HeadDistanceAlongSpline = FMath::Fmod(CurrentPosition.DistanceAlongSpline + HeadOffsetAlongSpline, SplineToFollow.Spline.SplineLength);
		FTransform HeadPos = SplineToFollow.Spline.GetTransformAtDistanceAlongSpline(HeadDistanceAlongSpline, ESplineCoordinateSpace::World);
		
		float DistanceDelta = FMath::Abs(CurrentPosition.DistanceAlongSpline - LastDistanceAlongSpline);
		LastDistanceAlongSpline = CurrentPosition.DistanceAlongSpline;
		PoseTrail.AddTrailPoint(DistanceDelta, HeadPos.Rotation);

		// Note that we should always set actor location and rotation before calling this, or interpolations will be based on previous tick 
		PoseTrail.UpdatePose(FQuat(CurrentRotation.Value), DeltaTime);

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			PoseTrail.DrawDebugAlongSpline(SplineToFollow.Spline, HeadDistanceAlongSpline);
#endif
	}
}

class USnowGlobeSplineFishMovementComponent : UHazeSplineFollowComponent
{
	ASnowGlobeSplineFish FishOwner;

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Never disable
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FishOwner = Cast<ASnowGlobeSplineFish>(Owner);
		auto Spline = FishOwner.SplineToFollow.Spline;
		
		const float CurrentDistanceAlongSpline = Spline.GetDistanceAlongSplineAtWorldLocation(FishOwner.GetActorLocation());
		const FVector SplineDir = Spline.GetDirectionAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		const FVector WantedActorLocation = Spline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
		const bool bIsForwardOnSpline = SplineDir.DotProduct(FishOwner.GetActorForwardVector()) >= 0;
		FRotator Rot;
		if(bIsForwardOnSpline)
			Rot = SplineDir.Rotation();
		else
			Rot = (-SplineDir).Rotation();
		
		FishOwner.SetActorLocationAndRotation(WantedActorLocation, Rot);
		ActivateSplineMovement(Spline, bIsForwardOnSpline);
		FishOwner.CurrentRotation.SnapTo(FishOwner.GetActorRotation());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateSplineMovement(FishOwner.SpeedAlongSpline * DeltaSeconds, FishOwner.CurrentPosition);
		FishOwner.DisableComponentExtension.SetWorldLocation(FishOwner.CurrentPosition.GetWorldLocation());
	}
}
