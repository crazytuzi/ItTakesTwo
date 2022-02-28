import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdBehaviorComponent;

/*
Check if we should return to a normal state, such as if someone else picks up the Key
*/

class UKeyBirdSeekKeyCapability : UHazeCapability
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
	UMusicKeyComponent KeyComp;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
		BehaviorComp = UKeyBirdBehaviorComponent::Get(Owner);
		KeyComp = UMusicKeyComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkActivation::DontActivate;

		if(BehaviorComp.CurrentState != EKeyBirdState::SeekKey)
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.IsDead())
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		KeyBird.ApplySettings(KeyBird.KeyBirdSeekKeySettings, this, EHazeSettingsPriority::Script);
		Steering.bEnableLimitsBehavior = false;
		BehaviorComp.OnKeyBirdSeekKeyStart.Broadcast(Owner, Steering.Seek.TargetActor);
		KeyComp.bPickupKeys = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(BehaviorComp.CurrentState != EKeyBirdState::SeekKey)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if(Steering.Seek.TargetActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		AMusicalFollowerKey Key = Cast<AMusicalFollowerKey>(Steering.Seek.TargetActor);

		if(Key == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Key.HasFollowTarget())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(Key.IsUsed())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		UKeyBirdTeam Team = KeyBirdTeam;

		if(Team == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyComp.HasKey())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.IsDead())
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
		BehaviorComp.OnKeyBirdSeekKeyStop.Broadcast(Owner, Steering.Seek.TargetActor, true);
		KeyComp.bPickupKeys = false;
	}

#if !RELEASE
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
		{
			return;
		}

		if(CVar_KeyBirdDebugDraw.GetInt() == 1)
		{
			System::DrawDebugSphere(Owner.ActorLocation, 300.0f, 12, FLinearColor::Blue);
		}
	}
#endif // !RELEASE

	UKeyBirdTeam GetKeyBirdTeam() const property
	{
		return Cast<UKeyBirdTeam>(HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam"));
	}
}
