import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Vino.LevelSpecific.Snowglobe.SnowGlobeMagnetCommon;

class USnowGlobeMagnetRotatingComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USnowGlobeMagnetRotatingComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USnowGlobeMagnetRotatingComponent>(Component);
		if (Comp == nullptr)
			return;

		FVector RotationAxis = Comp.LocalRotationAxis;
		RotationAxis.Normalize();

		FQuat CompRotation = Comp.ComponentQuat;
		float MinRad = FMath::DegreesToRadians(Comp.Rotation.LowerBound);
		float MidRad = FMath::DegreesToRadians(0.f);
		float MaxRad = FMath::DegreesToRadians(Comp.Rotation.UpperBound);

		FQuat MinRotation = CompRotation * FQuat(RotationAxis, MinRad);
		FQuat MidRotation = CompRotation * FQuat(RotationAxis, MidRad);
		FQuat MaxRotation = CompRotation * FQuat(RotationAxis, MaxRad);

		FVector Loc = Comp.WorldLocation;
		DrawLine(Loc, Loc + MidRotation.ForwardVector * 900.f, FLinearColor::Yellow, 5.f);
		DrawLine(Loc, Loc + (CompRotation * RotationAxis) * 900.f , FLinearColor::Blue, 5.f);

		if (Comp.Rotation.bHasLowerBound)
		{
			DrawLine(Loc, Loc + MinRotation.ForwardVector * 900.f, FLinearColor::Green, 5.f);
			DrawRotationPlane(Loc, RotationAxis, CompRotation, MinRad, MidRad, FLinearColor::Yellow);
		}
		if (Comp.Rotation.bHasUpperBound)
		{
			DrawLine(Loc, Loc + MaxRotation.ForwardVector * 900.f, FLinearColor::Red, 5.f);
			DrawRotationPlane(Loc, RotationAxis, CompRotation, MidRad, MaxRad, FLinearColor::Yellow);
		}
	}

	void DrawRotationPlane(FVector Loc, FVector RotationAxis, FQuat Origin, float From, float To, FLinearColor Color)
	{
		int NumSegments = 20;
		float Circumference = (250.f + 20.f * NumSegments) * FMath::Abs(To - From);
		int NumSteps = FMath::CeilToInt(Circumference / 50.f);

		// Draw a bunch of lines to visualize the rotation plane
		for(int i=0; i<NumSegments; ++i)
		{
			float Distance = 250.f + 20.f * i;

			for(int j=0; j<NumSteps; ++j)
			{
				if (j % 2 == 1)
					continue;

				float AlphaStep = (1.f / NumSteps);

				float FirstAlpha = AlphaStep * j;
				float SecondAlpha = AlphaStep * (j + 1);

				FQuat FirstRot = Origin * FQuat(RotationAxis, FMath::Lerp(From, To, FirstAlpha));
				FQuat SecondRot = Origin * FQuat(RotationAxis, FMath::Lerp(From, To, SecondAlpha));

				DrawLine(Loc + FirstRot.ForwardVector * Distance, Loc + SecondRot.ForwardVector * Distance, Color);
			} 
		}
	}
}

class USnowGlobeMagnetRotatingComponent : USceneComponent
{
	TArray<UMagnetGenericComponent> InfluenceMagnets;

	UPROPERTY(Category = "Rotation")
	FVector LocalRotationAxis = FVector(0.f, 0.f, 1.f);

	UPROPERTY(Category = "Rotation")
	FHazeConstrainedPhysicsValue Rotation;
	default Rotation.LowerBound = -90.f;
	default Rotation.UpperBound = 90.f;

	UPROPERTY(Category = "Rotation")
	bool bWrapAngle = false;

	FQuat OriginRotation;

	// Either the constant force or gravity per 100 units of offset
	UPROPERTY(Category = "Physics")
	float MagnetForce = 400.f;

	UPROPERTY(Category = "Physics")
	float SpringForce = 200.f;

	UPROPERTY(Category = "Physics")
	float TargetRotation = 0.f;

	UPROPERTY(Category = "Physics")
	float MagnetInitialImpulse_Red = 0.f;

	UPROPERTY(Category = "Physics")
	float MagnetInitialImpulse_Blue = 0.f;

