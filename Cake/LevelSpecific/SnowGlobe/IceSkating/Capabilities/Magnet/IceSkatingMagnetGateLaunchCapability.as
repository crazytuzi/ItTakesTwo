import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingMagnetBoostGate;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingMagnetGateLaunchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 95;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent SkateCamComp;

	FIceSkatingMagnetSettings MagnetSettings;
	FIceSkatingAirSettings AirSettings;

	float LaunchTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		SkateCamComp = UIceSkatingCameraComponent::GetOrCreate(Player);
	}

	bool HasPassedGate() const
	{
		if (SkateComp.ActiveBoostGate == nullptr)
			return false;

		FVector ToGate = SkateComp.ActiveBoostGate.ImpulseLocation - Player.ActorLocation;
		return ToGate.DotProduct(SkateComp.ActiveBoostGate.ImpulseForward) < 0.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!HasPassedGate())
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
		auto Gate = SkateComp.ActiveBoostGate;

		LaunchTimer = MagnetSettings.GateLaunchDuration;
		MoveComp.Velocity = Gate.ImpulseForward * Gate.ExitSpeed;

		Gate.OnLaunched.Broadcast(Player);
		Player.PlayForceFeedback(SkateComp.MagnetGateFeedbackEffect, false, true, n"IceSkatingGateLaunch");
		SkateComp.CallOnMagnetGateBoost(Gate);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);

		if (MoveComp.BecameGrounded())
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_GateBoost");
		FrameMove.OverrideStepDownHeight(0.f);

		LaunchTimer -= DeltaTime;

		if (HasControl())
		{
			// Apply movement stuff!
			FVector Velocity = MoveComp.Velocity;
			Velocity += MoveComp.WorldUp * -AirSettings.Gravity * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);

			MoveCharacter(FrameMove, n"MagnetGate", n"Launch");
			CrumbComp.LeaveMovementCrumb();

			// Apply camera stuff!
			float ProgressPercent = LaunchTimer / MagnetSettings.GateLaunchDuration;
			Player.ApplyFieldOfView(MagnetSettings.GateLaunchFov * ProgressPercent, CameraBlend::Additive(0.05f), this);

			FHazeCameraSpringArmSettings SpringArmSettings;
			SpringArmSettings.bUseIdealDistance = true;
			SpringArmSettings.IdealDistance = MagnetSettings.GateLaunchZoom;
			SpringArmSettings.bUsePivotOffset = true;
			SpringArmSettings.PivotOffset = FVector::ZeroVector;
			SpringArmSettings.bUseCameraOffsetOwnerSpace = true;
			SpringArmSettings.CameraOffsetOwnerSpace = FVector::ZeroVector;

			Player.ApplyCameraSpringArmSettings(SpringArmSettings, CameraBlend::ManualFraction(ProgressPercent, 0.8f), this);
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
