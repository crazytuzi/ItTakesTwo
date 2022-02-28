import Cake.LevelSpecific.Tree.DarkRoom.FireflySwarm;

class UFireflyLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UFireflyFlightComponent FlightComp;
	AFireflySwarm CurrentSwarm;
	
	float HorizontalDrag = 1.3f;
	float CatchDrag = 0.5f;
	float LaunchDrag = 1.4f;
	float HoldTime = 0.5f;
	float HoldDuration = 0.2f;

	float LaunchImpulse;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FlightComp.OverlappingSwarms.Num() == 0)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::MovementJump))
			return EHazeNetworkActivation::DontActivate;
		
        return EHazeNetworkActivation::ActivateUsingCrumb;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlightComp.OverlappingSwarms.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Swarm", FlightComp.OverlappingSwarms[0]);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"FireflyCatch", this);
		HoldTime = 0.f;
		FlightComp.bIsLaunching = true;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		Player.ApplyCameraSettings(FlightComp.CameraSettings, Blend, this);

		CurrentSwarm = Cast<AFireflySwarm>(ActivationParams.GetObject(n"Swarm"));
		CurrentSwarm.OnStartLaunching();
		LaunchImpulse = CurrentSwarm.Strength;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FVector LaunchDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		LaunchDirection.Z = 8.f;
		LaunchDirection.Normalize();

		Player.UnblockCapabilities(n"FireflyCatch", this);
		FlightComp.bIsLaunching = false;
		FlightComp.Velocity = LaunchDirection * LaunchImpulse;

		Player.ClearCameraSettingsByInstigator(this, 3.f);

		if (CurrentSwarm != nullptr)
		{
			CurrentSwarm.OnStopLaunching();
			FlightComp.OnLaunch(CurrentSwarm.bShouldPlayVO);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		float InterpSpeed = FlightComp.AttachedFireflies < FlightComp.TargetAttachedFireflies ? 10.f : 1.f;
		FlightComp.AttachedFireflies = FMath::FInterpConstantTo(FlightComp.AttachedFireflies, FlightComp.TargetAttachedFireflies, DeltaTime, InterpSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			HoldTime += DeltaTime;
			float AccelerationFactor = Math::Saturate(HoldTime / HoldDuration);
			float LaunchForce = CurrentSwarm.Strength;

			FlightComp.Velocity += FVector::UpVector * LaunchForce * AccelerationFactor * DeltaTime;

			if (FlightComp.Velocity.Z < 0.f)
			{
				FlightComp.Velocity.Z -= FlightComp.Velocity.Z * CatchDrag * DeltaTime;
			}
			else
			{
				FlightComp.Velocity.Z -= FlightComp.Velocity.Z * LaunchDrag * DeltaTime;
			}

			//Horizontal drag
			FVector HorizontalVelocity = FlightComp.Velocity.ConstrainToPlane(FVector::UpVector);
			FlightComp.Velocity -= HorizontalVelocity * HorizontalDrag * DeltaTime;
		}
	}
	
}