import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.LevelSpecific.Snowglobe.SnowGlobeMagnetSplineComponent;
import Vino.LevelSpecific.Snowglobe.SnowGlobeMagnetRotatingComponent;

struct FMagnetComponentData
{
	FHazeConstrainedPhysicsValue PhysicsValue;
	float MaxForce;
	float Friction;
	float MinVelocityRumble;
	float MaxVelocityRumble;
	float BoundsRumbleDuration;
	float BoundsRumbleStrength;
	TSubclassOf<UCameraShakeBase> BoundsCameraShake;
}

class DefaultMagnetForceFeedbackCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
	default CapabilityTags.Add(FMagneticTags::DefaultMagnetForceFeedbackCapability);
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;

	UMagnetGenericComponent TargetMagnet;
	USnowGlobeMagnetSplineComponent TargetSplineComp;
	USnowGlobeMagnetRotatingComponent TargetRotatingComp;
	FMagnetComponentData PreviousData;
	UCameraShakeBase CameraShakeInstance;
	float BoundsRumbleTimer = 0.f;
	float FeedbackStrength = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		UMagnetGenericComponent Magnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.GetActivatedMagnet());
		
		if (Magnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!Magnet.IsInfluencedBy(Player))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (TargetMagnet.bIsDisabled)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Prevent Players from standing on top of the magnets owning actor and using it
		if (TargetMagnet.IsBlockedByStandingPlayer(Player))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Deactivate when player steps out of range
		float DistanceToMagnet = PlayerMagnetComp.WorldLocation.Distance(TargetMagnet.WorldLocation);
		if (DistanceToMagnet > TargetMagnet.DeactivationDistance)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Check Generic Magnet Settings
		if( TargetMagnet.GenericMagnetSettings != nullptr)
		{
			if (TargetMagnet.GenericMagnetSettings.bDeactivateWhenDistanceIsLongerThanCustomDistance)
			{
				if (DistanceToMagnet > TargetMagnet.GenericMagnetSettings.CustomDistance)
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
			if(TargetMagnet.GenericMagnetSettings.bOnlyBlockSamePolarityWhenInfluencing)
			{
				if (!PlayerMagnetComp.HasOppositePolarity(TargetMagnet) && TargetMagnet.IsMagneticPathBlocked(PlayerMagnetComp, TargetMagnet.GenericMagnetSettings.bIgnoreSelf))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
			else if (TargetMagnet.GenericMagnetSettings.bDoExtraVisibilityCheckToBlockParents)
			{
				if (TargetMagnet.IsMagneticPathBlocked(PlayerMagnetComp, TargetMagnet.GenericMagnetSettings.bIgnoreSelf))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
			if (TargetMagnet.GenericMagnetSettings.bCheckFreeSightWhenInfluencing)
			{
				if (!TargetMagnet.HasFreeSight(Player))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
		}
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UMagnetGenericComponent Generic = Cast<UMagnetGenericComponent>(PlayerMagnetComp.ActivatedMagnet);
		USnowGlobeMagnetSplineComponent Spline = USnowGlobeMagnetSplineComponent::Get(Generic.Owner);
		USnowGlobeMagnetRotatingComponent Rotating = USnowGlobeMagnetRotatingComponent::Get(Generic.Owner);

		ActivationParams.AddObject(n"GenericMagnet", Generic);
		ActivationParams.AddObject(n"SplineComponent", Spline);
		ActivationParams.AddObject(n"RotatingComponent", Rotating);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetMagnet = Cast<UMagnetGenericComponent>(ActivationParams.GetObject(n"GenericMagnet"));
		TargetSplineComp = Cast<USnowGlobeMagnetSplineComponent>(ActivationParams.GetObject(n"SplineComponent"));
		TargetRotatingComp = Cast<USnowGlobeMagnetRotatingComponent>(ActivationParams.GetObject(n"RotatingComponent"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BoundsRumbleTimer = 0.f;

		if (CameraShakeInstance != nullptr)
			Player.StopCameraShake(CameraShakeInstance);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsMagnetGeneric())
		{
			Player.SetFrameForceFeedback(TargetMagnet.GenericForceFeedbackStrength, TargetMagnet.GenericForceFeedbackStrength);
			return;
		}

		// Spline & rotating magnet components contain mostly the same stuff
		// but don't share a base class
		FMagnetComponentData ComponentData;
		if (TargetSplineComp != nullptr) 
			GetMagnetComponentData(TargetSplineComp, ComponentData);
		if (TargetRotatingComp != nullptr) 
			GetMagnetComponentData(TargetRotatingComp, ComponentData);

		// Can't scale, fallback to generic rumble
		if (ComponentData.MaxForce == 0.f)
		{
			Player.SetFrameForceFeedback(TargetMagnet.GenericForceFeedbackStrength, TargetMagnet.GenericForceFeedbackStrength);
			return;
		}

		// Check if there's any signifact movement
		bool bIsMoving = !FMath::IsNearlyEqual(PreviousData.PhysicsValue.Velocity, ComponentData.PhysicsValue.Velocity) &&
			!FMath::IsNearlyEqual(PreviousData.PhysicsValue.Value, ComponentData.PhysicsValue.Value);
		
		// Start timer if we hit either bound while moving
		if (bIsMoving && (ComponentData.PhysicsValue.HasHitUpperBound() || ComponentData.PhysicsValue.HasHitLowerBound()))
			BoundsRumbleTimer = ComponentData.BoundsRumbleDuration;

		if (BoundsRumbleTimer < 0.f)
		{
			// Make sure we stop shaking the camera
			if (CameraShakeInstance != nullptr)
			{
				Player.StopCameraShake(CameraShakeInstance);
				CameraShakeInstance = nullptr;
			}

			if (DeltaTime != 0.f && bIsMoving)
			{
				float Acceleration = (ComponentData.PhysicsValue.Velocity - PreviousData.PhysicsValue.Velocity) / DeltaTime;

				float TargetStrength = FMath::Clamp(FMath::Abs(Acceleration / ComponentData.MaxForce), 0.f, 1.f); 
				FeedbackStrength = FMath::FInterpConstantTo(FeedbackStrength, TargetStrength, DeltaTime, 5.f);

				float Rumble = FMath::Lerp(ComponentData.MinVelocityRumble, ComponentData.MaxVelocityRumble, FeedbackStrength);

				Player.SetFrameForceFeedback(Rumble, Rumble);
			}
		}
		else
		{
			// Constant rumble over duration after hitting bounds
			BoundsRumbleTimer -= DeltaTime;
			
			CameraShakeInstance = Player.PlayCameraShake(ComponentData.BoundsCameraShake);
			Player.SetFrameForceFeedback(ComponentData.BoundsRumbleStrength, ComponentData.BoundsRumbleStrength);
		}

		PreviousData = ComponentData;
	}

	bool IsMagnetGeneric()
	{
		return TargetSplineComp == nullptr && TargetRotatingComp == nullptr;
	}

	void GetMagnetComponentData(USnowGlobeMagnetSplineComponent SplineComp, FMagnetComponentData& ComponentData)
	{
		if (SplineComp == nullptr)
			return;

		ComponentData.PhysicsValue = SplineComp.Distance;
		ComponentData.MaxForce = (SplineComp.MagnetForce - SplineComp.SpringForce);
		ComponentData.MinVelocityRumble = SplineComp.MinVelocityRumble;
		ComponentData.MaxVelocityRumble = SplineComp.MaxVelocityRumble;
		ComponentData.BoundsRumbleDuration = SplineComp.BoundsRumbleDuration;
		ComponentData.BoundsRumbleStrength = SplineComp.BoundsRumbleStrength;
		ComponentData.BoundsCameraShake = SplineComp.BoundsCameraShake;

		if (SplineComp.Distance.Friction != 0.f)
			ComponentData.MaxForce /= SplineComp.Distance.Friction;
	}

	void GetMagnetComponentData(USnowGlobeMagnetRotatingComponent RotatingComp, FMagnetComponentData& ComponentData)
	{
		if (RotatingComp == nullptr)
			return;

		ComponentData.PhysicsValue = RotatingComp.Rotation;
		ComponentData.MaxForce = (RotatingComp.MagnetForce - RotatingComp.SpringForce);
		ComponentData.MinVelocityRumble = RotatingComp.MinVelocityRumble;
		ComponentData.MaxVelocityRumble = RotatingComp.MaxVelocityRumble;
		ComponentData.BoundsRumbleDuration = RotatingComp.BoundsRumbleDuration;
		ComponentData.BoundsRumbleStrength = RotatingComp.BoundsRumbleStrength;
		ComponentData.BoundsCameraShake = RotatingComp.BoundsCameraShake;

		if (RotatingComp.Rotation.Friction != 0.f)
			ComponentData.MaxForce /= RotatingComp.Rotation.Friction;
	}
}