import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.MovementSystemTags;

class UPlayerMovementAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Audio");
	default CapabilityTags.Add(n"MovementAudio");
	default CapabilityDebugCategory = n"Audio";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;
	
	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UPlayerHazeAkComponent HazeAkComp;
	UPlayerMovementAudioComponent PlayerMovementAudioComp;	

	FHazeAudioEventInstance EffortEventInstance;

	bool bShouldSeek = false;
	bool bHasTriggeredSeek = false;

	float ActiveMovementDuration = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMovementAudioComp = UPlayerMovementAudioComponent::GetOrCreate(Owner, n"PlayerMovementAudioComponent");
		HazeAkComp = UPlayerHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

		
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)	
	{		
		if(PlayerMovementAudioComp.BodyMovementEvent != nullptr)
		{
			float VelocitySize = MoveComp.GetVelocity().Size();
			if(VelocitySize < KINDA_SMALL_NUMBER && !bShouldSeek)
			{
				bShouldSeek = true;
			}

			if(VelocitySize != 0.f && bHasTriggeredSeek && bShouldSeek)
			{
				bHasTriggeredSeek = false;
				bShouldSeek = true;
				
			}

			if(bShouldSeek && !bHasTriggeredSeek)
			{
				bHasTriggeredSeek = true;	
				bShouldSeek = false;	
				PlayerMovementAudioComp.bSeekOnBodyMovement = true;			
			}
		}	

		// Modify ActiveMovementDuration
		if (Player.IsAnyCapabilityActive(MovementSystemTags::AudioMovementEfforts) && !MoveComp.Velocity.IsNearlyZero() && !Player.IsAnyCapabilityActive(n"AudioTraversalTypeOverride"))
			ActiveMovementDuration += DeltaTime;
		else
			ActiveMovementDuration = 0.f;

		HazeAkComp.SetRTPCValue("Rtpc_VO_Efforts_MovementDuration", ActiveMovementDuration, 0.f);

		if (IsDebugActive())
			Print("FloorMovementDuration: " + ActiveMovementDuration, 0);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		if (PlayerMovementAudioComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(MoveComp.IsDisabled())	
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MoveComp.IsDisabled())	
			return EHazeNetworkDeactivation::DeactivateLocal;	

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerMovementAudioComp.UpdateBodyMovementEvent(PlayerMovementAudioComp.BodyMovementEvents.DefaultBodyMovementEvent);
		EffortEventInstance = PlayerMovementAudioComp.HazeAkComp.HazePostEvent(PlayerMovementAudioComp.EffortEvents.EffortBreathRunDefaultEvents);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		 		
		PlayerMovementAudioComp.StopMovementEvent(PlayerMovementAudioComp.BodyMovementEventInstance.PlayingID, EffortEventInstance.PlayingID);	
		PlayerMovementAudioComp.HazeAkComp.HazeStopEvent(EffortEventInstance.PlayingID);		
	}
}
