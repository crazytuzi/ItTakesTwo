import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowfolkSnowballFightComponent;

class USnowfolkSnowballLaughingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowfolkSnowballLaughingCapability");
	default CapabilityTags.Add(n"SnowFolkSnowballFight");
	default CapabilityDebugCategory = n"SnowFolkSnowballCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 180;

	ASnowfolkSplineFollower Snowfolk;

	USnowfolkSnowballFightComponent SnowfolkSnowballFightComponent;
	float AnimationEndTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snowfolk = Cast<ASnowfolkSplineFollower>(Owner);
		SnowfolkSnowballFightComponent = USnowfolkSnowballFightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Snowfolk.MovementComp.bIsSkating)
			return EHazeNetworkActivation::DontActivate;

		if (!Snowfolk.bSnowballThrower)
			return EHazeNetworkActivation::DontActivate;

		if (!SnowfolkSnowballFightComponent.bRetaliationSuccess)
			return EHazeNetworkActivation::DontActivate;
	
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds > AnimationEndTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"SnowFolkMovementCapability", this);
		Owner.BlockCapabilities(n"SnowFolkSnowballThrowCapability", this);

		auto LaughAnimation = SnowfolkSnowballFightComponent.LaughingAnimation;
		
		Snowfolk.PatrolAudioComp.HandleInteruption(false);
		Snowfolk.PlaySlotAnimation(Animation = LaughAnimation);
		
		AnimationEndTime = Time::GameTimeSeconds + LaughAnimation.PlayLength;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SnowFolkMovementCapability", this);
		Owner.UnblockCapabilities(n"SnowFolkSnowballThrowCapability", this);

		Snowfolk.PatrolAudioComp.FinishInteruption();
		Snowfolk.StopAnimationByAsset(SnowfolkSnowballFightComponent.LaughingAnimation);
	
		SnowfolkSnowballFightComponent.bRetaliationSuccess = false;
	}
}