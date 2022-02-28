import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Vino.LevelSpecific.Snowglobe.SnowGlobeMagnetCommon;

class USnowGlobeMagnetSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USnowGlobeMagnetSplineComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USnowGlobeMagnetSplineComponent>(Component);
		if (Comp == nullptr)
			return;

		if (Comp.SplineActorToFollow == nullptr)
			return;

		auto Spline = UHazeSplineComponentBase::Get(Comp.SplineActorToFollow);
		if (Spline == nullptr)
			return;

		// Draw forward arrow
		DrawArrow(Comp.WorldLocation, Comp.WorldLocation + Comp.ForwardVector * 1200.f, FLinearColor::Red, 80.f, 20.f);

		// Draw spline
		FVector Offset = FVector::UpVector * 100.f;
		float StepSize = 20.f;
		int NumSteps = FMath::CeilToInt(Spline.SplineLength / StepSize);

		for(int i=0; i<NumSteps; ++i)
		{
			float Distance = FMath::Min(StepSize * i, Spline.SplineLength);
			float Distance_Next = FMath::Min(StepSize * (i + 1), Spline.SplineLength);

			FVector From = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
			FVector To = Spline.GetLocationAtDistanceAlongSpline(Distance_Next, ESplineCoordinateSpace::World);

			DrawLine(From + Offset, To + Offset, FLinearColor::Blue, 10.f);
		}

		// Draw spring location
		FVector SpringLocation = Spline.GetLocationAtDistanceAlongSpline(Comp.SpringDistance, ESplineCoordinateSpace::World);
		DrawWireDiamond(SpringLocation + Offset, FRotator(), 120.f, FLinearColor::Red);
	}
}

class USnowGlobeMagnetSplineComponent : USceneComponent
{
	TArray<UMagnetGenericComponent> InfluenceMagnets;

	UPROPERTY(Category = "Spline")
	FHazeConstrainedPhysicsValue Distance;

	UPROPERTY(Category = "Spline")
	AActor SplineActorToFollow = nullptr;
	UHazeSplineComponentBase SplineComp;

	// Either the constant force or gravity per 100 units of offset
	UPROPERTY(Category = "Physics")
	float MagnetForce = 400.f;

	UPROPERTY(Category = "Physics")
	float SpringForce = 200.f;

	UPROPERTY(Category = "Physics")
	ESnowGlobeMagnetRotatingSpringType SpringType = ESnowGlobeMagnetRotatingSpringType::Constant;

	UPROPERTY(Category = "Physics")
	ESnowGlobeMagnetForceType ForceType = ESnowGlobeMagnetForceType::ThreeDimensional;

	UPROPERTY(Category = "Physics")
	float SpringDistance = 0.f;

	UPROPERTY(Category = "Physics")
	bool bEnableSplineGravity = false;

	UPROPERTY(Category = "Physics")
	float SplineGravity = 120.f;

	UPROPERTY(Category = "Physics")
	bool bSleepingAffectsWholeActor = false;

	// Rumble strength when not moving.
	UPROPERTY(Category = "Feedback", Meta = (ClampMin = 0.0, ClampMax = 1.0))
	float MinVelocityRumble = 0.0f;

	// Rumble strength when moving at max velocity.
	UPROPERTY(Category = "Feedback", Meta = (ClampMin = 0.0, ClampMax = 1.0))
	float MaxVelocityRumble = 0.2f;

	// Rumble strength when hitting bounds.
	UPROPERTY(Category = "Feedback", Meta = (ClampMin = 0.0, ClampMax = 1.0))
	float BoundsRumbleStrength = 0.3f;

	// Rumble duration when hitting bounds.
	UPROPERTY(Category = "Feedback")
	float BoundsRumbleDuration = 0.2f;

	// Camera shake played when hitting bounds.
	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> BoundsCameraShake;

	UPROPERTY(Category = "Network")
	bool bShouldNetwork = true;