	UPROPERTY(Category = "Physics")
	ESnowGlobeMagnetRotatingSpringType SpringType = ESnowGlobeMagnetRotatingSpringType::Constant;

	UPROPERTY(Category = "Physics")
	ESnowGlobeMagnetForceType ForceType = ESnowGlobeMagnetForceType::ThreeDimensional;

	UPROPERTY(Category = "Physics")
	bool bSleepingAffectsWholeActor = false;

	UPROPERTY(Category = "Linking")
	TArray<AHazeActor> SlaveRotatingActors;
	TArray<USnowGlobeMagnetRotatingComponent> SlaveRotatingComps;

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

	// Mumble mumble parallel universes.....
	float SyncingTimer = 0.f;
	float OtherSideRotation = 0.f;

	bool bIsAwake = true;
	bool bIsDisabled = false;
	bool bIsSlave = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddMagnetsAttachedTo(this);

		for(auto SlaveActor : SlaveRotatingActors)
		{
			auto RotatingComponent = USnowGlobeMagnetRotatingComponent::Get(SlaveActor);
			if (RotatingComponent == nullptr)
				continue;

			SlaveRotatingComps.Add(RotatingComponent);
			RotatingComponent.bIsSlave = true;
			AddMagnetsAttachedTo(RotatingComponent);
		}

