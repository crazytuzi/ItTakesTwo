
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Peanuts.Animation.Features.LocomotionFeatureGiddyUp;
import Vino.Movement.MovementSettings;

class UCharacterSpeedBoostCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	// How long time you will speedboost
	const float SpeedBoostTimeDuration = 1.25f;

	// How long it will take to reach normal speed
	const float SpeedBoostSlowdownTime = 0.3f;
	
	// The boost effect with a normal speedboost
	const float SpeedMultiplier = 1.75f;

	// A timed speedboost gives a super speedboost
	const float SUPERspeedMultiplier = 2.75f;

	// Internal Variables
	AHazePlayerCharacter PlayerCharacter = nullptr;
	float CurrentSpeedBoostTimeLeft = 0.f;
	float CurrentSpeedBoostSlowdownTimeLeft = 0.f;
	float CurrentMoveSpeed = 0.f;
	int ActivationLevel = 0;

	int DebugLevel = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		PlayerCharacter = Cast<AHazePlayerCharacter>(Owner);
	}


	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		ActivationLevel = 0;
		ConsumeAttribute(AttributeNames::ActivateSpeedBoost, ActivationLevel);
		if(ActivationLevel > 0)
		{
			int i = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (ActivationLevel > 0)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.DisableTransformSynchronization();
	}

	void EndSpeedBoost()
	{
		Owner.ClearSettingsByInstigator(Instigator = this);
		CurrentSpeedBoostTimeLeft = 0;
		Owner.SetCapabilityActionState(ActionNames::SpeedBoosting, EHazeActionState::Inactive);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (CurrentSpeedBoostTimeLeft <= 0.f && CurrentSpeedBoostSlowdownTimeLeft <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(PlayerCharacter.ActorVelocity.SizeSquared() < 1.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(CurrentSpeedBoostTimeLeft > 0)
		{
			EndSpeedBoost();
		}

		CurrentSpeedBoostTimeLeft = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(const FName Notification, FCapabilityNotificationReceiveParams NotificationParams)
	{
		if(Notification == n"SpeedBoost")
		{
			CurrentMoveSpeed = MoveComp.DefaultSpeed * SpeedMultiplier;
			TriggerSpeedBoost();
			DebugLevel = 1;
		}
		else if(Notification == n"SuperSpeedBoost")
		{
			CurrentMoveSpeed = MoveComp.DefaultSpeed * SUPERspeedMultiplier;
			TriggerSpeedBoost();
			DebugLevel = 2;
		}
	}

	void TriggerSpeedBoost()
	{
		UMovementSettings::SetMoveSpeed(Owner, CurrentMoveSpeed, Instigator = this);
		PlayerCharacter.SetCapabilityActionState(ActionNames::SpeedBoosting, EHazeActionState::Active);
		CurrentSpeedBoostTimeLeft = SpeedBoostTimeDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(ActivationLevel > 0)
		{
			if (ActivationLevel == 2)
			{	
				TriggerNotification(n"SuperSpeedBoost");
			}
			else if (ActivationLevel == 1)
			{
				TriggerNotification(n"SpeedBoost");
			}

			ActivationLevel = 0;
		}

		if(CurrentSpeedBoostTimeLeft > 0)
		{
			CurrentSpeedBoostTimeLeft -= DeltaTime;
			Owner.SetAnimFloatParam(AnimationFloats::LocomotionSpeedBoost, 1.f);
			if(CurrentSpeedBoostTimeLeft <= 0)
			{
				EndSpeedBoost();
				CurrentSpeedBoostSlowdownTimeLeft = SpeedBoostSlowdownTime;
			}
		}
		else if (CurrentSpeedBoostSlowdownTimeLeft > 0.f)
		{		
			CurrentSpeedBoostSlowdownTimeLeft = FMath::Max(CurrentSpeedBoostSlowdownTimeLeft - DeltaTime, 0.f);
			const float Speed = FMath::Lerp(MoveComp.DefaultSpeed, CurrentMoveSpeed, CurrentSpeedBoostSlowdownTimeLeft / SpeedBoostSlowdownTime);
			UMovementSettings::SetMoveSpeed(Owner, Speed, Instigator = this);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Speedboost Level: " + DebugLevel + "\n";
		Str += "Boost Time Left: " + CurrentSpeedBoostTimeLeft + "\n";
		Str += "Slowdown Time Left: " + CurrentSpeedBoostSlowdownTimeLeft + "\n";
		return Str;
	} 
}
