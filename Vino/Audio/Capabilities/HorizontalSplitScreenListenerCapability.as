import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Capabilities.AudioTags;
import Peanuts.Audio.AudioStatics;
import Vino.Camera.Components.CameraUserComponent;

class UHorizontalSplitScreenListenerCapability : UHazeCapability
{
    default CapabilityDebugCategory = AudioTags::Audio;

    default CapabilityTags.Add(AudioTags::AudioListener);
    default CapabilityTags.Add(AudioTags::HorizontalSplitListener);

    AHazePlayerCharacter PlayerOwner;
    UPlayerHazeAkComponent HazeAkComp;
	UCameraUserComponent User;
	float PreviousScreenPositionX;

	bool bHasRTPCBeenSet = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        HazeAkComp = UPlayerHazeAkComponent::Get(PlayerOwner, n"PlayerHazeAkComponent");
		User = UCameraUserComponent::Get(PlayerOwner);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        // This will block all other listener capabilities except itself
        PlayerOwner.BlockCapabilities(n"AudioListener", this);
		bHasRTPCBeenSet = false;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        // This will unblock all other listener capabilities except itself
        PlayerOwner.UnblockCapabilities(n"AudioListener", this);
		HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, 0.f);
    }
    
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        HazeAudio::UpdateListenerTransform(PlayerOwner, 0);
		if (User.CanControlCamera()) 
		{
			if (bHasRTPCBeenSet) 
			{
				bHasRTPCBeenSet = false;
				HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, 0.f);
			}
			return;
		}

		FVector2D ScreenPosition;
		if (!HazeAudio::GetPlayerScreenPosition(PlayerOwner, nullptr, ScreenPosition))
		{
			return;
		}
		
		bHasRTPCBeenSet = true;
		if (PreviousScreenPositionX != ScreenPosition.X) 
		{
			HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, ScreenPosition.X);
			PreviousScreenPositionX = ScreenPosition.X;
		}
        
        if (IsDebugActive())
        {
            HazeAudio::DebugListenerLocations(PlayerOwner);
			Print("Player: " + PlayerOwner.Name + ", ScreenPosition.x: " + ScreenPosition.X);
        }
    }

   	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SceneView::GetSplitScreenMode() != EHazeSplitScreenMode::Horizontal)
    		return EHazeNetworkActivation::DontActivate;

       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SceneView::GetSplitScreenMode() != EHazeSplitScreenMode::Horizontal)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}


    UFUNCTION(BlueprintOverride)
    FString GetDebugString()
    {
        if(IsActive())
        {
            FString DebugText = "";
            if(HasControl())
            {
                DebugText += "Control Side\n";
            }
            else
            {
                DebugText += "Slave Side\n";
            }
            return DebugText;
        }

        return "Not Active";
    }
}