		OriginRotation = RelativeTransform.Rotation;
		Sleep();
	}

	void AddMagnetsAttachedTo(USceneComponent Base)
	{
		TArray<USceneComponent> SceneComponents;
		Base.GetChildrenComponents(true, SceneComponents);

		for(auto Component : SceneComponents)
		{
			// Ignore components that are attached to a different actor
			if (Component.Owner != Base.Owner)
				continue;

			auto Magnet = Cast<UMagnetGenericComponent>(Component);
			if (Magnet != nullptr)
			{
				Magnet.OnActivatedBy.AddUFunction(this, n"HandleMagnetActivated");
				Magnet.OnDeactivatedBy.AddUFunction(this, n"HandleMagnetDeactivated");

				// HACK: Only add to the InfluenceMagnet if this Magnet is attached to the 'this' actor.
				// Which means, dont add magnets of slave actors to the list. They will be calculated individually.
				if (Base.Owner == Owner)
					InfluenceMagnets.Add(Magnet);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleMagnetActivated(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		// Wake up if any magnet state changes
		Wake();

		auto PlayerMagnet = UMagneticComponent::Get(Player);
		float ImpulseForce = PlayerMagnet.Polarity == EMagnetPolarity::Minus_Blue ? MagnetInitialImpulse_Blue : MagnetInitialImpulse_Red;

		if (Point.IsActivatedBy(Player) && !FMath::IsNearlyZero(ImpulseForce))
		{
			auto Magnet = Cast<UMagnetGenericComponent>(Point);
			float PolaritySign = Magnet.HasOppositePolarity(PlayerMagnet) ? -1.f : 1.f;

			FVector ForceDirection = (Point.WorldLocation - PlayerMagnet.WorldLocation) * PolaritySign;
			ForceDirection.Normalize();

			Rotation.AddImpulse(CalculateMagnetAngularForce(Magnet, ForceDirection * ImpulseForce));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleMagnetDeactivated(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		Wake();
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		Sleep();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Wake();
	}

	float CalculateMagnetAngularForce(UMagnetGenericComponent Magnet, FVector Force)
	{
		// Calculate the rotation force 
		FVector WorldRotationAxis = WorldTransform.TransformVector(LocalRotationAxis);
		WorldRotationAxis.Normalize();

		float ForceMagnitude = 0.f;
		FVector ForceDirection;

		Force.ToDirectionAndLength(ForceDirection, ForceMagnitude);

		FVector MagnetOffset = Magnet.WorldLocation - WorldLocation;
		MagnetOffset = MagnetOffset.ConstrainToPlane(WorldRotationAxis);
		MagnetOffset.Normalize();
		FVector ConstrainedForceDirection = ForceDirection.ConstrainToPlane(WorldRotationAxis);

		// Flatten for two dimensional
		if (ForceType == ESnowGlobeMagnetForceType::TwoDimensional)
		{
			ConstrainedForceDirection.Normalize();
		}

		// The rotational force is calculated from the angle between the magnet offset and attraction direction
		FVector RotationCross = MagnetOffset.CrossProduct(ConstrainedForceDirection);
		float AngularForce = RotationCross.DotProduct(WorldRotationAxis);

		// For one-dimensional, just take the sign of the force :) since we only care about backwards or forwards
		if (ForceType == ESnowGlobeMagnetForceType::OneDimensional)
		{
			AngularForce = FMath::Sign(AngularForce);
		}

		return AngularForce * ForceMagnitude;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float PrevValue = Rotation.Value;
		float PrevVelocity = Rotation.Velocity;

		float Force = 0.f;

		// Gather all forces for all influences
		for(auto Magnet : InfluenceMagnets)
		{
			FVector MagnetDirection = Magnet.GetDirectionalForceFromAllInfluencers();
			MagnetDirection.Normalize();

			Force += CalculateMagnetAngularForce(Magnet, MagnetDirection * MagnetForce);
		}

		// Gather all forces from all SLAVE magnet influencers
		for(auto Slave : SlaveRotatingComps)
		{
			for(auto Magnet : Slave.InfluenceMagnets)
			{
				FVector MagnetDirection = Magnet.GetDirectionalForceFromAllInfluencers();
				MagnetDirection.Normalize();

				Force += Slave.CalculateMagnetAngularForce(Magnet, MagnetDirection * MagnetForce);
			}
		}

		// Update networking
		if (bShouldNetwork && Network::IsNetworked())
		{
			// We send over our rotation a few times a second, so both sides know about the other sides' distance..
			if (SyncsPerSecond > SMALL_NUMBER)
			{
				SyncingTimer -= DeltaTime;
				if (SyncingTimer < 0.f)
				{
					float ValueToSync = Rotation.Value;
					if (FMath::Abs(ValueToSync) < 2.f)
						ValueToSync = 0.f;

					NetSetOtherSideRotation(HasControl(), ValueToSync);
					SyncingTimer = 1.f / SyncsPerSecond;
				}
			}

			// Then we lerp towards it, so both sides with correct towards the other side
			// (this is outside of the physics-float, so we dont mess with any velocities and such)
			if (bWrapAngle)
			{
				// If we're wrapping the angle, don't take the _literal_ route, since it might have wrapped recently
				// Take the closest route instead
				// NOTE: With bounds this will look _BAD_
				Rotation.Value = Math::LerpAngle(Rotation.Value, OtherSideRotation, SyncingSpeed * DeltaTime);
			}
			else
			{
				Rotation.Value = FMath::FInterpTo(Rotation.Value, OtherSideRotation, SyncingSpeed, DeltaTime);
			}
		}

		// Where to accelerate towards,
		// If we're wrapping the angle, find the closest 360 degree resting spot, instead
		// of always accelerating towards 0
		float ClampedTargetRotation = TargetRotation;
		if (bWrapAngle)
			ClampedTargetRotation = FMath::RoundToInt((Rotation.Value - TargetRotation)/ 360.f) * 360.f + TargetRotation;

		Rotation.AddAcceleration(Force);
		if (SpringType == ESnowGlobeMagnetRotatingSpringType::Constant)
		{
			Rotation.AccelerateTowards(ClampedTargetRotation, SpringForce);
		}
		else
		{
			// For rotating-components, gravity is based on the angle
			// 0 is fully resting, 90 is maximum gravity, and then 180 is unstable resting (straight up)
			float GravityFactor = FMath::Abs(FMath::Sin(FMath::DegreesToRadians(Rotation.Value)));
			Rotation.AccelerateTowards(ClampedTargetRotation, GravityFactor * SpringForce);
		}

		Rotation.Update(DeltaTime);

		// Events!
		if (Rotation.HasHitUpperBound())
		{
			OnHitUpperBound.Broadcast(PrevVelocity);
			for(auto Slave : SlaveRotatingComps)
				Slave.OnHitUpperBound.Broadcast(PrevVelocity);
		}

		if (Rotation.HasHitLowerBound())
		{
			OnHitLowerBound.Broadcast(PrevVelocity);
			for(auto Slave : SlaveRotatingComps)
				Slave.OnHitLowerBound.Broadcast(PrevVelocity);
		}

		// If the new value is a different sign than the old one, we passed the center-point
		if (FMath::Sign(PrevValue) != FMath::Sign(Rotation.Value))
		{
			OnPassedCenter.Broadcast(PrevVelocity);
			for(auto Slave : SlaveRotatingComps)
				Slave.OnPassedCenter.Broadcast(PrevVelocity);
		}

		// Should we sleep?
		bool bHaveInfluencers = false;
		for(auto Magnet : InfluenceMagnets)
		{
			if (Magnet.InfluencerNum > 0)
			{
				bHaveInfluencers = true;
				break;
			}
		}

		if (FMath::IsNearlyEqual(PrevVelocity, Rotation.Velocity) &&
			FMath::IsNearlyZero(Rotation.Velocity) &&
			FMath::IsNearlyEqual(PrevValue, Rotation.Value) &&
			!bHaveInfluencers)
			Sleep();

		{
			FQuat RotationOffset = FQuat(LocalRotationAxis, FMath::DegreesToRadians(Rotation.Value));
			SetRelativeRotation(OriginRotation * RotationOffset);
		}

		// Update slaves
		for(auto Slave : SlaveRotatingComps)
		{
			FQuat RotationOffset = FQuat(Slave.LocalRotationAxis, FMath::DegreesToRadians(Rotation.Value));
			Slave.SetRelativeRotation(Slave.OriginRotation * RotationOffset);
			Slave.Rotation = Rotation;
		}
	}

	UFUNCTION(NetFunction)
	void NetSetOtherSideRotation(bool bControlSide, float InRotation)
	{
		// We send in "HasControl()" when calling this function
		// So if this statement is true, we knew it came from this machine
		// And since we only care about the REMOTE distance, we discard this function call
		if (HasControl() == bControlSide)
			return;

		// Wake up if the other side is moving a lot
		if (!FMath::IsNearlyEqual(InRotation, Rotation.Value, 0.5f))
			Wake();

		OtherSideRotation = InRotation;
	}

	void Sleep()
	{
		if (!bIsAwake)
			return;

		bIsAwake = false;
		OnSleep.Broadcast();
		for(auto Slave : SlaveRotatingComps)
			Slave.OnSleep.Broadcast();

		SetComponentTickEnabled(false);

		if (bSleepingAffectsWholeActor)
			Owner.SetActorTickEnabled(false);

		NetSetOtherSideRotation(HasControl(), Rotation.Value);
	}

	void Wake()
	{
		// Never wake up if disabled
		if (bIsDisabled)
			return;

		// Never wake up if actor is disabled
		auto HazeOwner = Cast<AHazeActor>(Owner);
		if (HazeOwner != nullptr && HazeOwner.IsActorDisabled())
			return;

		// Never wake up if sla- that sounds dark
		if (bIsSlave)
			return;

		if (bIsAwake)
			return;

		bIsAwake = true;

		// Dont do anything if the actor is disabled, delay it until the actor is re-enabled
		OnWakeUp.Broadcast();
		for(auto Slave : SlaveRotatingComps)
			Slave.OnWakeUp.Broadcast();

		SetComponentTickEnabled(true);
		if (bSleepingAffectsWholeActor)
			Owner.SetActorTickEnabled(true);
	}

	UFUNCTION()
	void SnapToAndDisable(float InRotation)
	{
		// Ensures we can't wake up the component again
		bIsDisabled = true;

		// Rotate the actor
		Rotation.SnapTo(InRotation, true);
		FQuat RotationOffset = FQuat(LocalRotationAxis, FMath::DegreesToRadians(Rotation.Value));
		SetRelativeRotation(OriginRotation * RotationOffset);

		// Disable magnets
		for (int i = 0; i < InfluenceMagnets.Num(); ++i)
			InfluenceMagnets[i].bIsDisabled = true;

		// Make sure we're sleeping
		Sleep();
	}

	UFUNCTION(NetFunction)
	void NetSnapToAndDisable(float InRotation)
	{
		SnapToAndDisable(InRotation);
	}

	UFUNCTION()
	void AddRotationAcceleration(float Force)
	{
		Rotation.AddAcceleration(Force);
		Wake();
	}

	UFUNCTION()
	void AddRotationImpulse(float Impulse)
	{
		Rotation.AddImpulse(Impulse);
		Wake();
	}
}