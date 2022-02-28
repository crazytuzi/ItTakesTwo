import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.Classic.MusicKeyComponent;
import Cake.LevelSpecific.Music.Classic.Capabilities.PlayerKeyBirdReactionComponent;

class UKeyBirdApproachPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"KeyBirdStealKey");
	default CapabilityTags.Add(n"KeyBird");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 2;
	
	AKeyBird KeyBird;
	USteeringBehaviorComponent Steering;
	AHazePlayerCharacter TargetPlayer;
	UKeyBirdBehaviorComponent BehaviorComp;
	UMusicKeyComponent KeyComp;
	UKeyBirdSettings Settings;

	bool bCloseEnough = false;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		KeyComp = UMusicKeyComponent::Get(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		BehaviorComp = UKeyBirdBehaviorComponent::Get(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(BehaviorComp.CurrentState != EKeyBirdState::StealKey)
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.TargetPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.IsDead())
			return EHazeNetworkActivation::DontActivate;

		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.bStartAttack)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"TargetPlayer", KeyBird.TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"TargetPlayer"));
		devEnsure(TargetPlayer != nullptr);
		bCloseEnough = false;
		BehaviorComp.OnKeyBirdStealKeyStart.Broadcast(KeyBird, TargetPlayer);
		Steering.bEnableLimitsBehavior = false;
		KeyBird.ApplySettings(KeyBird.KeyBirdStealKeySettings, this, EHazeSettingsPriority::Script);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BehaviorComp.CurrentState != EKeyBirdState::StealKey)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.TargetPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bCloseEnough)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.IsDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!KeyBird.IsKeyBirdEnabled())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!KeyBirdCommon::IsPlayerValidTarget(KeyBird.TargetPlayer, KeyBird.CombatArea))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if(bCloseEnough && !KeyBird.IsDead())
		{
			UMusicKeyComponent PlayerKeyComp = UMusicKeyComponent::Get(TargetPlayer);
			AMusicalFollowerKey KeyTarget = PlayerKeyComp.FirstKey;

			if(KeyTarget != nullptr)
			{
				DeactivationParams.AddObject(n"TargetKey", KeyTarget);
				DeactivationParams.AddActionState(n"CloseEnough");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(DeactivationParams.GetActionState(n"CloseEnough"))
		{
			KeyBird.bStartAttack = true;
		}
		else
		{
			KeyBird.CombatArea.Handle_KeyBirdStealKeyStop(KeyBird, TargetPlayer, false);
			BehaviorComp.OnKeyBirdStealKeyStop.Broadcast(KeyBird, TargetPlayer, false);
			KeyBird.StartRandomMovement();
		}

		KeyBird.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

#if !RELEASE
		if(CVar_KeyBirdDebugDraw.GetInt() == 1)
		{
			System::DrawDebugSphere(Owner.ActorLocation, 400.0f, 12, FLinearColor::Red);
		}
#endif // !RELEASE

		if(TargetPlayer.GetSquaredDistanceTo(KeyBird) < FMath::Square(Settings.StealKeyRadius))
		{
			bCloseEnough = true;
		}
	}
}
