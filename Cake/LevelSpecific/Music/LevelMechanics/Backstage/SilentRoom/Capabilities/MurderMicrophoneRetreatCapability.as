import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;
import Vino.PlayerHealth.PlayerHealthComponent;

class UMurderMicrophoneRetreatCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 10;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;
	UMurderMicrophoneSettings Settings;

	float CooldownElapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
		Settings = UMurderMicrophoneSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.CurrentState != EMurderMicrophoneHeadState::Retreat)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Snake.SetCurrentState(EMurderMicrophoneHeadState::Retreat);
		Snake.ApplySettings(Snake.RetreatSettings, this, EHazeSettingsPriority::Override);
		const FVector TargetLocation = Snake.HeadStartLocation + FVector(0.0f, 0.0f, 400.0f);
		MoveComp.SetTargetLocation(TargetLocation);
		MoveComp.ResetMovementVelocity();
		CooldownElapsed = Settings.ChangeStateCooldown;

		// Need extra cooldown if god mode because of 
		if(GetGodMode(Game::GetMay()) != EGodMode::Mortal)
			CooldownElapsed += 2.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Snake.UpdateEyeColorIntensityAlpha(Snake.SnakeHeadLocation);
		const FVector TargetFacingDirection = (Snake.SnakeHeadLocation - MoveComp.TargetLocation).GetSafeNormal();
		MoveComp.SetTargetFacingDirection(TargetFacingDirection);
		CooldownElapsed -= DeltaTime;
		if(Snake.HasTarget())
			Snake.SetOrAddEyeColor(Snake.AggressiveEyeColor, this, 2);
		else
			Snake.RemoveEyeColor(this);
		//PrintToScreen("" + TargetFacingDirection);
		//System::DrawDebugArrow(Snake.SnakeHeadLocation, Snake.SnakeHeadLocation + TargetFacingDirection * 3000.0f, 10.0f, FLinearColor::Green, 0, 20);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CooldownElapsed > 0.0f)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(Snake.ShouldEnterHypnosis())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(HasValidTarget() && !Snake.HasReachedTargetLocation())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.HasReachedTargetLocation())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.CurrentState != EMurderMicrophoneHeadState::Retreat)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl())
		{
			if(HasValidTarget() && !Snake.HasReachedTargetLocation())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Aggressive);
			else if(Snake.ShouldEnterHypnosis())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Hypnosis);
			else if(!Snake.IsKilled() && Snake.HasTarget())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Suspicious);
			else if(!Snake.IsKilled())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Sleeping);
		}

		Snake.ClearSettingsByInstigator(this);
		Snake.RemoveEyeColor(this);
	}

	private bool HasValidTarget() const
	{
		if(!Snake.HasTarget())
			return false;

		if(TargetingComp.IsTargetWithinChaseRange(Snake.TargetPlayer) && Snake.IsSnakeInsideChaseRadius())
			return true;

		return false;
	}
}