	UPROPERTY(Category = "Network")
	float SyncsPerSecond = 5.f;

	UPROPERTY(Category = "Network")
	float SyncingSpeed = 0.6f;

	UPROPERTY(Category = "Events")
	FOnMagnetHitUpperBound OnHitUpperBound;

	UPROPERTY(Category = "Events")
	FOnMagnetHitLowerBound OnHitLowerBound;

	UPROPERTY(Category = "Events")
	FOnMagnetPassedCenter OnPassedCenter;

	UPROPERTY(Category = "Events")
	FOnMagnetWakeUp OnWakeUp;

	UPROPERTY(Category = "Events")
	FOnMagnetSleep OnSleep;

	float SyncingTimer = 0.f;
	float OtherSideDistance = 0.f;

	bool bIsAwake = true;
	bool bIsDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> SceneComponents;
		GetChildrenComponents(true, SceneComponents);

		for(auto Component : SceneComponents)
		{
			// Ignore magnets that are attached to different actors...
			if (Component.Owner != Owner)
				continue;

			auto Magnet = Cast<UMagnetGenericComponent>(Component);
			if (Magnet != nullptr)
			{
				Magnet.OnActivatedBy.AddUFunction(this, n"HandleMagnetStateChanged");
				Magnet.OnDeactivatedBy.AddUFunction(this, n"HandleMagnetStateChanged");
				InfluenceMagnets.Add(Magnet);
			}
		}

		// If no actor is selected, try our owner by default
		if (SplineActorToFollow == nullptr)
			SplineActorToFollow = Owner;

		SplineComp = UHazeSplineComponentBase::Get(SplineActorToFollow);
		if (SplineComp == nullptr)
			return;

		SpringDistance = FMath::Clamp(SpringDistance, 0.f, SplineComp.SplineLength);

		Distance.LowerBound = 0.f;
		Distance.UpperBound = SplineComp.SplineLength;
		Distance.Value = SpringDistance;
		OtherSideDistance = SpringDistance;

		AttachToComponent(SplineComp);
		RelativeTransform = SplineComp.GetTransformAtDistanceAlongSpline(Distance.Value, ESplineCoordinateSpace::Local);

