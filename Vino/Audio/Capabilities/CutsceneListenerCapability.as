import Peanuts.Audio.AudioStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraCutsceneBlendInCapability;
import Vino.Audio.Capabilities.AudioTags;
import Vino.Camera.Capabilities.CameraTags;

class UCutsceneListenerCapability : UHazeCapability
{
    default CapabilityDebugCategory = AudioTags::Audio;

	default CapabilityTags.Add(AudioTags::AudioListener);
	default CapabilityTags.Add(AudioTags::CutsceneListener);
	default TickGroup = ECapabilityTickGroups::PostWork;

	AHazePlayerCharacter PlayerOwner;
	UHazeListenerComponent Listener;
	AHazePlayerCharacter OtherPlayer;
	AHazeLevelSequenceActor LevelSequenceActor;
	UCameraUserComponent User;

	bool bStartedBlendOut = false;
	bool bBlockedReflection = false;

	float PreviousSizePercentage;
	float StartTimeForBlend = 2.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		Listener = UHazeListenerComponent::Get(PlayerOwner);
		OtherPlayer = PlayerOwner.GetOtherPlayer();
		User = UCameraUserComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlayerOwner.bIsParticipatingInCutscene)
    		return EHazeNetworkActivation::DontActivate;

       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PlayerOwner.bIsParticipatingInCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LevelSequenceActor = PlayerOwner.GetActiveLevelSequenceActor();
		PlayerOwner.BlockCapabilities(AudioTags::AudioListener, this);
		if (LevelSequenceActor != nullptr && LevelSequenceActor.bIsCutscene) 
		{
			bBlockedReflection = true;
			PlayerOwner.BlockCapabilities(AudioTags::PlayerReflectionTracing, this);
		}
			
		bStartedBlendOut = false;
		PreviousSizePercentage = -1;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(AudioTags::AudioListener, this);
		if (bBlockedReflection)
		{
			bBlockedReflection = false;
			PlayerOwner.UnblockCapabilities(AudioTags::PlayerReflectionTracing, this);
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
	{
		// If reloading during load the LevelSequenceActor reference can be lost.
		if (LevelSequenceActor == nullptr) 
		{
			LevelSequenceActor = PlayerOwner.GetActiveLevelSequenceActor();
			devEnsure(LevelSequenceActor != nullptr);
		}

		// 1. During cutscene update listener to camera, if needed (i.e is camera is used in cutscene).
		// 2. When cutscene is ending and camera is starting to blendout, shift to both listeners lerping to their usual position.
		UHazeCameraComponent Camera = PlayerOwner.GetCurrentlyUsedCamera();
		float SizePercentage = SceneView::GetPlayerViewSizePercentage(PlayerOwner);
		bool hasChanged = PreviousSizePercentage != SizePercentage;
		PreviousSizePercentage = SizePercentage;
		
		if (SizePercentage == 0.5f) 
		{
			float TimeLeft = LevelSequenceActor.GetTimeRemaining();
			if (TimeLeft < StartTimeForBlend) 
			{
				float Value = FMath::Clamp(TimeLeft/StartTimeForBlend, 0.f, 1.f);
				HazeAudio::UpdateListenerTransform(PlayerOwner, Value);
			}
			else 
			{
				if (Camera != nullptr)
					Listener.SetWorldTransform(Camera.GetWorldTransform());	
			}
		}
		else
		{
			if (SizePercentage <= 0.f)
			{
				auto OtherPlayerCamera = OtherPlayer.GetCurrentlyUsedCamera();
				if (OtherPlayerCamera != nullptr)
					Listener.SetWorldTransform(OtherPlayerCamera.GetWorldTransform());	
			}
			else if (SizePercentage >= 1.f)
			{
				if (Camera != nullptr)
					Listener.SetWorldTransform(Camera.GetWorldTransform());	
			}
			else if (hasChanged)
			{
				float NormalizedSize = FMath::Abs(SizePercentage-0.5f);
				HazeAudio::UpdateListenerTransform(PlayerOwner, NormalizedSize/0.5f);
			}
		}

		if (IsDebugActive())
		{
			HazeAudio::DebugListenerLocations(PlayerOwner);
		}	
	}

	UFUNCTION(BlueprintOverride)
    FString GetDebugString()
    {
        if(IsActive())
        {
            return "PreviousSizePercentage: " + PreviousSizePercentage;
        }

        return "Not Active";
    }
}