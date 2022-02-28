import Peanuts.Audio.AudioStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Capabilities.AudioTags;

class UFullScreenListenerCapability : UHazeCapability
{
    default CapabilityDebugCategory = AudioTags::Audio;

    default CapabilityTags.Add(AudioTags::AudioListener);
    default CapabilityTags.Add(AudioTags::FullScreenListener);

    AHazePlayerCharacter PlayerOwner;
    UPlayerHazeAkComponent HazeAkComp;
	float PreviousScreenPositionX;
	float LastCameraDistanceRtpcValue = 0.f;

	AActor ActorPositionalOverride = nullptr;
	USceneComponent ComponenPositionalOverride = nullptr;

	void ResetPositionalOverrides()
	{
		ActorPositionalOverride = nullptr;
		ComponenPositionalOverride = nullptr;
	}

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams SetupParams)
    {
        PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
        HazeAkComp = UPlayerHazeAkComponent::Get(PlayerOwner);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        // This will block all other listener capabilities except itself
        PlayerOwner.BlockCapabilities(AudioTags::AudioListener, this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        // This will unblock all other listener capabilities except itself
		PlayerOwner.UnblockCapabilities(AudioTags::AudioListener, this);

		ResetPositionalOverrides();
		HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, 0.f);
    }

	bool HasOverridePosition(FVector& Position)
	{
		if (ActorPositionalOverride != nullptr)
			Position = ActorPositionalOverride.GetActorLocation();

		if (ComponenPositionalOverride != nullptr)
			Position = ComponenPositionalOverride.GetWorldLocation();

		return ActorPositionalOverride != nullptr || ComponenPositionalOverride != nullptr;
	}

	UObject GetObjectOverride()
	{
		if (ActorPositionalOverride != nullptr)
			return ActorPositionalOverride;

		if (ComponenPositionalOverride != nullptr)
			return ComponenPositionalOverride;

		return nullptr;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		UObject ObjectOverrideOut = nullptr;
		if (ConsumeAttribute(n"FullscreenListenerActorOverride", ObjectOverrideOut))
		{
			if (ObjectOverrideOut != nullptr)
			{
				ActorPositionalOverride = Cast<AActor>(ObjectOverrideOut);
				ComponenPositionalOverride = Cast<USceneComponent>(ObjectOverrideOut);
			}
		}

		FVector TargetPosition;
		if (HasOverridePosition(TargetPosition))
			HazeAudio::UpdateListenerTransform(PlayerOwner, TargetPosition,  1);
		else
			HazeAudio::UpdateListenerTransform(PlayerOwner, 0);

		FVector2D ScreenPosition;
		if (!HazeAudio::GetPlayerScreenPosition(PlayerOwner, ActorPositionalOverride,  ScreenPosition))
		{
			return;
		}
			
		if (PreviousScreenPositionX != ScreenPosition.X) 
		{
			const float NormalizedPanningValue = HazeAudio::NormalizeRTPC(ScreenPosition.X, 0.f, 1.f, -1.f, 1.f);
			HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, NormalizedPanningValue);
			PreviousScreenPositionX = ScreenPosition.X;
		}

        if (IsDebugActive() || HazeAkComp.bDebugAudio)
        {
            HazeAudio::DebugListenerLocations(PlayerOwner, GetObjectOverride(), TargetPosition);
			PrintToScreen("Player: " + PlayerOwner.Name + ", ScreenPosition.x: " + ScreenPosition.X);
        }

		const float CameraDistanceRTPCValue = HazeAudio::GetPlayerCameraDistanceRTPCValue(PlayerOwner);
		if(CameraDistanceRTPCValue != LastCameraDistanceRtpcValue)
		{
			PlayerOwner.PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterCameraDistance, CameraDistanceRTPCValue);
			LastCameraDistanceRtpcValue = CameraDistanceRTPCValue;
		}
    }

   	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerOwner.bIsParticipatingInCutscene || !SceneView::IsFullScreen())
    		return EHazeNetworkActivation::DontActivate;

       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerOwner.bIsParticipatingInCutscene  || !SceneView::IsFullScreen())
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