		Sleep();
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleMagnetStateChanged(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		// Wake up if any magnet state changes
		Wake();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float PrevValue = Distance.Value;
		float PrevVelocity = Distance.Velocity;

		float Force = 0.f;

		// Gather all forces for all magnets
		for(auto Magnet : InfluenceMagnets)
		{
			FVector MagnetOffset = Magnet.WorldLocation - WorldLocation;
			MagnetOffset.Normalize();

			FVector MagnetDirection = Magnet.GetDirectionalForceFromAllInfluencers();

			// Flatten for two dimensional
			if (ForceType == ESnowGlobeMagnetForceType::TwoDimensional)
			{
				MagnetDirection = MagnetDirection.ConstrainToPlane(UpVector);
				MagnetDirection.Normalize();
			}

			float ForwardForce = MagnetDirection.DotProduct(ForwardVector);

			// For one-dimensional, just take the sign of the force :) since we only care about backwards or forwards
			if (ForceType == ESnowGlobeMagnetForceType::OneDimensional)
			{
				ForwardForce = FMath::Sign(ForwardForce);
			}

			Force += ForwardForce * MagnetForce;
		}

		if (bEnableSplineGravity)
		{
			float GravityCoefficient = -ForwardVector.DotProduct(FVector::UpVector);
			Force += GravityCoefficient * SplineGravity;
		}

		// Update networking
		if (bShouldNetwork && Network::IsNetworked() && !FMath::IsNearlyZero(Distance.Velocity))
		{
			// We send over our distance a few times a second, so both sides know about the other sides' distance..
			if (SyncsPerSecond > SMALL_NUMBER)
			{
				SyncingTimer -= DeltaTime;
				if (SyncingTimer < 0.f)
				{
					NetSetOtherSideDistance(HasControl(), Distance.Value);
					SyncingTimer = 1.f / SyncsPerSecond;
				}
			}

			// Then we lerp towards it, so both sides with correct towards the other side
			// (this is outside of the physics-float, so we dont mess with any velocities and such)
			Distance.Value = FMath::FInterpTo(Distance.Value, OtherSideDistance, SyncingSpeed, DeltaTime);
		}

		Distance.AddAcceleration(Force);
		if (SpringType == ESnowGlobeMagnetRotatingSpringType::Constant)
			Distance.AccelerateTowards(SpringDistance, SpringForce);
		else
			Distance.SpringTowards(SpringDistance, SpringForce);

		Distance.Update(DeltaTime);

		// Events!
		if (Distance.HasHitUpperBound())
			OnHitUpperBound.Broadcast(PrevVelocity);

		if (Distance.HasHitLowerBound())
			OnHitLowerBound.Broadcast(PrevVelocity);

		// If the new value is a different sign than the old one, we passed the center-point
		if (FMath::Sign(PrevValue - SpringDistance) != FMath::Sign(Distance.Value - SpringDistance))
			OnPassedCenter.Broadcast(PrevVelocity);

		bool bHasInfluencingPlayers = false;
		for (auto Influencer : InfluenceMagnets)
		{
			if (Influencer.GetInfluencerNum() > 0)
			{
				bHasInfluencingPlayers = true;
				break;
			}
		}

		// Should we sleep?
		if (FMath::IsNearlyEqual(PrevVelocity, Distance.Velocity) &&
			FMath::IsNearlyEqual(PrevValue, Distance.Value) &&
			!bHasInfluencingPlayers)
			Sleep();

		RelativeTransform = SplineComp.GetTransformAtDistanceAlongSpline(Distance.Value, ESplineCoordinateSpace::Local);
	}

	UFUNCTION(NetFunction)
	void NetSetOtherSideDistance(bool bControlSide, float InDistance)
	{
		// We send in "HasControl()" when calling this function
		// So if this statement is true, we knew it came from this machine
		// And since we only care about the REMOTE distance, we discard this function call
		if (HasControl() == bControlSide)
			return;

		// Wake up if the other side is moving a lot
		if (!FMath::IsNearlyEqual(InDistance, Distance.Value))
			Wake();

		OtherSideDistance = InDistance;
	}

	UFUNCTION()
	void Desync_Bro()
	{
		if (HasControl())
			Distance.Value = Distance.LowerBound;
		else
			Distance.Value = Distance.UpperBound;
	}

	void Sleep()
	{
		if (bIsAwake)
			OnSleep.Broadcast();

		bIsAwake = false;
		SetComponentTickEnabled(false);

		if (bSleepingAffectsWholeActor)
			Owner.SetActorTickEnabled(false);
	}

	void Wake()
	{
		// Never wake up if disabled
		if (bIsDisabled)
			return;

		if (!bIsAwake)
			OnWakeUp.Broadcast();

		bIsAwake = true;
		SetComponentTickEnabled(true);

		if (bSleepingAffectsWholeActor)
			Owner.SetActorTickEnabled(true);
	}

	UFUNCTION()
	void SnapToAndDisable(float InDistance)
	{
		// Ensures we can't wake up the component again
		bIsDisabled = true;

		// Move actor to specified distance on spline
		Distance.SnapTo(InDistance, true);
		RelativeTransform = SplineComp.GetTransformAtDistanceAlongSpline(Distance.Value, ESplineCoordinateSpace::Local);

		// Disable magnets
		for (int i = 0; i < InfluenceMagnets.Num(); ++i)
			InfluenceMagnets[i].bIsDisabled = true;

		// Make sure we're sleeping
		Sleep();
	}

	UFUNCTION(NetFunction)
	void NetSnapToAndDisable(float InDistance)
	{
		SnapToAndDisable(InDistance);
	}
}