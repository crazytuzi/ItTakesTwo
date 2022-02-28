import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Audio.CastleDungeonPlayerAudioCapabilityBase;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteSword;

class UCastleBrutePlayerAudioCapability : UCastleDungeonPlayerAudioCapabilityBase
{
	ACastleBruteSword Sword;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	UAkAudioEvent SwordStartBurningEvent;

	UPROPERTY()
	UAkAudioEvent SwordStopBurningEvent;

	private FHazeAudioEventInstance BurningSwordEventInstance;
	private float LastNormalizedRotationDelta = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);

		TArray<AActor> AttachActors;
		Owner.GetAttachedActors(AttachActors);

		for(auto Actor : AttachActors)
		{
			Sword = Cast<ACastleBruteSword>(Actor);
			if(Sword != nullptr)
				break;
		}

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.PlayerHazeAkComp.HazePostEvent(SwordStopBurningEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioShowSword") == EActionStateStatus::Active && !Player.PlayerHazeAkComp.EventInstanceIsPlaying(BurningSwordEventInstance))
			BurningSwordEventInstance = Player.PlayerHazeAkComp.HazePostEvent(SwordStartBurningEvent);

		if(ConsumeAction(n"AudioHideSword") == EActionStateStatus::Active)	
			Player.PlayerHazeAkComp.HazePostEvent(SwordStopBurningEvent);

		if(Sword != nullptr)
		{
			float RotationDelta = MoveComp.RotationDelta / DeltaTime;
			const float NormalizedRotationDelta = HazeAudio::NormalizeRTPC01(RotationDelta, 0.f, 24.f);

			if(NormalizedRotationDelta != LastNormalizedRotationDelta)
			{
				Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Abilites_Spells_FireSword_Rotation_Delta", NormalizedRotationDelta);
				LastNormalizedRotationDelta = NormalizedRotationDelta;
			}
		}
	}
	
}