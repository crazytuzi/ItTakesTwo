import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.ActivationPoint.ActivationPointStatics;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;

class UPlayerMagnetControllerCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticControl);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	default TickGroup = ECapabilityTickGroups::Input;

	const float DelaySendTime = 0.1f;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent MagneticPlayerComponent;
	UCharacterSprintComponent SprintComponent;

	UMagneticComponent ActiveMagnet;
	const float ActivationCooldown = 0.25f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::Get(PlayerOwner);
		SprintComponent = UCharacterSprintComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DeactiveDuration < ActivationCooldown)
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, ActivationCooldown))
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerComponent.TargetedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddObject(n"TargetedMagnet", MagneticPlayerComponent.GetTargetedMagnet());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Return and deactivate if targeted activation point was not a magnet
		ActiveMagnet = Cast<UMagneticComponent>(ActivationParams.GetObject(n"TargetedMagnet"));
		if(ActiveMagnet != nullptr)
		{
			// Start controlling magnet
			ActiveMagnet.ApplyControlInfluenser(MagneticPlayerComponent, n"MagneticController", GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis), MagneticPlayerComponent.GetTargetDistanceAlpha());

			// Deactivate sprinting
			SprintComponent.bSprintToggled = false;
		}

		// Block sliding
		PlayerOwner.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsBlocked() && MagneticPlayerComponent.ActivatedMagnet == nullptr)
		{
			MagneticPlayerComponent.QueryMagnets();
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveMagnet == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(SprintComponent.bSprintActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Deactivate magnet if valid
		if(ActiveMagnet != nullptr)
		{
			ActiveMagnet.RemoveInfluenser(PlayerOwner, n"MagneticController");
			ActiveMagnet = nullptr;

			// Consume magnet action to guarantee all magnet-related capabilities will deactivate
			PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		}

		// Unblock sliding
		PlayerOwner.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		if(ActiveMagnet != nullptr)
		{
			Str += "Inluensing: " + ActiveMagnet.GetOwner().GetName() + "\n";
			Str += "(" + ActiveMagnet.GetName() + ")";
		}	
		return Str;
	}
}