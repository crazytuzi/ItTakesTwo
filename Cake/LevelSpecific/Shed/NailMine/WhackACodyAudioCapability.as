import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;
import Peanuts.Foghorn.FoghornStatics;

class UWhackACodyAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UWhackACodyComponent WhackAComp;

	UPROPERTY()
	UAkAudioEvent LidOpenedEvent;

	UPROPERTY() 
	UAkAudioEvent LidClosedEvent;

	UPROPERTY() 
	UAkAudioEvent HitEvent;

	UPROPERTY()
	UFoghornBarkDataAsset CodyHitEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackAComp = UWhackACodyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackAComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WhackAComp.WhackABoardRef != nullptr)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioLidOpened") == EActionStateStatus::Active)
			Player.PlayerHazeAkComp.HazePostEvent(LidOpenedEvent);

		if(ConsumeAction(n"AudioLidClosed") == EActionStateStatus::Active)
			Player.PlayerHazeAkComp.HazePostEvent(LidClosedEvent);

		if(ConsumeAction(n"AudioCodyWasHit") == EActionStateStatus::Active)
		{
			PlayFoghornEffort(CodyHitEvent, nullptr);
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_UI_Health_Decay_Start_Amount_Cody", 0.3f);
			Player.PlayerHazeAkComp.HazePostEvent(HitEvent);
		}
	}

}