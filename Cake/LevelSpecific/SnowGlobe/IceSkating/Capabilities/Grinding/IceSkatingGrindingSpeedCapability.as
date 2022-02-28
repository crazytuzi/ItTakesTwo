import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Rice.Math.MathStatics;

class UIceSkatingGrindingSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Speed);

	default CapabilityDebugCategory = n"IceSkating";	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 179;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;

	FHazeAcceleratedFloat AcceleratedSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
        	return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(GrindingCapabilityTags::Speed, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(GrindingCapabilityTags::Speed, false);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// If the custom speed of the grind spline is higher than
		FGrindBasicSpeedSettings CustomSpeedSettings = UserGrindComp.ActiveGrindSpline.CustomSpeed;
		float TargetSpeed = FMath::Max(CustomSpeedSettings.DesiredMiddle, UserGrindComp.DesiredSpeed);

		UMovementSettings::SetHorizontalAirSpeed(Player, UserGrindComp.CurrentSpeed, Instigator = this);
		UserGrindComp.CurrentSpeed = FMath::FInterpTo(
			UserGrindComp.CurrentSpeed, TargetSpeed,
			DeltaTime, 5.f
		);
	}
}
