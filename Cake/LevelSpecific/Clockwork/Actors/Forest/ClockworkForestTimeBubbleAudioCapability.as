import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;
import Cake.LevelSpecific.Clockwork.Actors.Forest.ClockworkForestTimeBubble;


class UClockworkForestTimeBubbleAudioCapability : UHazeCapability
{
	AClockworkForestTimeBubble TimeBubble;
	UHazeAudioManager AudioManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TimeBubble = Cast<AClockworkForestTimeBubble>(Owner);
		AudioManager = GetAudioManager();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TimeBubble.BubbleMesh.bHiddenInGame)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TimeBubble.BubbleMesh.bHiddenInGame)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UObject RawBird;
		if(ConsumeAttribute(n"Bubble_AudioEnteredForcefield", RawBird))
		{
			AClockworkBird Bird = Cast<AClockworkBird>(RawBird);
			Bird.HazeAkComp.HazePostEvent(TimeBubble.BirdEnterBubbleEvent);
			Bird.HazeAkComp.SetRTPCValue("Rtpc_Clockwork_Outside_Player_Inside_TimeBubble", 1.f);
			Bird.ActivePlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_Clockwork_Outside_Player_Inside_TimeBubble", 1.f);
		}

		if(ConsumeAttribute(n"Bubble_AudioExitedForcefield", RawBird))
		{
			AClockworkBird Bird = Cast<AClockworkBird>(RawBird);
			Bird.ActivePlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_Clockwork_Outside_Player_Inside_TimeBubble", 0.f);
			Bird.HazeAkComp.SetRTPCValue("Rtpc_Clockwork_Outside_Player_Inside_TimeBubble", 0.f);
		}

		UObject RawBomb;
		if(ConsumeAttribute(n"AudioBubbleBombOverlap", RawBomb))
		{
			AFlyingBomb Bomb = Cast<AFlyingBomb>(RawBomb);
			Bomb.HazeAkComp.HazePostEvent(TimeBubble.BombEnterBubbleEvent);
		}
		
	}

}