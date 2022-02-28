import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Vino.Camera.Components.CameraUserComponent;

/*
	Used to play the catch animation accordingly, the Cymbal will notify when it attaches itself again.
*/

class UCymbalPlayerCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	//default CapabilityTags.Add(n"Cymbal");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UCymbalComponent CymbalComp;
	ACymbal Cymbal;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CymbalComp = UCymbalComponent::GetOrCreate(Owner);
		Cymbal = CymbalComp.CymbalActor;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!CymbalComp.bCymbalWasCaught)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(CymbalComp.ShouldPlayCatchAnimation())
		{
			Player.AddLocomotionAsset(CymbalComp.CymbalStrafe, this);
			MoveComp.SetAnimationToBeRequested(n"CymbalCatch");
			Player.SetCapabilityActionState(n"AudioCymbalCatch", EHazeActionState::ActiveForOneFrame);
		}
		else if(CymbalComp.bCymbalAudioOnFlying)
			Player.SetCapabilityActionState(n"AudioCymbalCatch", EHazeActionState::ActiveForOneFrame);

		CymbalComp.AttachCymbalToBack();
		Cymbal.BP_OnCymbalCatch();

		Player.PlayForceFeedback(CymbalComp.CatchForceFeedback, false, true, n"CymbalCatch");
		CymbalComp.ThrowCooldownElapsed = CymbalComp.ThrowCooldown;

		// Since we're catching cymbal we want it to get hidden if player is overlapping camera
		UCameraUserComponent User = UCameraUserComponent::Get(Owner);
		if (User != nullptr)
			User.UpdateHideOnOverlap.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearLocomotionAssetByInstigator(this);
		CymbalComp.bCymbalWasCaught = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
