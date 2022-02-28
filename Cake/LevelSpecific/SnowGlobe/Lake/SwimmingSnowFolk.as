import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;

class ASwimmingSnowFolk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.bEnableUpdateRateOptimizations = true;
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
	
	UPROPERTY(DefaultComponent, Category = "Snowfolk")
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent, Attach = VisualRange)
	USnowGlobeLakeDisableComponentExtension DisableExtension;
	default DisableExtension.ActiveType = ESnowGlobeLakeDisableType::ActiveUnderSurfaceInWater;
	default DisableExtension.DontDisableWhileVisibleTime = 1.f;
	default DisableExtension.TickDelay = 0.f;
	default DisableExtension.DisableRange = FHazeMinMax(2000, 25000.f); 

	UPROPERTY(Category = "Snowfolk")
	USkeletalMesh SnowFolkMesh;

	UPROPERTY(Category = "Snowfolk")
	FHazePlaySlotAnimationParams SwimmingAnimation;
	default SwimmingAnimation.bLoop = true;
	default SwimmingAnimation.BlendTime = 0.3f;

	// NOTE: Only for the temporary swimming animation
	UPROPERTY(Category = "Snowfolk")
	bool bFlipMesh = true;
	
	UPROPERTY(Category = "Snowfolk")
	AActor SplineActor;

	UPROPERTY(Category = "Snowfolk")
	float Speed = 750.f;

	UPROPERTY(Category = "Snowfolk")
	float MaxSpeed = 1200.f;

	// Speed at which the mesh offset is interpolated when avoiding.
	UPROPERTY(Category = "Snowfolk")
	float MeshOffsetInterpSpeed = 3.f;

	UPROPERTY(Category = "Snowfolk")
	float AvoidanceRadius = 350.f;
	
	// Whether to add speed when a player is within the avoidance radius. 
	UPROPERTY(Category = "Snowfolk")
	bool bUseAvoidanceBoost = true;

	UHazeSplineComponent TargetSpline;
	float SplineAlpha;
	float CurrentSpeed;
	FVector MeshOffset;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetSkeletalMesh(SnowFolkMesh);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentSpeed = Speed;

		// NOTE: Only for the temporary swimming animation
		if (bFlipMesh)
			Mesh.RelativeRotation = FRotator(180.f, 0.f, 0.f);

		if (SplineActor != nullptr)
			TargetSpline = UHazeSplineComponent::Get(SplineActor);

		if (TargetSpline != nullptr)
			SplineAlpha = TargetSpline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);

		if (SwimmingAnimation.Animation != nullptr)
			PlaySlotAnimation(SwimmingAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		SplineAlpha = Math::FWrap(SplineAlpha + CurrentSpeed * DeltaTime, 0.f, TargetSpline.GetSplineLength());

		FTransform TargetTransform = TargetSpline.GetTransformAtDistanceAlongSpline(SplineAlpha, ESplineCoordinateSpace::World);
		SetActorLocationAndRotation(TargetTransform.Location, TargetTransform.Rotation);

		// Offset the mesh from the actor location
		Mesh.WorldLocation = FMath::VInterpTo(Mesh.WorldLocation, ActorLocation + MeshOffset, DeltaTime, MeshOffsetInterpSpeed);

		float RadiusSqr = FMath::Square(AvoidanceRadius);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector FromPlayer = (ActorLocation - Player.ActorLocation);
			float DistanceSqr = FromPlayer.SizeSquared();

			if (DistanceSqr <= RadiusSqr && RadiusSqr != 0.f)
			{
				float OffsetAlpha = 1.f - FMath::Clamp(FMath::Pow(DistanceSqr / RadiusSqr, 1.5f), 0.f, 1.f);
				float OffsetDistance = FMath::Lerp(0.f, AvoidanceRadius, OffsetAlpha);

				// Offset the mesh to the opposite end of the player within the avoidance sphere
				MeshOffset = FromPlayer.GetSafeNormal() * OffsetDistance;

				// Move away a bit faster
				if (bUseAvoidanceBoost)
					CurrentSpeed += OffsetDistance;
			}
		}

		CurrentSpeed = FMath::Clamp(FMath::FInterpTo(CurrentSpeed, Speed, DeltaTime, 5.f), -MaxSpeed, MaxSpeed);
	}
}