import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimecontrolMechanic.Audio.CharacterTimeControlAudioComponent;
import Vino.Movement.Components.MovementComponent;

class UCharacterTimeControlAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	UTimeControlComponent TimeComp;
	UTimeControlActorComponent TargetTimeComp;
	UCharacterTimeControlAudioComponent AudioTimeComp;

	private float ActivatedTimeManipulationValue;
	private float LastTimeManipulationValue;
	private bool bIsCurrentlyManipulating = false;
	private bool bHasTriggeredProgressionEnd = false;

	default CapabilityTags.Add(n"CharacterTimeControlAudio");

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerHazeAkComp = Player.PlayerHazeAkComp != nullptr ? Player.PlayerHazeAkComp : UPlayerHazeAkComponent::Get(Player);
		TimeComp = UTimeControlComponent::Get(Player);	
		AudioTimeComp = UCharacterTimeControlAudioComponent::Get(Player);
		AudioTimeComp.PlayerHazeAkComp = PlayerHazeAkComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UTimeControlActorComponent CurrentTargetTimeComp = TimeComp.GetLockedOnComponent();
		if(CurrentTargetTimeComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!CurrentTargetTimeComp.bIsCurrentlyBeingTimeControlled)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetTimeComp = TimeComp.GetLockedOnComponent();	

		TargetTimeComp.StartedProgressingTime.AddUFunction(AudioTimeComp, n"StartManipulationForwards");
		TargetTimeComp.StartedReversingTime.AddUFunction(AudioTimeComp, n"StartManipulationBackwards");
		TargetTimeComp.StartedHoldingTimeStill.AddUFunction(AudioTimeComp, n"StopManipulating");

		AudioTimeComp.BeginTimeControl();
		ActivatedTimeManipulationValue  = TimeComp.GetLockedOnComponent().GetCurrentProgressSpeedValue();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const float CurrentManipulationValue = TimeComp.GetLockedOnComponent().GetCurrentProgressSpeedValue();

		if(CurrentManipulationValue != 0 && CurrentManipulationValue != ActivatedTimeManipulationValue && !AudioTimeComp.bHasStartedManipulating)
			AudioTimeComp.bHasStartedManipulating = true;

		if(LastTimeManipulationValue != CurrentManipulationValue)
			PlayerHazeAkComp.SetRTPCValue("Rtpc_TimeControl_Manipulation_Value", CurrentManipulationValue);
		
		LastTimeManipulationValue = CurrentManipulationValue;

		const float CurrentManupulationProgress = TimeComp.GetLockedOnComponent().GetPointInTime();

		if(CurrentManupulationProgress > 0 && CurrentManupulationProgress < 1)
			bHasTriggeredProgressionEnd = false;

		if(CurrentManupulationProgress == 1.f && !bHasTriggeredProgressionEnd)
		{
			AudioTimeComp.TimeManipulationFullyProgressed();
			bHasTriggeredProgressionEnd = true;
		}
		else if(CurrentManupulationProgress == 0.f && !bHasTriggeredProgressionEnd)
		{
			AudioTimeComp.TimeManipulationFullyReversed();
			bHasTriggeredProgressionEnd = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		UTimeControlActorComponent CurrentTargetTimeComp = TimeComp.GetLockedOnComponent();
		if (CurrentTargetTimeComp != nullptr)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AudioTimeComp.EndTimeControl();
		AudioTimeComp.bHasStartedManipulating = false;

		bHasTriggeredProgressionEnd = false;
	}
}