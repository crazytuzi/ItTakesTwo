import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraPlayerComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;

class USelfieCameraPlayerTakePictureCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfieCameraPlayerTakePictureCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USelfieCameraPlayerComponent PlayerComp;

	TArray<ASelfieCameraActor> SelfieCamArray;
	ASelfieCameraActor SelfieCam;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		
		PlayerComp = USelfieCameraPlayerComponent::Get(Player);

		GetAllActorsOfClass(SelfieCamArray);
		SelfieCam = SelfieCamArray[0];

		// System::SetTimer(this, n"NetDelayedEnableActions", 0.8f, false);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::MovementJump) && SelfieCam.bCanTakePicture)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

       	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.HidePlayerTakePic(Player);
		SelfieCam.InstantCameraTakePicture(Player);

		if (PlayerComp.WidgetRef != nullptr)
			PlayerComp.WidgetRef.BP_LenseFlash();
	}

	// UFUNCTION(NetFunction)
	// void NetDelayedEnableActions()
	// {
	// 	SelfieCam.bCanTakePicture = true;
	// 	PlayerComp.ShowPlayerTakePic(Player);
	// 	PlayerComp.bCanCancel = true;
	// 	PlayerComp.ShowPlayerCancel(Player);
	// }
}