import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowfolkSnowballFightComponent;

class USnowFolkSnowballAggroCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowFolkSnowballAggroCapability");
	default CapabilityTags.Add(n"SnowFolkSnowballFight");
	default CapabilityDebugCategory = n"SnowFolkSnowballCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 180;

	ASnowfolkSplineFollower Snowfolk;

	USnowfolkSnowballFightComponent SnowfolkSnowballFightComponent;
	USnowballFightResponseComponent SnowballFightResponseComponent;

	// This is a loopy boi, not the same length as the animation.
	float AnimationDuration = 2.f;
	float AnimationEndTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snowfolk = Cast<ASnowfolkSplineFollower>(Owner);
		SnowfolkSnowballFightComponent = USnowfolkSnowballFightComponent::Get(Owner);
		SnowballFightResponseComponent = USnowballFightResponseComponent::Get(Owner);

		SnowballFightResponseComponent.OnSnowballHit.AddUFunction(this, n"HandleSnowballHit");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Snowfolk.MovementComp.bIsSkating)
			return EHazeNetworkActivation::DontActivate;

		if (!Snowfolk.bSnowballThrower)
			return EHazeNetworkActivation::DontActivate;

		if (SnowfolkSnowballFightComponent.AggroTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;
	
		if (Snowfolk.bIsRecovering)
			return EHazeNetworkActivation::DontActivate;

		if (!Snowfolk.bIsHit)
			return EHazeNetworkActivation::DontActivate;

		if (Snowfolk.bIsDown)
			return EHazeNetworkActivation::DontActivate;
	
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Snowfolk.MovementComp.bIsSkating)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (SnowfolkSnowballFightComponent.AggroTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsRecovering)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Snowfolk.bIsDown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Time::GameTimeSeconds > AnimationEndTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"SnowFolkMovementCapability", this);
		Owner.BlockCapabilities(n"SnowFolkSnowballThrowCapability", this);

		Snowfolk.PlaySlotAnimation(Animation = SnowfolkSnowballFightComponent.AggroAnimation, bLoop = true);
		Snowfolk.PatrolAudioComp.HandleInteruption();

		AnimationEndTime = Time::GameTimeSeconds + AnimationDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SnowFolkMovementCapability", this);
		Owner.UnblockCapabilities(n"SnowFolkSnowballThrowCapability", this);

		Snowfolk.PatrolAudioComp.FinishInteruption();
		
		Snowfolk.StopAnimationByAsset(SnowfolkSnowballFightComponent.AggroAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SnowfolkSnowballFightComponent.AggroTarget == nullptr)
			return;

		FVector Direction = (SnowfolkSnowballFightComponent.AggroTarget.ActorLocation - Owner.ActorLocation).GetSafeNormal();

		Direction.ConstrainToPlane(Owner.ActorUpVector);
		FRotator Rotation = FRotator::MakeFromZX(Owner.ActorUpVector, Direction);

		Owner.SetActorRotation(Rotation);
	}

	UFUNCTION()
	void HandleSnowballHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(ProjectileOwner);

		if (Player == nullptr)
			return;

		SnowfolkSnowballFightComponent.AggroTarget = Player;
	}
}