import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraPlayerComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;
class USelfieCameraPlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfieCameraPlayerCancelCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USelfieCameraPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USelfieCameraPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && PlayerComp.bCanCancel)
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		
		ASelfieCameraActor CamActor = Cast<ASelfieCameraActor>(PlayerComp.SelfieCameraActor);
		PlayerComp.HidePlayerTakePic(Player);
		PlayerComp.HidePlayerCancel(Player);
		
		if (CamActor == nullptr)
			return;

		if (HasControl())
			CamActor.NetPlayerCancelled(Player);
	}
}