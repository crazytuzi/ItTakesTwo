import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdTags;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBombCrosshair;
import Peanuts.Aiming.AutoAimStatics;

class UClockworkPlayerBirdAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"WeaponAim");
	default CapabilityTags.Add(n"ClockworkBirdAim");

	default CapabilityDebugCategory = n"ClockworkInputCapability";
	
	default TickGroup = ECapabilityTickGroups::PostWork;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AClockworkBird Bird;
	UFlyingBombCrosshair Crosshair;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
        if (MountedBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
        if (!WasActionStarted(ActionNames::WeaponAim))
			return EHazeNetworkActivation::DontActivate;
		if (!MountedBird.bIsFlying)
			return EHazeNetworkActivation::DontActivate;
		if (!MountedBird.bIsHoldingBomb)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (MountedBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if(!MountedBird.PlayerIsUsingBird(Player))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!MountedBird.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!MountedBird.bIsHoldingBomb)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));

		if (Bird.CameraSettings_Aiming != nullptr)
		{
			Player.ApplyCameraSettings(
				Bird.CameraSettings_Aiming, 
				Bird.CameraSettingsBlend_Aiming, 
				Instigator = this, Priority = EHazeCameraPriority::Script);
		}

		Bird.SetCapabilityActionState(ClockworkBirdTags::Aiming, EHazeActionState::Active);

		if (Bird.BombAimCrosshair.IsValid())
			Crosshair = Cast<UFlyingBombCrosshair>(Player.AddWidget(Bird.BombAimCrosshair, EHazeWidgetLayer::Crosshair));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
		Bird.SetCapabilityActionState(ClockworkBirdTags::Aiming, EHazeActionState::Inactive);

		if (Crosshair != nullptr)
		{
			Player.RemoveWidget(Crosshair);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector AimStart = Player.ViewLocation;
		FVector AimDirection = Player.ViewRotation.ForwardVector;
		
		FAutoAimLine AutoAim = GetAutoAimForTargetLine(
			Player,
			AimStart,
			AimDirection,
			1000.f,
			100000.f,
			false
		);

		if (AutoAim.AutoAimedAtComponent != nullptr)
		{
			Bird.AutoAimPoint = AutoAim.AutoAimedAtComponent.WorldLocation;

			if (Crosshair != nullptr)
			{
				Crosshair.bHasAutoAim = true;
				Crosshair.AutoAimLocation = Bird.AutoAimPoint;
			}
		}
		else
		{
			Bird.AutoAimPoint = FVector::ZeroVector;

			if (Crosshair != nullptr)
			{
				Crosshair.bHasAutoAim = false;
			}
		}
	}
}