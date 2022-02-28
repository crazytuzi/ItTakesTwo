import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowfolkSnowballFightComponent;

class USnowFolkSnowballThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowFolkSnowballThrowCapability");
	default CapabilityTags.Add(n"SnowFolkSnowballFight");
	default CapabilityDebugCategory = n"SnowFolkSnowballCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 181;

	ASnowfolkSplineFollower Snowfolk;
	USnowfolkSnowballFightComponent SnowballComp;
	UHazeCrumbComponent CrumbComp;

	bool bThrownSnowball;
	float AnimationEndTime;
	float AnimationDuration;

	// Time of throw relative to played slot animation.
	float AnimationThrowTime = 0.75f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snowfolk = Cast<ASnowfolkSplineFollower>(Owner);
		SnowballComp = USnowfolkSnowballFightComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Snowfolk.MovementComp.bIsSkating)
			return EHazeNetworkActivation::DontActivate;

		if (!Snowfolk.bSnowballThrower)
			return EHazeNetworkActivation::DontActivate;

		if (Snowfolk.bIsRecovering)
			return EHazeNetworkActivation::DontActivate;

		if (Snowfolk.bIsHit)
			return EHazeNetworkActivation::DontActivate;

		if (Snowfolk.bIsDown)
			return EHazeNetworkActivation::DontActivate;

		if (SnowballComp.HasCooldown())
			return EHazeNetworkActivation::DontActivate;

		if (!SnowballComp.HasValidTargetInRange(3000.f))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Snowfolk.MovementComp.bIsSkating)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!Snowfolk.bSnowballThrower)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsRecovering)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsDown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!SnowballComp.HasValidTargetInRange(3500.f))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Time::GameTimeSeconds > AnimationEndTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"SnowFolkMovementCapability", this);
		Snowfolk.PatrolAudioComp.HandleInteruption(false);

		Snowfolk.PlaySlotAnimation(Animation = SnowballComp.ThrowAnimation);
		AnimationDuration = SnowballComp.ThrowAnimation.PlayLength;
		AnimationEndTime = Time::GameTimeSeconds + AnimationDuration;

		bThrownSnowball = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SnowFolkMovementCapability", this);
		Snowfolk.PatrolAudioComp.FinishInteruption();

		Snowfolk.StopAnimationByAsset(SnowballComp.ThrowAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We're crumbing the actual throw, since we need to network target data
		if (!HasControl() || bThrownSnowball)
			return;

		float Elapsed = Time::GetGameTimeSince(AnimationEndTime - AnimationDuration);

		if (Elapsed >= AnimationThrowTime)
		{
			FSnowballFightTargetData TargetData;
			TargetData.Component = SnowballComp.AimTargetComponent;
			TargetData.RelativeLocation = SnowballComp.AimTargetRelativeLocation;

			FHazeDelegateCrumbParams CrumbData;
			CrumbData.AddStruct(n"TargetData", TargetData);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ThrowSnowball"), CrumbData);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_ThrowSnowball(FHazeDelegateCrumbData CrumbData)
	{
		FSnowballFightTargetData TargetData;
		CrumbData.GetStruct(n"TargetData", TargetData);

		SnowballComp.LaunchSnowball(TargetData);
		bThrownSnowball = true;
	}
}