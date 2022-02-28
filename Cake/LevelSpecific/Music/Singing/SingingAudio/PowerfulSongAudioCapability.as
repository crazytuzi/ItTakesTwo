import Cake.LevelSpecific.Music.Singing.SingingAudio.SingingAudioComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongProjectile;


enum EPowerfulSongAudioPlaybackType
{
	Sequence,
	RandomStandard,
	RandomShuffle
}

class UPowerfulSongAudioCapability : UHazeCapability
{
	// NOTE (GK): Removed due to it's not used and not networked.
	// UPROPERTY()
	// UAkAudioEvent PowerfulSongStartAimEvent;

	UPROPERTY()
	UAkAudioEvent PowerfulSongBlastEvent;

	UPROPERTY()
	UAkAudioEvent PowerfulSongScreamEvent;

	UPROPERTY(EditDefaultsOnly)
	TArray<UAkAudioEvent> PowerfulSongVariations;

	UPROPERTY(EditDefaultsOnly)
	TArray<UAkAudioEvent> PowerfulSongImpactVariations;

	UPROPERTY()
	EPowerfulSongAudioPlaybackType PlaybackType;

	UPROPERTY(Meta = (EditCondition = "PlaybackType == EPowerfulSongAudioPlaybackType::RandomStandard"))
	int32 AvoidLast = 0;

	AHazePlayerCharacter Player;
	USingingAudioComponent SingAudioComp;

	private int32 SelectionIndex = 0.f;
	private TArray<int32> AvoidIndexes;
	private TArray<int32> PlayedIndexes;

	private UAkAudioEvent PowerfulSongEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SingAudioComp = USingingAudioComponent::Get(Owner);

		if(AvoidLast >= PowerfulSongVariations.Num())
			AvoidLast = PowerfulSongVariations.Num() - 1;		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		//Always activate immediately if we are flying
		if(SingAudioComp != nullptr && SingAudioComp.bActivateOnFlying)
			return EHazeNetworkActivation::ActivateLocal;

		if (IsActioning(ActionNames::LedgeGrabbing))
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::WallSliding))
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::Dashing))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// NOTE (GK): The following isn't networked, if this is needed we need to make a networked check
		// if(IsActioning(ActionNames::WeaponAim))
		// Player.PlayerHazeAkComp.HazePostEvent(PowerfulSongStartAimEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UObject RawObject;		
		if(ConsumeAttribute(n"AudioActivatedPowerfulSong", RawObject))
		{
			APowerfulSongProjectile SongProjectile = Cast<APowerfulSongProjectile>(RawObject);
			if(SongProjectile != nullptr)
				PerformPowerfulSongEvent(SongProjectile);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::LedgeGrabbing))
		return EHazeNetworkDeactivation::DeactivateLocal;

		if (IsActioning(ActionNames::WallSliding))
		return EHazeNetworkDeactivation::DeactivateLocal;

		if (IsActioning(ActionNames::Dashing))
		return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool PerformPowerfulSongEvent(APowerfulSongProjectile SongProjectile)
	{
		if(PowerfulSongVariations.Num() == 0)
			return false;

		int32 SelectedIndex = 0;
		GetNextPowerfulSongEvent(PowerfulSongEvent, SelectedIndex);
	
		UHazeAkComponent ProjectileHazeAkComp = UHazeAkComponent::GetOrCreate(SongProjectile);
		Player.PlayerHazeAkComp.HazePostEvent(PowerfulSongBlastEvent);
		ProjectileHazeAkComp.HazePostEvent(PowerfulSongEvent);
		ProjectileHazeAkComp.HazePostEvent(PowerfulSongScreamEvent);
		SongProjectile.AttachedPowerfulSongEvent = PowerfulSongEvent;

		if(PowerfulSongImpactVariations.Num() >= SelectedIndex)
			SongProjectile.AttachedPowerfulSongEchoEvent = PowerfulSongImpactVariations[SelectedIndex];

		return PowerfulSongEvent != nullptr;
	}

	void GetNextPowerfulSongEvent(UAkAudioEvent& OutEvent, int32& OutSelectedIndex)
	{
		switch(PlaybackType)
		{
			case(EPowerfulSongAudioPlaybackType::Sequence):
				GetSequentialEvent(OutEvent, OutSelectedIndex);
				break;
			
			case(EPowerfulSongAudioPlaybackType::RandomStandard):
				GetRandomEvent(OutEvent, OutSelectedIndex);
		}
	}	

	void GetSequentialEvent(UAkAudioEvent& OutEvent, int32& OutSelectedIndex)
	{
		if(PlaybackType != EPowerfulSongAudioPlaybackType::Sequence)
			return;

		if(SelectionIndex == PowerfulSongVariations.Num())
			SelectionIndex = 0;
		
		OutEvent = PowerfulSongVariations[SelectionIndex];
		OutSelectedIndex = SelectionIndex;
		SelectionIndex ++;
	}

	void GetRandomEvent(UAkAudioEvent& OutEvent, int32& OutSelectedIndex)
	{
		if(PlaybackType == EPowerfulSongAudioPlaybackType::Sequence)
			return;

		int32 RandomIndex = FMath::RandRange(0, PowerfulSongVariations.Num() - 1);
		bool bFoundValidIndex = PlaybackType == EPowerfulSongAudioPlaybackType::RandomStandard ? !AvoidIndexes.Contains(RandomIndex) : !PlayedIndexes.Contains(RandomIndex);

		while(!bFoundValidIndex)
		{
			RandomIndex = FMath::RandRange(0, PowerfulSongVariations.Num() - 1);
			bFoundValidIndex = PlaybackType == EPowerfulSongAudioPlaybackType::RandomStandard ? !AvoidIndexes.Contains(RandomIndex) : !PlayedIndexes.Contains(RandomIndex);
		}

		UpdateValidRandomIndexes(RandomIndex);
		OutEvent = PowerfulSongVariations[RandomIndex];
		OutSelectedIndex = RandomIndex;
	}	

	void UpdateValidRandomIndexes(int32 CurrSelectedIndex)
	{
		switch(PlaybackType)
		{
			case(EPowerfulSongAudioPlaybackType::Sequence):
				return;

			case(EPowerfulSongAudioPlaybackType::RandomStandard):
				if(AvoidLast == 0)
					return;

				if(AvoidIndexes.Num() == AvoidLast)
				{
					AvoidIndexes.Insert(CurrSelectedIndex, 0);
					AvoidIndexes.RemoveAtSwap(AvoidIndexes.Num() - 1);
				}
				else
					AvoidIndexes.Add(CurrSelectedIndex);
				break;
			
			case(EPowerfulSongAudioPlaybackType::RandomShuffle):
				if(PlayedIndexes.Num() + 1 < PowerfulSongVariations.Num())
					PlayedIndexes.Add(CurrSelectedIndex);
				else
					PlayedIndexes.Empty();
		}
	}

	UFUNCTION()
	bool GetCurrentPowerfulSongEvent(UAkAudioEvent& OutEvent)
	{
		OutEvent = PowerfulSongEvent;
		return OutEvent != nullptr;
	}
}

