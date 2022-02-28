import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

class UKeyBirdApproachKeyCapability : UHazeCapability
{
	AKeyBird KeyBird;
	USteeringBehaviorComponent SteeringComp;
	UMusicKeyComponent KeyComp;
	UKeyBirdBehaviorComponent BehaviorComp;

	AMusicalFollowerKey KeyTarget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		SteeringComp = USteeringBehaviorComponent::Get(Owner);
		KeyComp = UMusicKeyComponent::Get(Owner);
		BehaviorComp = UKeyBirdBehaviorComponent::Get(Owner);
	}

	float PickupTargetTime = 0.25f;

	bool bStopApproachingKey = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.IsDead())
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.CurrentState != EKeyBirdState::SeekKey)
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.HasKey())
			return EHazeNetworkActivation::DontActivate;

		if(SteeringComp.Seek.TargetActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		AMusicalFollowerKey KeyFollower = Cast<AMusicalFollowerKey>(SteeringComp.Seek.TargetActor);

		if(KeyFollower == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"KeyTarget", SteeringComp.Seek.TargetActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		KeyTarget = Cast<AMusicalFollowerKey>(ActivationParams.GetObject(n"KeyTarget"));
		bStopApproachingKey = false;
		KeyBird.ApplySettings(KeyBird.KeyBirdSeekKeySettings, this, EHazeSettingsPriority::Script);
		BehaviorComp.OnKeyBirdSeekKeyStart.Broadcast(Owner, KeyTarget);
		Elapsed = PickupTargetTime;
	}

	float Elapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		const float DistanceToSplinePointSq = KeyTarget.ActorLocation.DistSquared(Owner.ActorLocation);
		const bool bIsInRange = DistanceToSplinePointSq < FMath::Square(KeyComp.PickupRange);

		Elapsed -= DeltaTime;

		if(bIsInRange && Elapsed < 0.0f)
		{
			Elapsed = PickupTargetTime;
			KeyTarget.AddPendingFollowTarget(KeyBird);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(KeyBird.HasKey())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if(KeyBird.IsDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyTarget.HasFollowTarget())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.CurrentState != EKeyBirdState::SeekKey)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(SteeringComp.Seek.TargetActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if(KeyBird.IsDead())
			OutParams.AddActionState(n"Dead");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!DeactivationParams.GetActionState(n"Dead"))
			KeyBird.StartRandomMovement();

		KeyBird.ClearSettingsByInstigator(this);
		BehaviorComp.OnKeyBirdSeekKeyStop.Broadcast(Owner, SteeringComp.Seek.TargetActor, true);
	}
}
