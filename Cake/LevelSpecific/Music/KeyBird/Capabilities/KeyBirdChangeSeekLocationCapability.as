import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdBehaviorComponent;

/*
Change Target Seek location if we are in random movement state. This is its own capability because we want to disable this particulat functionality when in SeekKey state.
If it takes too 
*/

class UKeyBirdChangeSeekLocationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"KeyBird");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 1;

	AKeyBird KeyBird;
	USteeringBehaviorComponent Steering;
	UKeyBirdBehaviorComponent BehaviorComp;
	UKeyBirdSettings Settings;

	float Elapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		BehaviorComp = UKeyBirdBehaviorComponent::Get(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(BehaviorComp.CurrentState != EKeyBirdState::RandomMovement)
			return EHazeNetworkActivation::DontActivate;

		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.IsDead())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChangeSeekLocation();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviorComp.CurrentState != EKeyBirdState::RandomMovement)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(KeyBird.IsDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//System::DrawDebugLine(Owner.ActorLocation, Steering.Seek.SeekLocation, FLinearColor::Red, 0, 10);
		//System::DrawDebugSphere(Steering.Seek.SeekLocation, 100, 12, FLinearColor::Red);
		// Close enough
		if(Steering.Seek.SeekLocation.DistSquared(Steering.WorldLocation) < FMath::Square(Settings.DistanceSlowdownScale.X * 0.9f))
		{
			ChangeSeekLocation();
		}
		else if(Elapsed < 0.0f)
		{
			ChangeSeekLocation();
		}
	}

	private void ChangeSeekLocation()
	{
		KeyBird.SetNewTargetLocation();
		ResetTimer();
	}

	private void ResetTimer()
	{
		Elapsed = 10.0f;
	}
}
