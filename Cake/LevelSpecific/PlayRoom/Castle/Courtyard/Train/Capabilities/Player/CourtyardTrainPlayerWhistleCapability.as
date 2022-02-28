import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainUserComponent;
import Vino.Camera.Components.CameraUserComponent;
import Rice.Camera.AcceleratedCameraDesiredRotation;

class UCourtyardTrainPlayerWhistleCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Camera);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	default CapabilityDebugCategory = CapabilityTags::Camera;

	AHazePlayerCharacter Player;
	UCourtyardTrainUserComponent TrainComp;
	ACourtyardTrain Train;

	const float Cooldown = 2.2f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrainComp = UCourtyardTrainUserComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TrainComp.InteractionComp == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (TrainComp.State != ECourtyardTrainState::Train)
        	return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < Cooldown)
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Train = TrainComp.Train;

		Train.WhistleNiagaraComp.Activate();
		Train.SetCapabilityActionState(n"AudioStartedWhistle", EHazeActionState::ActiveForOneFrame);

		Train.PlayTrainRiddenBark(Player);

		Player.SetAnimBoolParam(n"WhistleActive", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetAnimBoolParam(n"WhistleActive", false);
	}
}