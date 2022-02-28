import Vino.Audio.Movement.PlayerMovementAudioComponent;

struct FOverrideFootstepEvents
{
	UPROPERTY()
	UAkAudioEvent RunSoft;
	
	UPROPERTY()
	UAkAudioEvent RunHard;

	UPROPERTY()
	UAkAudioEvent SprintSoft;

	UPROPERTY()
	UAkAudioEvent SprintHard;

	UPROPERTY()
	UAkAudioEvent CrouchSoft;

	UPROPERTY()
	UAkAudioEvent CrouchHard;

	UPROPERTY()
	UAkAudioEvent ScuffLowInt;

	UPROPERTY()
	UAkAudioEvent ScuffHighInt;

	UPROPERTY()
	UAkAudioEvent LandingLowInt;

	UPROPERTY()
	UAkAudioEvent LandingHighInt;

	UPROPERTY()
	UAkAudioEvent JumpEvent;
}

class UPlayerSkeletalMeshAudioOverrideCapability : UHazeCapability
{
	UPlayerMovementAudioComponent AudioMoveComp;

	UPROPERTY()
	bool bOverrideFootsteps = false;

	UPROPERTY(Meta = (EditCondition = "bOverrideFootsteps"))
	FOverrideFootstepEvents OverrideFootstepEvents;

	UPROPERTY()
	UAkAudioEvent OverrideBodyMovementEvent;	

	FRunEvents DefaultRunEvents;
	FSprintEvents DefaultSprintEvents;
	FCrouchEvents DefaultCrouchEvents;
	FScuffEvents DefaultScuffEvents;
	FLandingEvents DefaultLandingEvents;
	FJumpEvents DefaultJumpEvents;

	UAkAudioEvent DefaultBodyMovementEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);
	}

	void CacheDefaultEvents()
	{
		DefaultRunEvents = AudioMoveComp.RunEvents;
		DefaultSprintEvents = AudioMoveComp.SprintEvents;
		DefaultCrouchEvents = AudioMoveComp.CrouchEvents;
		DefaultScuffEvents = AudioMoveComp.ScuffEvents;
		DefaultLandingEvents = AudioMoveComp.LandingEvents;
		DefaultJumpEvents = AudioMoveComp.JumpEvents;
	}

	void ResetDefaultEvents()
	{
		AudioMoveComp.RunEvents.DefaultRunHardFootstepEvent = DefaultRunEvents.DefaultRunHardFootstepEvent;
		AudioMoveComp.RunEvents.DefaultRunSoftFootstepEvent = DefaultRunEvents.DefaultRunSoftFootstepEvent;
		AudioMoveComp.SprintEvents.DefaultSprintSoftFootstepEvent = DefaultSprintEvents.DefaultSprintSoftFootstepEvent;
		AudioMoveComp.SprintEvents.DefaultSprintHardFootstepEvent = DefaultSprintEvents.DefaultSprintHardFootstepEvent;
		AudioMoveComp.CrouchEvents.DefaultCrouchSoftFootstepEvent = DefaultCrouchEvents.DefaultCrouchSoftFootstepEvent;
		AudioMoveComp.CrouchEvents.DefaultCrouchHardFootstepEvent = DefaultCrouchEvents.DefaultCrouchHardFootstepEvent;
		AudioMoveComp.ScuffEvents.DefaultScuffLowIntensityHardEvent = DefaultScuffEvents.DefaultScuffLowIntensityHardEvent;
		AudioMoveComp.ScuffEvents.DefaultScuffLowIntensitySoftEvent = DefaultScuffEvents.DefaultScuffLowIntensitySoftEvent;
		AudioMoveComp.ScuffEvents.DefaultScuffHighIntensitySoftEvent = DefaultScuffEvents.DefaultScuffHighIntensitySoftEvent;
		AudioMoveComp.ScuffEvents.DefaultScuffHighIntensityHardEvent = DefaultScuffEvents.DefaultScuffHighIntensityHardEvent;
		AudioMoveComp.LandingEvents.LandingLowIntensity = DefaultLandingEvents.LandingLowIntensity;
		AudioMoveComp.LandingEvents.LandingHighIntensity = DefaultLandingEvents.LandingHighIntensity;
		AudioMoveComp.JumpEvents.JumpEvents = DefaultJumpEvents.JumpEvents;
	}

	void SetOverrideFootstepEvents()
	{
		AudioMoveComp.RunEvents.DefaultRunHardFootstepEvent = OverrideFootstepEvents.RunHard;
		AudioMoveComp.RunEvents.DefaultRunSoftFootstepEvent = OverrideFootstepEvents.RunSoft;
		AudioMoveComp.SprintEvents.DefaultSprintSoftFootstepEvent = OverrideFootstepEvents.SprintSoft;
		AudioMoveComp.SprintEvents.DefaultSprintHardFootstepEvent = OverrideFootstepEvents.SprintHard;
		AudioMoveComp.CrouchEvents.DefaultCrouchSoftFootstepEvent = OverrideFootstepEvents.CrouchSoft;
		AudioMoveComp.CrouchEvents.DefaultCrouchHardFootstepEvent = OverrideFootstepEvents.CrouchHard;
		AudioMoveComp.ScuffEvents.DefaultScuffLowIntensityHardEvent = OverrideFootstepEvents.ScuffLowInt;
		AudioMoveComp.ScuffEvents.DefaultScuffLowIntensitySoftEvent = OverrideFootstepEvents.ScuffLowInt;
		AudioMoveComp.ScuffEvents.DefaultScuffHighIntensitySoftEvent = OverrideFootstepEvents.ScuffHighInt;
		AudioMoveComp.ScuffEvents.DefaultScuffHighIntensityHardEvent = OverrideFootstepEvents.ScuffHighInt;
		AudioMoveComp.LandingEvents.LandingLowIntensity = OverrideFootstepEvents.LandingLowInt;
		AudioMoveComp.LandingEvents.LandingHighIntensity = OverrideFootstepEvents.LandingHighInt;
		AudioMoveComp.JumpEvents.JumpEvents = OverrideFootstepEvents.JumpEvent;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CacheDefaultEvents();

		if(bOverrideFootsteps)
			SetOverrideFootstepEvents();

		if(OverrideBodyMovementEvent != nullptr)
		{
			DefaultBodyMovementEvent = AudioMoveComp.BodyMovementEvents.DefaultBodyMovementEvent;
			AudioMoveComp.UpdateBodyMovementEvent(OverrideBodyMovementEvent);
		}		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ResetDefaultEvents();

		if(OverrideBodyMovementEvent != nullptr)
			AudioMoveComp.UpdateBodyMovementEvent(DefaultBodyMovementEvent);
	}

}

