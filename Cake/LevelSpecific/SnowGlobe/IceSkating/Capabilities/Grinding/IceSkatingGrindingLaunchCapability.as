import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingMagnetBoostGate;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Grinding.UserGrindComponent;

class UIceSkatingGrindingLaunchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 95;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UUserGrindComponent UserGrindComp;

	FIceSkatingAirSettings AirSettings;
	FIceSkatingGrindSettings GrindSettings;
	float LaunchTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
	        return EHazeNetworkActivation::DontActivate;

	    if (!SkateComp.bGrindJumpShouldBlockInput)
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.BecameGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (LaunchTimer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LaunchTimer = GrindSettings.LaunchDuration;
		SkateComp.bGrindJumpShouldBlockInput = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (MoveComp.BecameGrounded())
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_GrindLaunch");
		FrameMove.OverrideStepDownHeight(0.f);

		LaunchTimer -= DeltaTime;

		if (HasControl())
		{
			// Apply movement stuff!
			FVector Velocity = MoveComp.Velocity;
			Velocity += MoveComp.WorldUp * -AirSettings.Gravity * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);

			MoveCharacter(FrameMove, n"SkateInAir");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"MagnetGate", n"Launch");
		}
	}
}
